"""Authenticated loopback endpoint; full ordered key states, never arbitrary input."""
from aiohttp import web
from .common import authorize
from native_keyboard import KeyboardError, UnsupportedKeyboard


class NativeKeyboard(web.View):
    async def post(self):
        if self.request.remote not in {'127.0.0.1', '::1'}:
            raise web.HTTPForbidden()
        row = await authorize(self.request)
        try:
            values = await self.request.json()
        except (ValueError, UnicodeError):
            raise web.HTTPBadRequest()
        if not isinstance(values, dict) or set(values) != {'session', 'seq', 'keys', 'pulse'}:
            raise web.HTTPBadRequest()
        try:
            result = self.request.app['native_keyboard'].update(row['user_id'], **values)
            return web.json_response(result)
        except UnsupportedKeyboard as error:
            return web.json_response({'success': False, 'supported': False, 'message': str(error)}, status=409)
        except KeyboardError as error:
            return web.json_response({'success': False, 'supported': True, 'message': str(error)}, status=409)
        except OSError:
            return web.json_response({'success': False, 'supported': True, 'message': 'Falha ao enviar as setas pelo Windows.'}, status=409)
        except (TypeError, ValueError):
            raise web.HTTPBadRequest()


async def release_keyboard(app):
    app['native_keyboard'].close()
