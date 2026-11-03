import base64
import binascii
import time
import secrets
from aiohttp import web
from database import AuthError
from .common import address

class Auth(web.View):
    async def get(self):
        config = self.request.app['config']
        version = self.request.query.get('version')
        if version and version != config['version']:
            return web.json_response({'success': False, 'error': 'outdated version', 'update_url': config.get('update_url')}, status=406)
        ip = address(self.request)
        now = time.monotonic()
        attempts = self.request.app['attempts']
        # Bound memory and enforce the block before touching the database.
        for old in [k for k, (_, until) in attempts.items() if until <= now]:
            del attempts[old]
        count, until = attempts.get(ip, (0, now + 240))
        if count >= 8:
            return web.json_response({'success': False, 'error': 'temporarily blocked due to many login attempts'}, status=429)
        auth = self.request.headers.get('Authorization', '').split()
        try:
            if len(auth) != 2 or auth[0].lower() not in {'basic','bearer'}:
                raise ValueError()
            key = base64.b64decode(auth[1], validate=True).decode() if auth[0].lower() == 'basic' else auth[1]
            if not 1 <= len(key) <= 256:
                raise ValueError()
        except (ValueError, UnicodeError, binascii.Error):
            attempts[ip] = (count + 1, until)
            return web.json_response({'success': False, 'error': 'bad authorization'}, status=400)
        # Browser cookie is a device identifier, not a substitute for a key.
        # Desktop clients should persist X-Device-ID across launches.
        device = self.request.headers.get('X-Device-ID') or self.request.cookies.get('browser_access_token')
        new_device = not device
        if not device:
            device = secrets.token_urlsafe(32)
        if len(device) > 256:
            raise web.HTTPBadRequest()
        try:
            cookie, access, level = await self.request.app['db'].authenticate(key, device, ip)
        except AuthError as exc:
            attempts[ip] = (count + 1, until)
            return web.json_response({'success': False, 'error': str(exc)}, status=401)
        attempts.pop(ip, None)
        response = web.json_response({'success': True, 'access_token': access, 'level': level, 'sleep': 0})
        response.set_cookie('session', cookie, httponly=True, secure=self.request.secure, samesite='Lax', max_age=10800)
        if new_device:
            response.set_cookie('browser_access_token', device, httponly=True, secure=self.request.secure, samesite='Lax', max_age=31536000)
        response.headers['Cache-Control'] = 'no-store'
        return response
