from aiohttp import web
from .common import authorize, address

class TfmLogin(web.View):
    async def get(self):
        row = await authorize(self.request)
        await self.request.app['db'].audit('client.login', row['user_id'], address(self.request))
        return web.Response(status=204)
