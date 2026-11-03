import secrets
from aiohttp import web

async def index(request):
    response = web.FileResponse(request.app['root'] / 'public/index/index.html')
    if not request.cookies.get('browser_access_token'):
        response.set_cookie('browser_access_token', secrets.token_urlsafe(32), httponly=True, secure=request.secure, samesite='Lax', max_age=31536000)
    return response
