# Python / test_native_api.py / Python 3.11 / verify loopback authentication and native operation dispatch
import asyncio,importlib,json,sys,types,unittest
from pathlib import Path
from unittest.mock import AsyncMock,patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"DisneyClient"))
from aiohttp import web
pkg=types.ModuleType('api');pkg.__path__=[str(Path(__file__).resolve().parents[1]/"DisneyClient/api")];sys.modules['api']=pkg
mod=importlib.import_module('api.native_patch')
class FakeManager:
 def __init__(self):self.calls=[]
 def set_enabled(self,enabled,owner):self.calls.append((enabled,owner));return {'enabled':enabled,'message':'done'}
class Request:
 remote='127.0.0.1'
 def __init__(self,**values):self.app={'native_wj':FakeManager(),'native_lock':asyncio.Lock(),'native_rates':{}};self.values={'feature':'wj_fly','enabled':'1'};self.values.update(values)
 async def post(self):return self.values
class Tests(unittest.TestCase):
 def test_valid_dispatch(self):
  r=Request()
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):out=asyncio.run(mod.NativePatch(r).post())
  self.assertEqual(json.loads(out.text)['enabled'],True);self.assertEqual(r.app['native_wj'].calls,[(True,7)])
 def test_remote_rejected(self):
  r=Request();r.remote='192.0.2.1'
  with self.assertRaises(web.HTTPForbidden):asyncio.run(mod.NativePatch(r).post())
  self.assertFalse(r.app['native_wj'].calls)
 def test_auth_required(self):
  r=Request()
  with patch.object(mod,'authorize',AsyncMock(side_effect=web.HTTPUnauthorized())):
   with self.assertRaises(web.HTTPUnauthorized):asyncio.run(mod.NativePatch(r).post())
  self.assertFalse(r.app['native_wj'].calls)
 def test_other_feature_rejected(self):
  r=Request(feature='arbitrary_write')
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):
   with self.assertRaises(web.HTTPBadRequest):asyncio.run(mod.NativePatch(r).post())
  self.assertFalse(r.app['native_wj'].calls)
 def test_error_message_reaches_flash(self):
  r=Request()
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})),patch.object(r.app['native_wj'],'set_enabled',side_effect=mod.PatchError('AoB nao encontrado')):
   out=asyncio.run(mod.NativePatch(r).post())
  self.assertEqual(out.status,200);self.assertEqual(json.loads(out.text),{'success':False,'enabled':None,'message':'AoB nao encontrado'})
 def test_rate_limit(self):
  r=Request();r.app['native_rates'][7]=mod.time.monotonic()
  with patch.object(mod,'authorize',AsyncMock(return_value={'user_id':7})):out=asyncio.run(mod.NativePatch(r).post())
  self.assertEqual(out.status,429);self.assertFalse(r.app['native_wj'].calls)
if __name__=='__main__':unittest.main()
