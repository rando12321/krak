"""Async MySQL persistence. No connections or tasks at import time."""
import asyncio
import hashlib
import os
import re
import secrets
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
import asyncmy
from asyncmy.cursors import DictCursor


def digest(value):
    return hashlib.sha256(value.encode('utf-8')).hexdigest()


def utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)


def check_server_version(version):
    """Accept MySQL 8+ and XAMPP MariaDB 10.4+, including compatibility prefixes."""
    if 'mariadb' in version.lower():
        match = re.search(r'(\d+)\.(\d+)(?:\.\d+)?(?=-MariaDB)', version, re.I)
        if match and tuple(map(int, match.groups())) >= (10, 4):
            return
    else:
        match = re.match(r'(\d+)\.(\d+)', version)
        if match and tuple(map(int, match.groups())) >= (8, 0):
            return
    raise RuntimeError('MySQL 8.0+ or MariaDB 10.4+ (XAMPP) is required')


class AuthError(Exception):
    pass


class Database:
    def __init__(self):
        self.pool = None

    async def open(self):
        # Retry connection acquisition only. Never replay committed writes.
        for attempt in range(3):
            try:
                self.pool = await asyncmy.create_pool(
                    host=os.getenv('MYSQL_HOST', '127.0.0.1'),
                    port=int(os.getenv('MYSQL_PORT', '3306')),
                    user=os.getenv('MYSQL_USER', 'disneyclient'),
                    password=os.getenv('MYSQL_PASSWORD', ''),
                    db=os.getenv('MYSQL_DATABASE', 'disneyclient'),
                    minsize=1, maxsize=int(os.getenv('MYSQL_POOL_SIZE', '10')),
                    pool_recycle=300, connect_timeout=5, autocommit=False,
                    charset='utf8mb4', init_command="SET time_zone = '+00:00'",
                )
                return
            except (OSError, asyncmy.errors.OperationalError):
                if attempt == 2:
                    raise
                await asyncio.sleep(0.5 * 2**attempt)

    async def close(self):
        if self.pool is not None:
            self.pool.close()
            await self.pool.wait_closed()
            self.pool = None

    @asynccontextmanager
    async def transaction(self):
        if self.pool is None:
            raise RuntimeError('Database not initialized')
        async with self.pool.acquire() as conn:
            await conn.ping(reconnect=True)
            await conn.begin()
            try:
                async with conn.cursor(DictCursor) as cur:
                    yield cur
                await conn.commit()
            except BaseException:
                await conn.rollback()
                raise

    async def migrate(self):
        async with self.transaction() as cur:
            await cur.execute('SELECT VERSION() AS version')
            version = (await cur.fetchone())['version']
            check_server_version(version)
            await cur.execute("SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='users'")
            if (await cur.fetchone())['n']:
                await cur.execute("SHOW COLUMNS FROM users LIKE 'id'")
                if not await cur.fetchone():
                    raise RuntimeError('Legacy users table detected. Use a new database; see INSTALL_WINDOWS.md.')
            sql = (Path(__file__).parent / 'migrations/001_initial.sql').read_text()
            for statement in sql.split(';'):
                if statement.strip():
                    await cur.execute(statement)

            # CREATE IF NOT EXISTS does not upgrade existing installations.
            await cur.execute("SHOW COLUMNS FROM sessions LIKE 'device_hash'")
            if not await cur.fetchone():
                await cur.execute("ALTER TABLE sessions ADD COLUMN device_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL, ADD INDEX sessions_device (user_id,license_id,device_hash,expires_at)")

    async def audit(self, action, user_id=None, ip=None):
        async with self.transaction() as cur:
            await cur.execute('INSERT INTO audit_logs(user_id,action,ip_address) VALUES(%s,%s,%s)', (user_id, action, ip))

    async def create_key(self, username, days, level='GOLD_II', max_activations=1):
        raw = secrets.token_urlsafe(32)
        expiry = utcnow() + timedelta(days=days) if days else None
        async with self.transaction() as cur:
            await cur.execute('INSERT INTO users(username,level) VALUES(%s,%s) ON DUPLICATE KEY UPDATE username=%s', (username, level, username))
            await cur.execute('SELECT id FROM users WHERE username=%s', (username,))
            uid = (await cur.fetchone())['id']
            await cur.execute('INSERT INTO license_keys(key_hash,user_id,expires_at,max_activations) VALUES(%s,%s,%s,%s)', (digest(raw), uid, expiry, max_activations))
            lid = cur.lastrowid
            await cur.execute("INSERT INTO audit_logs(user_id,action) VALUES(%s,'admin.create-key')", (uid,))
        return lid, raw

    async def authenticate(self, raw, device, ip):
        result = None
        failure = 'invalid key'
        async with self.transaction() as cur:
            await cur.execute('SELECT l.*,u.status AS user_status,u.level,u.connection_limit,u.browser_access FROM license_keys l JOIN users u ON u.id=l.user_id WHERE l.key_hash=%s FOR UPDATE', (digest(raw),))
            row = await cur.fetchone()
            uid = row['user_id'] if row else None
            now = utcnow()
            if row:
                if row['status'] != 'active' or row['user_status'] != 'active':
                    failure = 'access blocked'
                elif row['expires_at'] and row['expires_at'] <= now:
                    failure = 'expired key'
                elif not row['browser_access']:
                    failure = 'client access disabled'
                else:
                    # Lock before snapshot reads so concurrent logins see committed sessions.
                    await cur.execute('SELECT connection_limit FROM users WHERE id=%s FOR UPDATE', (uid,))
                    limits = await cur.fetchone()
                    dh = digest(device)
                    await cur.execute('SELECT device_hash FROM license_activations WHERE license_id=%s', (row['id'],))
                    devices = [r['device_hash'] for r in await cur.fetchall()]
                    if dh not in devices and len(devices) >= row['max_activations']:
                        failure = 'activation limit exceeded'
                    else:
                        # Legacy sessions can be attributed only when this key has
                        # exactly one known activation; never guess with several.
                        if len(devices) == 1 and devices[0] == dh:
                            await cur.execute('UPDATE sessions SET device_hash=%s WHERE user_id=%s AND license_id=%s AND device_hash IS NULL', (dh, uid, row['id']))
                        # A device moving between networks replaces its old IP-bound
                        # sessions, without evicting other devices or other keys.
                        await cur.execute('UPDATE sessions SET expires_at=%s WHERE user_id=%s AND license_id=%s AND device_hash=%s AND ip_address<>%s AND expires_at>UTC_TIMESTAMP(6)', (now, uid, row['id'], dh, ip))
                        # Repeated browser logins from one address are not new connections.
                        # Existing addresses may reconnect even when the address limit is full.
                        await cur.execute('SELECT COUNT(DISTINCT ip_address) AS n, MAX(ip_address=%s) AS same_ip FROM sessions WHERE user_id=%s AND expires_at>UTC_TIMESTAMP(6)', (ip, uid))
                        active = await cur.fetchone()
                        if not active['same_ip'] and active['n'] >= limits['connection_limit']:
                            failure = 'connection limit exceeded'
                        else:
                            if dh not in devices:
                                await cur.execute('INSERT INTO license_activations(license_id,device_hash) VALUES(%s,%s)', (row['id'], dh))
                            cookie, access = secrets.token_urlsafe(32), secrets.token_urlsafe(32)
                            expiry = min(now + timedelta(hours=3), row['expires_at']) if row['expires_at'] else now + timedelta(hours=3)
                            await cur.execute('INSERT INTO sessions(user_id,license_id,session_token_hash,access_token_hash,expires_at,ip_address,device_hash) VALUES(%s,%s,%s,%s,%s,%s,%s)', (uid, row['id'], digest(cookie), digest(access), expiry, ip, dh))
                            await cur.execute('UPDATE license_keys SET activated_at=COALESCE(activated_at,%s),last_used=%s WHERE id=%s', (now, now, row['id']))
                            await cur.execute('UPDATE users SET last_login=%s WHERE id=%s', (now, uid))
                            result = (cookie, access, row['level'])
            await cur.execute('INSERT INTO audit_logs(user_id,action,ip_address) VALUES(%s,%s,%s)', (uid, 'auth.accepted' if result else 'auth.denied', ip))
        if result is None:
            raise AuthError(failure)
        return result

    async def session(self, token, ip, *, cookie=False, flash=None):
        if not token:
            return None
        column = 'session_token_hash' if cookie else 'access_token_hash'
        async with self.transaction() as cur:
            await cur.execute(f'SELECT s.*,u.level,u.username,l.key_hash FROM sessions s JOIN users u ON u.id=s.user_id JOIN license_keys l ON l.id=s.license_id WHERE s.{column}=%s AND s.ip_address=%s AND s.expires_at>UTC_TIMESTAMP(6) AND u.status=\'active\' AND l.status=\'active\' AND (l.expires_at IS NULL OR l.expires_at>UTC_TIMESTAMP(6)) FOR UPDATE', (digest(token), ip))
            row = await cur.fetchone()
            if row and flash is not None:
                fh = digest(flash)
                if row['flash_token_hash'] and row['flash_token_hash'] != fh:
                    return None
                await cur.execute('UPDATE sessions SET flash_token_hash=%s WHERE id=%s', (fh, row['id']))
            return row

    async def get_data(self, uid):
        async with self.transaction() as cur:
            await cur.execute('SELECT * FROM user_data WHERE user_id=%s', (uid,))
            return await cur.fetchone() or {}

    async def put_data(self, uid, field, value):
        if field not in {'menu','map_data','soft_data'}:
            raise ValueError('Invalid data field')
        async with self.transaction() as cur:
            await cur.execute(f'INSERT INTO user_data(user_id,{field}) VALUES(%s,%s) ON DUPLICATE KEY UPDATE {field}=%s', (uid, value, value))
