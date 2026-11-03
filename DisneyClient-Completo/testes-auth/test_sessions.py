"""Exercise real auth/admin code against SQL fixtures (SQLite adapter, not MySQL)."""
import sys,pathlib,sqlite3,unittest,argparse
from contextlib import asynccontextmanager
from datetime import timedelta
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'DisneyClient'))
from database import Database,AuthError,digest,utcnow
import admin

class Cursor:
 def __init__(self,db):self.db=db;self.cur=db.sql.cursor()
 async def execute(self,sql,args=()):
  self.db.commands.append(sql)
  self.cur.execute(sql.replace(' FOR UPDATE','').replace('%s','?'),args)
 async def fetchone(self):
  r=self.cur.fetchone();return dict(r) if r else None
 async def fetchall(self):return [dict(r) for r in self.cur.fetchall()]
class Store(Database):
 def __init__(self):
  super().__init__();self.commands=[];self.sql=sqlite3.connect(':memory:');self.sql.row_factory=sqlite3.Row
  self.sql.create_function('UTC_TIMESTAMP',1,lambda _:str(utcnow()))
  self.sql.executescript('''CREATE TABLE users(id INTEGER PRIMARY KEY,status TEXT,level TEXT,connection_limit INT,browser_access INT,last_login TEXT);
CREATE TABLE license_keys(id INTEGER PRIMARY KEY,user_id INT,key_hash TEXT,status TEXT,expires_at TEXT,max_activations INT,activated_at TEXT,last_used TEXT);
CREATE TABLE license_activations(license_id INT,device_hash TEXT);
CREATE TABLE sessions(id INTEGER PRIMARY KEY,user_id INT,license_id INT,session_token_hash TEXT,access_token_hash TEXT,expires_at TEXT,ip_address TEXT);
CREATE TABLE audit_logs(user_id INT,action TEXT,ip_address TEXT);
INSERT INTO users VALUES(1,'active','GOLD_II',2,1,NULL);
''')
  for lid in (1,2):self.sql.execute('INSERT INTO license_keys VALUES(?,1,?,\'active\',NULL,1,NULL,NULL)',(lid,digest('test-key-'+str(lid))))
  for lid in (1,2):self.sql.execute('INSERT INTO license_activations VALUES(?,?)',(lid,digest('test-device')))
  self.sql.commit()
 @asynccontextmanager
 async def transaction(self):
  try:yield Cursor(self);self.sql.commit()
  except BaseException:self.sql.rollback();raise
 def seed(self,ip,lid=1,expired=False):
  expiry=utcnow()+timedelta(hours=-1 if expired else 1)
  self.sql.execute('INSERT INTO sessions(user_id,license_id,expires_at,ip_address) VALUES(1,?,?,?)',(lid,str(expiry),ip));self.sql.commit()
class Tests(unittest.IsolatedAsyncioTestCase):
 def setUp(self):self.db=Store()
 def tearDown(self):self.db.sql.close()
 async def auth(self,ip):return await self.db.authenticate('test-key-1','test-device',ip)
 async def test_duplicate_other_ip_does_not_fill_limit(self):
  for _ in range(5):self.db.seed('192.0.2.1')
  self.assertEqual((await self.auth('192.0.2.2'))[2],'GOLD_II')
 async def test_existing_ip_reconnects_at_limit(self):
  self.db.seed('192.0.2.1');self.db.seed('192.0.2.2')
  self.assertEqual((await self.auth('192.0.2.1'))[2],'GOLD_II')
 async def test_new_third_ip_still_blocked(self):
  self.db.seed('192.0.2.1');self.db.seed('192.0.2.2')
  with self.assertRaisesRegex(AuthError,'connection limit exceeded'):await self.auth('192.0.2.3')
  self.assertEqual(self.db.sql.execute('SELECT COUNT(*) FROM sessions').fetchone()[0],2)
 async def test_expired_session_not_counted(self):
  self.db.seed('192.0.2.1');self.db.seed('192.0.2.2',expired=True)
  self.assertTrue(await self.auth('192.0.2.3'))
 async def test_limits_apply_across_keys_of_same_user(self):
  self.db.seed('192.0.2.1',lid=1);self.db.seed('192.0.2.2',lid=2)
  with self.assertRaises(AuthError):await self.auth('192.0.2.3')
 async def test_invalid_key_remains_rejected(self):
  with self.assertRaisesRegex(AuthError,'invalid key'):await self.db.authenticate('invalid','test-device','192.0.2.1')
 async def test_activation_limit_remains_enforced(self):
  with self.assertRaisesRegex(AuthError,'activation limit exceeded'):await self.db.authenticate('test-key-1','other-device','192.0.2.1')
 async def test_lock_before_snapshot_reads(self):
  await self.auth('192.0.2.1');cmd=self.db.commands
  self.assertLess(next(i for i,x in enumerate(cmd) if x.startswith('SELECT connection_limit')),next(i for i,x in enumerate(cmd) if x.startswith('SELECT device_hash')))
 async def test_clear_only_selected_key_sessions(self):
  self.db.seed('192.0.2.1',lid=1);self.db.seed('192.0.2.2',lid=2)
  args=admin.parser().parse_args(['clear-key-sessions','--id','1']);await admin.execute(args,self.db)
  self.assertEqual([r[0] for r in self.db.sql.execute('SELECT license_id FROM sessions')],[2])
  self.assertEqual(self.db.sql.execute('SELECT status FROM license_keys WHERE id=1').fetchone()[0],'active')
  self.assertEqual(self.db.sql.execute('SELECT COUNT(*) FROM license_activations').fetchone()[0],2)
  self.assertEqual(self.db.sql.execute("SELECT COUNT(*) FROM audit_logs WHERE action='admin.clear-key-sessions'").fetchone()[0],1)
 async def test_unknown_key_reset_does_not_delete(self):
  self.db.seed('192.0.2.1')
  with self.assertRaisesRegex(ValueError,'License not found'):await admin.execute(argparse.Namespace(command='clear-key-sessions',id=999),self.db)
  self.assertEqual(self.db.sql.execute('SELECT COUNT(*) FROM sessions').fetchone()[0],1)
if __name__=='__main__':unittest.main()
