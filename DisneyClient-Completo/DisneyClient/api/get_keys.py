from aiohttp import web
import aiohttp
import infrastructure
from utils import cryptjson
from .common import authorize

class GetKeys(web.View):
    async def get(self):
        if not self.request.query.get('flash_token'):
            raise web.HTTPBadRequest(text='flash_token required')
        row = await authorize(self.request)
        endpoint = self.request.app['parser_url']
        if not endpoint:
            return web.json_response({'success': False, 'error': 'parser not configured'}, status=503)
        try:
            async with infrastructure.get_session().get(endpoint + '/api/tfm_keys', headers={'Authorization': 'Bearer ' + self.request.app['parser_token']}) as upstream:
                if upstream.status != 200:
                    raise web.HTTPBadGateway(text='Parser rejected request')
                keys = await upstream.json()
                if not isinstance(keys, dict):
                    raise ValueError('Invalid parser response')
        except (aiohttp.ClientError, TimeoutError, ValueError):
            raise web.HTTPBadGateway(text='Parser unavailable')
        data = await self.request.app['db'].get_data(row['user_id'])
        keys.update(maps_allowed=bool(data.get('map_data')) and self.request.app['config'].get('map_storage_fetch', False), client_version=self.request.app['config']['client_version'], discord=[], premium_level=row['level'])
        return web.json_response({'success': True, 'keys': cryptjson.json_zip(keys).decode()})
