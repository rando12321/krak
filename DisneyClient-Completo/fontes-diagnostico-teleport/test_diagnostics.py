# Python / test_diagnostics.py / Python 3.11 / physics diagnostic validation without credentials or arbitrary payloads
import asyncio,importlib,sys,types,unittest,tempfile,json
from pathlib import Path
from unittest.mock import AsyncMock,patch
sys.path.insert(0,'/workspace/work/disney-user-fix/input/DisneyClient-Completo/DisneyClient')
pkg=types.ModuleType('api');pkg.__path__=['/workspace/work/teleport-diagnostics','/workspace/work/disney-user-fix/input/DisneyClient-Completo/DisneyClient/api'];sys.modules['api']=pkg
from aiohttp import web
mod=importlib.import_module('api.diagnostics')
class Request:
 remote='127.0.0.1'
 def __init__(self,root,**values):self.app={'root':root,'diagnostics_rate':{}};self.values={'event':'physics','code':'0','channel':'client','elapsed':'123','options':'mass_reduction','feature':'mass','reason':'paused_cheese'};self.values.update(values)
 async def post(self):return self.values
class Tests(unittest.TestCase):
 def test_physics_event_records_whitelisted_context_only(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder)/'DisneyClient';root.mkdir();request=Request(root,access_token='PRIVATE',message='PRIVATE',payload='PRIVATE')
   with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):r=asyncio.run(mod.Diagnostics(request).post())
   content=(root.parent/'logs-client/flash-diagnostics.jsonl').read_text();row=json.loads(content)
   self.assertEqual(r.status,200);self.assertEqual(row['feature'],'mass');self.assertEqual(row['reason'],'paused_cheese');self.assertNotIn('PRIVATE',content)
 def test_unknown_reason_rejected(self):
  r=Request(Path('/tmp'),reason='untrusted detail')
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):
   with self.assertRaises(web.HTTPBadRequest):asyncio.run(mod.Diagnostics(r).post())
 def test_remote_rejected(self):
  r=Request(Path('/tmp'));r.remote='192.0.2.1'
  with self.assertRaises(web.HTTPForbidden):asyncio.run(mod.Diagnostics(r).post())
 def test_auth_required(self):
  r=Request(Path('/tmp'))
  with patch.object(mod,'authorize',AsyncMock(side_effect=web.HTTPUnauthorized())):
   with self.assertRaises(web.HTTPUnauthorized):asyncio.run(mod.Diagnostics(r).post())
 def test_old_events_remain_accepted(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder)/'DisneyClient';root.mkdir();r=Request(root,event='guard_ready')
   with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):out=asyncio.run(mod.Diagnostics(r).post())
   row=json.loads((root.parent/'logs-client/flash-diagnostics.jsonl').read_text());self.assertEqual(out.status,200);self.assertNotIn('feature',row)
class TeleportTests(unittest.TestCase):
 def request(self,root,**kw):
  values=dict(event='teleport',channel='client',options='teleport',reason='requested',build='sdds-legacy-teleport-diag-v4',press='3',x='100',y='200',target_x='400',target_y='250',alive='1');values.update(kw);return Request(root,**values)
 def test_teleport_whitelist(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder)/'DisneyClient';root.mkdir();r=self.request(root,access_token='PRIVATE',message='PRIVATE')
   with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):out=asyncio.run(mod.Diagnostics(r).post())
   content=(root.parent/'logs-client/flash-diagnostics.jsonl').read_text();row=json.loads(content)
   self.assertEqual(out.status,200);self.assertEqual(row['press'],3);self.assertEqual(row['target_x'],400);self.assertIs(row['alive'],True);self.assertNotIn('PRIVATE',content)
 def test_invalid_context_rejected(self):
  for values in ({'build':'unknown'},{'press':'-1'},{'target_x':'NaN'},{'reason':'untrusted'},{'alive':'maybe'}):
   r=self.request(Path('/tmp'),**values)
   with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):
    with self.assertRaises(web.HTTPBadRequest):asyncio.run(mod.Diagnostics(r).post())
 def test_teleport_budget_does_not_consume_socket_budget(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder)/'DisneyClient';root.mkdir();r=self.request(root)
   with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):
    for i in range(120):asyncio.run(mod.Diagnostics(r).post())
    with self.assertRaises(web.HTTPTooManyRequests):asyncio.run(mod.Diagnostics(r).post())
    r.values.update(event='socket_close',options='');out=asyncio.run(mod.Diagnostics(r).post());self.assertEqual(out.status,200)
if __name__=='__main__':unittest.main()

