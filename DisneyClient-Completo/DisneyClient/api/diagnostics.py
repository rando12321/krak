# Python / diagnostics.py / Python 3.11 / authenticated local Flash diagnostics, without packet or token contents
from aiohttp import web
from datetime import datetime,timezone
from pathlib import Path
import json
import time
from .common import authorize

EVENTS={'guard_ready','frame_error','socket_close','io_error','security_error','physics','teleport'}
OPTIONS={'teleport','auto_play','recording','change_jump_delay','change_jump_height','change_jump_speed','change_movement_speed','mass_reduction','insta_death','insta_win','no_delay','no_bulle','soft_mode','macro'}

class Diagnostics(web.View):
    async def post(self):
        if self.request.remote not in {'127.0.0.1','::1'}:
            raise web.HTTPForbidden()
        row=await authorize(self.request)
        values=await self.request.post()
        event=values.get('event','');channel=values.get('channel','')
        if event not in EVENTS or channel not in {'main','bulle','client'}:raise web.HTTPBadRequest()
        try:
            code=int(values.get('code',0));elapsed=int(values.get('elapsed',0))
        except (TypeError,ValueError):raise web.HTTPBadRequest()
        if not -65535<=code<=65535 or not -2147483648<=elapsed<=2147483647:raise web.HTTPBadRequest()
        option_text=values.get('options','')
        if not isinstance(option_text,str) or len(option_text)>512:raise web.HTTPBadRequest()
        options=option_text.split(',') if option_text else []
        if any(name not in OPTIONS for name in options):raise web.HTTPBadRequest()
        extra={}
        if event=='physics':
            feature=values.get('feature');reason=values.get('reason')
            if feature not in {'mass','speed','round'} or reason not in {'fault','restore_pending','restored','enabled','off','paused_cheese','paused_dead','left_with_cheese','left_without_cheese','old_body_removed','native_mass_changed','paused_input'}:raise web.HTTPBadRequest()
            extra={'feature':feature,'reason':reason}
            if feature=='speed' and 'guard_build' in values:
                if values['guard_build']!='sdds-speed-edit-v2' or values.get('input_valid') not in {'0','1'}:raise web.HTTPBadRequest()
                extra.update(guard_build=values['guard_build'],input_valid=values['input_valid']=='1')
                if 'speed_value' in values:
                    try:speed=float(values['speed_value'])
                    except (TypeError,ValueError):raise web.HTTPBadRequest()
                    if not 0<speed<=9.9:raise web.HTTPBadRequest()
                    extra['speed_value']=speed
        if event=='teleport':
            reason=values.get('reason');build=values.get('build')
            if channel!='client' or reason not in {'ready','enabled','disabled','focus_field','waiting_player','requested','returned','after_200ms','error'} or build not in {'sdds-legacy-teleport-diag-v4','sdds-legacy-teleport-codec-v5'}:
                raise web.HTTPBadRequest()
            try:
                press=int(values.get('press',0))
            except (ValueError,TypeError):raise web.HTTPBadRequest()
            if not 0<=press<=1000000000:raise web.HTTPBadRequest()
            extra={'reason':reason,'build':build,'press':press}
            for name in ('x','y','target_x','target_y'):
                if name in values:
                    try:value=int(values[name])
                    except (ValueError,TypeError):raise web.HTTPBadRequest()
                    if not -10000000<=value<=10000000:raise web.HTTPBadRequest()
                    extra[name]=value
            if 'alive' in values:
                if values['alive'] not in {'0','1'}:raise web.HTTPBadRequest()
                extra['alive']=values['alive']=='1'
        now=time.monotonic();key=(row['user_id'],'teleport') if event=='teleport' else row['user_id'];rates=self.request.app['diagnostics_rate']
        start,count=rates.get(key,(now,0))
        if now-start>=60:start,count=now,0
        if count>=(120 if event=='teleport' else 30):raise web.HTTPTooManyRequests()
        rates[key]=(start,count+1)
        record={'time':datetime.now(timezone.utc).isoformat(),'event':event,'code':code,'channel':channel,'elapsed_ms':elapsed,'active_options':options}
        record.update(extra)
        folder=Path(self.request.app['root']).parent/'logs-client';folder.mkdir(exist_ok=True)
        target=folder/'flash-diagnostics.jsonl'
        if target.exists() and target.stat().st_size>5*1024*1024:
            target.replace(folder/'flash-diagnostics.previous.jsonl')
        with target.open('a',encoding='utf-8') as handle:handle.write(json.dumps(record,ensure_ascii=True)+'\n')
        return web.json_response({'saved':True})
