"""Run with Python 3.11+: python server.py (from any working directory)."""
import asyncio
import contextlib
import binascii
import zlib
import json
import logging
import os
from pathlib import Path
import aiohttp
from aiohttp import web
import infrastructure
from database import Database

log = logging.getLogger(__name__)


@web.middleware
async def errors(request, handler):
    try:
        response = await handler(request)
    except web.HTTPException as exc:
        response = web.json_response({'success': False, 'error': exc.reason}, status=exc.status)
    except (ValueError, UnicodeError, binascii.Error, zlib.error):
        response = web.json_response({'success': False, 'error': 'invalid request data'}, status=400)
    if request.path.startswith(('/api/', '/auth', '/get_keys')):
        response.headers['Cache-Control'] = 'no-store'
    return response


async def swf_downloader(app):
    path = app['root'] / 'tfm.swf'
    temporary = path.with_suffix('.swf.tmp')
    while True:
        try:
            async with infrastructure.get_session().get(app['parser_url'] + '/transformice?swf', headers={'Authorization': 'Bearer ' + app['parser_token']}) as response:
                response.raise_for_status()
                content = await response.read()
                if len(content) < 8 or content[:3] not in (b'FWS', b'CWS', b'ZWS'):
                    raise ValueError('Invalid SWF response')
                temporary.write_bytes(content)
                temporary.replace(path)
        except (aiohttp.ClientError, TimeoutError, ValueError, OSError) as exc:
            # Do not log URLs or upstream response bodies, which may contain credentials.
            log.warning('SWF refresh failed (%s)', type(exc).__name__)
        await asyncio.sleep(30)


async def lifecycle(app):
    task = None
    try:
        await app['db'].open()
        await app['db'].migrate()
        await infrastructure.init_session()
        if app['parser_url']:
            task = asyncio.create_task(swf_downloader(app))
        yield
    finally:
        if task:
            task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await task
        await infrastructure.close_session()
        await app['db'].close()


def create_app():
    import api
    from api.diagnostics import Diagnostics
    from api.native_patch import NativePatch, restore_native
    from native_wj import NativeWj
    import resources
    root = infrastructure.ROOT
    config = json.loads((root / 'config.json').read_text())
    infrastructure.config = config
    app = web.Application(middlewares=[errors], client_max_size=10 * 1024 * 1024)
    app.update(root=root, build_id=(root / 'BUILD-ID.txt').read_text().strip(), config=config, db=Database(), attempts={},
               parser_url=os.getenv('TFM_PARSER_ENDPOINT', '').rstrip('/'),
               parser_token=os.getenv('TFM_PARSER_API_TOKEN', ''))
    app["diagnostics_rate"] = {}
    app["native_wj"] = NativeWj()
    app["native_lock"] = asyncio.Lock()
    app["native_rates"] = {}
    app.on_cleanup.append(restore_native)
    app.router.add_view('/native_patch', NativePatch)
    app.cleanup_ctx.append(lifecycle)
    app.router.add_view('/client_diagnostics', Diagnostics)
    app.router.add_get('/', resources.index)
    app.router.add_get('/dashboard', resources.dashboard)
    for path, view in [('/auth',api.Auth),('/api/auth',api.Auth),('/get_keys',api.GetKeys),('/tfmlogin',api.TfmLogin),('/transformice',api.Transformice),('/data',api.Data),('/data/soft',api.Soft),('/mapstorage',api.MapStorage),('/api/fetch',api.Fetch),('/api/update',api.Update)]:
        app.router.add_view(path,view)
    # Compatibility metadata route; no Discord API, bot or token is used.
    async def discord_metadata(request):
        return web.json_response({'names': []})
    app.router.add_get('/api/discord', discord_metadata)
    async def health(request):
        async with request.app['db'].transaction() as cur:
            await cur.execute('SELECT 1')
        return web.json_response({'status': 'ok', 'database': 'ok', 'build_id': request.app['build_id']})
    app.router.add_get('/health',health)
    app.router.add_static('/images',root / 'images')
    app.router.add_static('/public',root / 'public')
    return app


def main():
    logging.basicConfig(level=logging.INFO)
    # run_app owns one loop, startup hooks and graceful SIGINT/SIGTERM cleanup.
    web.run_app(create_app(), host=os.getenv('SERVER_HOST','0.0.0.0'),
                port=int(os.getenv('SERVER_PORT',os.getenv('PORT','8080'))),
                access_log=None)


if __name__ == '__main__':
    main()
