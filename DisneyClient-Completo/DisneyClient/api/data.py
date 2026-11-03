import json
from aiohttp import web
from utils import cryptjson
from .common import authorize

class Data(web.View):
    async def get(self):
        user = await authorize(self.request, allow_cookie=True)
        data = await self.request.app['db'].get_data(user['user_id'])
        q = self.request.query
        root = self.request.app['root']
        if 'soft' in q:
            return web.Response(body=data.get('soft_data') or b'')
        if 'protected' in q:
            return web.FileResponse(root / 'public/protectedmaps.json')
        if 'config' in q:
            menu = data.get('menu')
            return web.json_response(json.loads(menu) if isinstance(menu, str) else menu or {})
        if 'record_list' in q:
            return web.FileResponse(root / 'public/record_list.json')
        return web.Response(body=b'')

    async def post(self):
        user = await authorize(self.request, allow_cookie=True)
        form = await self.request.post()
        db = self.request.app['db']
        if 'soft' in form:
            if user['level'] != 'PLATINUM':
                raise web.HTTPForbidden()
            previous = await db.get_data(user['user_id'])
            changes = cryptjson.json_unzip(form['soft'])
            merged = cryptjson.json_unzip(previous['soft_data']) if previous.get('soft_data') else {}
            if not isinstance(changes, dict) or not isinstance(merged, dict):
                raise web.HTTPBadRequest()
            for code, value in changes.items():
                if code.startswith('@') and value:
                    merged[code] = value
                else:
                    merged.pop(code, None)
            await db.put_data(user['user_id'], 'soft_data', cryptjson.json_zip(merged))
        elif 'config' in form:
            menu = json.loads(form['config'])
            if not isinstance(menu, dict):
                raise web.HTTPBadRequest()
            await db.put_data(user['user_id'], 'menu', json.dumps(menu))
        else:
            raise web.HTTPBadRequest()
        return web.Response(status=204)

class Soft(web.View):
    async def get(self):
        user = await authorize(self.request, allow_cookie=True)
        if user['level'] != 'PLATINUM':
            raise web.HTTPForbidden()
        return web.FileResponse(self.request.app['root'] / 'public/soft/index.html')
