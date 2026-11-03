# Python / test_diagnostics.py / Python 3.11 / local diagnostics authorization and redaction
from pathlib import Path
import asyncio,importlib,sys,tempfile,unittest,json,types
from unittest.mock import patch,AsyncMock
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'DisneyClient'))
from aiohttp import web
package=types.ModuleType('api');package.__path__=[str(Path(__file__).resolve().parents[1]/'DisneyClient/api')];sys.modules['api']=package
mod=importlib.import_module('api.diagnostics')
class Request:
 remote='127.0.0.1'
 def __init__(self,root,**values):self.app={'root':root,'diagnostics_rate':{}};self.values={'event':'guard_ready','code':'0','channel':'client','elapsed':'100','options':''};self.values.update(values)
 async def post(self):return self.values
class Tests(unittest.TestCase):
 def test_valid_log_excludes_tokens_and_payloads(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d)/'DisneyClient';root.mkdir();request=Request(root,options='macro,change_movement_speed',access_token='PRIVATE',payload='PRIVATE')
   with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):response=asyncio.run(mod.Diagnostics(request).post())
   self.assertEqual(response.status,200);line=(root.parent/'logs-client/flash-diagnostics.jsonl').read_text();self.assertNotIn('PRIVATE',line);self.assertNotIn('user_id',line)
   self.assertEqual(json.loads(line)['active_options'],['macro','change_movement_speed'])
 def test_remote_rejected(self):
  request=Request(Path('/tmp'));request.remote='192.0.2.1'
  with self.assertRaises(web.HTTPForbidden):asyncio.run(mod.Diagnostics(request).post())
 def test_unauthenticated_rejected(self):
  request=Request(Path('/tmp'))
  with patch.object(mod,'authorize',AsyncMock(side_effect=web.HTTPUnauthorized())):
   with self.assertRaises(web.HTTPUnauthorized):asyncio.run(mod.Diagnostics(request).post())
 def test_unknown_option_rejected(self):
  request=Request(Path('/tmp'),options='token-secret')
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):
   with self.assertRaises(web.HTTPBadRequest):asyncio.run(mod.Diagnostics(request).post())
 def test_rate_limit(self):
  request=Request(Path('/tmp'));request.app['diagnostics_rate'][7]=(mod.time.monotonic(),30)
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):
   with self.assertRaises(web.HTTPTooManyRequests):asyncio.run(mod.Diagnostics(request).post())
if __name__=='__main__':unittest.main()
