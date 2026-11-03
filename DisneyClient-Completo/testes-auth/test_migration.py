"""Check migration decisions/idempotence with a DDL cursor model, not live MySQL."""
import pathlib
import sys
import unittest
from contextlib import asynccontextmanager
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'DisneyClient'))
from database import Database


class MigrationStore(Database):
    def __init__(self, sessions_exist=True, device_column=False):
        super().__init__()
        self.sessions_exist=sessions_exist
        self.device_column=device_column
        self.commands=[]
        self.result=None

    @asynccontextmanager
    async def transaction(self):
        yield self

    async def execute(self, sql, args=()):
        self.commands.append(sql)
        stripped=sql.strip()
        if stripped.startswith('SELECT VERSION'): self.result={'version':'8.0.40'}
        elif 'information_schema.tables' in sql: self.result={'n':1}
        elif "SHOW COLUMNS FROM users" in sql: self.result={'Field':'id'}
        elif "SHOW COLUMNS FROM sessions" in sql: self.result={'Field':'device_hash'} if self.device_column else None
        elif 'CREATE TABLE IF NOT EXISTS sessions' in sql and not self.sessions_exist:
            self.sessions_exist=True
            self.device_column='device_hash CHAR(64)' in sql
        elif stripped.startswith('ALTER TABLE sessions'):
            if self.device_column: raise AssertionError('duplicate ALTER')
            self.device_column=True

    async def fetchone(self):
        return self.result


class MigrationTests(unittest.IsolatedAsyncioTestCase):
    async def test_existing_installation_adds_device_column(self):
        db=MigrationStore()
        await db.migrate()
        self.assertTrue(db.device_column)
        self.assertEqual(sum(q.startswith('ALTER TABLE sessions') for q in db.commands),1)

    async def test_upgrade_is_idempotent(self):
        db=MigrationStore()
        await db.migrate();await db.migrate()
        self.assertEqual(sum(q.startswith('ALTER TABLE sessions') for q in db.commands),1)

    async def test_fresh_installation_includes_column_without_alter(self):
        db=MigrationStore(sessions_exist=False)
        await db.migrate()
        self.assertTrue(db.device_column)
        self.assertFalse(any(q.startswith('ALTER TABLE sessions') for q in db.commands))
