from aiohttp import web


def address(request):
    # Forwarded headers are untrusted. Deploy behind a proxy only with explicit
    # trusted-proxy support, not by trusting arbitrary X-Forwarded-For headers.
    return request.remote or '127.0.0.1'


async def authorize(request, *, allow_cookie=False):
    cookie = request.cookies.get('session') if allow_cookie else None
    token = cookie or request.query.get('access_token')
    if not token:
        raise web.HTTPUnauthorized()
    row = await request.app['db'].session(token, address(request), cookie=bool(cookie), flash=request.query.get('flash_token'))
    if row is None:
        raise web.HTTPUnauthorized()
    return row
