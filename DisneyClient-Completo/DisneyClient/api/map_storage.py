import re
from aiohttp import web
from utils import cryptjson
from .common import authorize

class MapStorage(web.View):
    async def get(self):
        user = await authorize(self.request, allow_cookie=True)
        data = await self.request.app['db'].get_data(user['user_id'])
        config = self.request.app['config']
        if config.get('map_storage_fetch') and data.get('map_data'):
            return web.Response(body=data['map_data'])
        if user['level'] in config.get('storage_allowed_levels', []):
            return web.FileResponse(self.request.app['root'] / 'public/maps.json')
        raise web.HTTPForbidden()

    async def post(self):
        user = await authorize(self.request, allow_cookie=True)
        if user['level'] not in self.request.app['config'].get('storage_allowed_levels', []):
            raise web.HTTPForbidden()
        form = await self.request.post()
        code, info = form.get('code'), form.get('info')
        method = self.request.query.get('method')
        if not code or not re.fullmatch(r'@?[0-9]+', code) or method not in {'save','del'}:
            raise web.HTTPBadRequest()
        # Row lock prevents concurrent read/modify/write losing a map update.
        async with self.request.app['db'].transaction() as cur:
            await cur.execute('INSERT INTO user_data(user_id) VALUES(%s) ON DUPLICATE KEY UPDATE user_id=user_id', (user['user_id'],))
            await cur.execute('SELECT map_data FROM user_data WHERE user_id=%s FOR UPDATE', (user['user_id'],))
            previous = (await cur.fetchone())['map_data']
            raw = cryptjson.text_decode(previous) if previous else b''
            chunks = [p for p in raw.split(b'#') if p and not p.startswith(code.encode() + b':')]
            if method == 'save':
                if not info:
                    raise web.HTTPBadRequest()
                chunks.append(code.encode() + b':' + cryptjson.text_decode(info))
            await cur.execute('UPDATE user_data SET map_data=%s WHERE user_id=%s', (cryptjson.text_encode(b'#'.join(chunks)), user['user_id']))
        return web.Response(status=204)
