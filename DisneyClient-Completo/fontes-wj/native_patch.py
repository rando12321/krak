# Python / native_patch.py / Python 3.11 + aiohttp / authenticated loopback control for the WJ Fly patch
import asyncio,time
from aiohttp import web
from .common import authorize
from native_wj import PatchError

async def finish_thread(function,*args):
    task=asyncio.create_task(asyncio.to_thread(function,*args))
    try:return await asyncio.shield(task)
    except asyncio.CancelledError:
        try:await task
        finally:raise

class NativePatch(web.View):
    async def post(self):
        if self.request.remote not in {'127.0.0.1','::1'}:raise web.HTTPForbidden()
        row=await authorize(self.request)
        values=await self.request.post()
        if set(values)!={'feature','enabled'} or values['feature']!='wj_fly' or values['enabled'] not in {'0','1'}:raise web.HTTPBadRequest()
        owner=row['user_id'];now=time.monotonic();last=self.request.app['native_rates'].get(owner,-100)
        if now-last<0.5:return web.json_response({'enabled':None,'message':'Aguarde a operacao anterior terminar.'},status=429)
        self.request.app['native_rates'][owner]=now
        async with self.request.app['native_lock']:
            try:
                result=await finish_thread(self.request.app['native_wj'].set_enabled,values['enabled']=='1',owner)
                return web.json_response(result)
            except (PatchError,ProcessLookupError,OSError) as error:
                message=str(error) if isinstance(error,PatchError) else 'O Adobe_10.exe foi encerrado ou a memoria deixou de estar disponivel.'
                return web.json_response({'success':False,'enabled':None,'message':message})

async def restore_native(app):
    async with app['native_lock']:
        try:await finish_thread(app['native_wj'].close)
        except (PatchError,ProcessLookupError,OSError) as error:
            print('WJ Fly: restauracao nao confirmada ('+type(error).__name__+'). Feche o Adobe_10.exe.',flush=True)
