"""Local administrator CLI. Reads passphrases from a prompt or explicit stdin."""
import argparse
import asyncio
import getpass
import hashlib
import hmac
import json
import os
import secrets
import sys
from datetime import timedelta
import infrastructure  # loads the project .env without opening connections
from database import Database, utcnow


def password_hash(password, salt=None):
    if len(password) < 12:
        raise ValueError('Use a passphrase of at least 12 characters')
    salt = salt or secrets.token_hex(16)
    result = hashlib.scrypt(password.encode(), salt=bytes.fromhex(salt), n=16384, r=8, p=1).hex()
    return f'scrypt${salt}${result}'


def verify_password(password, expected):
    try:
        kind, salt, value = expected.split('$')
        if kind != 'scrypt':
            return False
        return hmac.compare_digest(password_hash(password, salt), expected)
    except (ValueError, TypeError):
        return False


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--password-stdin', action='store_true', help='Read admin passphrase from stdin, never an argument')
    sub = p.add_subparsers(dest='command', required=True)
    sub.add_parser('hash-password')
    sub.add_parser('migrate')
    create = sub.add_parser('create-key')
    create.add_argument('--username', default=None)
    create.add_argument('--days', type=int, choices=[0,1,7,30,90], default=30, help='0 = permanent')
    create.add_argument('--level', choices=['GOLD_I','GOLD_II','PLATINUM'], default='GOLD_II')
    create.add_argument('--max-activations',type=int,default=1)
    sub.add_parser('list-keys')
    sub.add_parser('list-users')
    sub.add_parser('audit')
    for cmd in ['show-key','revoke-key','renew-key','block-user','unblock-user','clear-key-sessions']:
        c = sub.add_parser(cmd)
        c.add_argument('--id', type=int, required=True)
        if cmd == 'renew-key':
            c.add_argument('--days', type=int, choices=[0,1,7,30,90], required=True)
    return p


async def execute(args, db):
    if args.command == 'migrate':
        return {'status':'schema initialized'}
    if args.command == 'create-key':
        if args.max_activations < 1:
            raise ValueError('max-activations must be positive')
        username = args.username or 'user-' + secrets.token_hex(8)
        lid, key = await db.create_key(username,args.days,args.level,args.max_activations)
        # The only deliberate full-key output: one-time delivery to the administrator.
        return {'id':lid,'username':username,'key':key,'warning':'Store securely; this key cannot be recovered.'}
    async with db.transaction() as cur:
        if args.command in {'list-keys','show-key'}:
            sql = 'SELECT id,user_id,created_at,expires_at,activated_at,last_used,status,max_activations FROM license_keys'
            await cur.execute(sql + (' WHERE id=%s' if args.command == 'show-key' else ' ORDER BY id DESC LIMIT 200'), (args.id,) if args.command == 'show-key' else ())
            return await cur.fetchall()
        if args.command == 'list-users':
            await cur.execute('SELECT id,username,status,level,created_at,last_login FROM users ORDER BY id DESC LIMIT 200')
            return await cur.fetchall()
        if args.command == 'audit':
            await cur.execute('SELECT * FROM audit_logs ORDER BY id DESC LIMIT 200')
            return await cur.fetchall()
        if args.command in {'block-user','unblock-user'}:
            await cur.execute('SELECT id FROM users WHERE id=%s FOR UPDATE', (args.id,))
            if not await cur.fetchone():
                raise ValueError('User not found')
            await cur.execute('UPDATE users SET status=%s WHERE id=%s', ('blocked' if args.command == 'block-user' else 'active', args.id))
            await cur.execute('DELETE FROM sessions WHERE user_id=%s', (args.id,))
            uid = args.id
        else:
            await cur.execute('SELECT user_id FROM license_keys WHERE id=%s FOR UPDATE', (args.id,))
            row = await cur.fetchone()
            if not row:
                raise ValueError('License not found')
            uid = row['user_id']
            if args.command == 'clear-key-sessions':
                pass  # Delete only this license's sessions below; leave key and activations intact.
            elif args.command == 'revoke-key':
                await cur.execute("UPDATE license_keys SET status='revoked' WHERE id=%s", (args.id,))
            else:
                # Renewal explicitly reactivates the license, counted from now.
                expiry = utcnow() + timedelta(days=args.days) if args.days else None
                await cur.execute("UPDATE license_keys SET expires_at=%s,status='active' WHERE id=%s", (expiry,args.id))
            await cur.execute('DELETE FROM sessions WHERE license_id=%s', (args.id,))
        await cur.execute('INSERT INTO audit_logs(user_id,action) VALUES(%s,%s)', (uid,'admin.' + args.command))
        return {'status':'updated'}


async def run(args):
    db = Database()
    try:
        await db.open()
        await db.migrate()
        return await execute(args,db)
    finally:
        await db.close()


def main():
    args = parser().parse_args()
    try:
        password = sys.stdin.readline().rstrip('\r\n') if args.password_stdin else getpass.getpass('Admin passphrase: ')
        if args.command == 'hash-password':
            print(password_hash(password))
            return 0
        expected = os.getenv('ADMIN_PASSWORD_HASH','')
        if not expected or not verify_password(password,expected):
            print('Administrator authentication failed. Configure ADMIN_PASSWORD_HASH in .env.',file=sys.stderr)
            return 1
        print(json.dumps(asyncio.run(run(args)),default=str,indent=2))
        return 0
    except (ValueError, OSError) as exc:
        print(f'Admin operation failed ({type(exc).__name__}). Check configuration and IDs.',file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
