# Python / transformice.py / Python 3.11 / serve the current parsed game
from aiohttp import web
import aiohttp
import infrastructure
from .common import authorize

class Transformice(web.View):
    async def get(self):
        root = self.request.app['root']
        if 'swf' in self.request.query:
            endpoint = self.request.app['parser_url']
            if endpoint:
                try:
                    async with infrastructure.get_session().get(endpoint + '/transformice?swf', headers={'Authorization': 'Bearer ' + self.request.app['parser_token']}) as upstream:
                        if upstream.status != 200:
                            raise web.HTTPServiceUnavailable(text='Game SWF not ready')
                        content = await upstream.read()
                    if len(content) < 8 or content[:3] not in (b'FWS', b'CWS', b'ZWS'):
                        raise web.HTTPBadGateway(text='Invalid parser SWF')
                    return web.Response(body=content, content_type='application/x-shockwave-flash', headers={'Cache-Control': 'no-store'})
                except (aiohttp.ClientError, TimeoutError):
                    raise web.HTTPBadGateway(text='Parser unavailable')
            path = root / 'tfm.swf'
            if not path.is_file():
                return web.json_response({'success': False, 'error': 'SWF not configured'}, status=503)
            return web.FileResponse(path)
        await authorize(self.request)
        return web.FileResponse(root / 'public/ChargeurTransformice.swf')
