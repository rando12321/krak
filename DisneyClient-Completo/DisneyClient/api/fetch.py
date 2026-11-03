from aiohttp import web
from .common import authorize

class Fetch(web.View):
    async def get(self):
        row = await authorize(self.request, allow_cookie=True)
        data = await self.request.app['db'].get_data(row['user_id'])
        # Session cookies authorize the dashboard without recovering raw tokens.
        return web.json_response({'success': True, 'user': {'key': '[hidden]', 'username': row['username'], 'premium_level': row['level'], 'maps_allowed': bool(data.get('map_data'))}})
