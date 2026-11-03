from aiohttp import web
from api.common import authorize

async def dashboard(request):
    await authorize(request, allow_cookie=True)
    return web.FileResponse(request.app['root'] / 'public/dashboard/index.html')
