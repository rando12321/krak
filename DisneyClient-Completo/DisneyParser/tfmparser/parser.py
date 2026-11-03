# Python / parser.py / Python 3.11 / automatically refresh the configured game SWF
from .bypasscode import BypassCode
from .chatcontainer import ChatContainer
from .chatclass import Chat
from .chatmessage import ChatMessage
from .checker import Checker
from .domainmanager import DomainManager
from .frameloop import FrameLoop
from .mapclass import Map
from .move import Move
from .player import Player
from .shaman import Shaman
from .socket import Socket
from .swf import Swf
from .timer import Timer
from .ui import UI


from .unpack_live import unpack_game
from pathlib import Path
import asyncio
import hashlib
import json
import os
import shutil
import tempfile
import time
import aiohttp

# Retain the source URL supplied in the original project; allow an explicit override.
tfm_swf_url = "http://transformice.com/Transformice.swf"
EXTRACTORS = (Chat, ChatContainer, ChatMessage, Checker, DomainManager,
              FrameLoop, Map, Move, Player, Shaman, Socket, Timer, UI, BypassCode)


async def collect_symbols(lines):
    results = await asyncio.gather(*(cls().fetch(lines) for cls in EXTRACTORS))
    symbols = {}
    for result in results:
        symbols.update(result)
    # Bot support is optional: preserve login and other controls on unsupported builds.
    from .bot_symbols import extract_bot_symbols
    try:
        symbols.update(extract_bot_symbols(lines, symbols))
    except (ValueError, KeyError, IndexError) as error:
        print('Autoplay symbols unavailable: '+str(error), flush=True)
    from .physics_symbols import extract_physics_symbols
    try:
        symbols.update(extract_physics_symbols(lines,symbols))
    except (ValueError, KeyError, IndexError) as error:
        print('Physics options unavailable: '+str(error),flush=True)
    from .legacy_symbols import extract_legacy_symbols
    try:
        symbols.update(extract_legacy_symbols(lines,symbols))
    except (ValueError, KeyError, IndexError) as error:
        print('Legacy inventory notifications unavailable: '+str(error),flush=True)
    required = set(json.loads(Path(__file__).with_name('required_symbols.json').read_text()))
    missing = required-symbols.keys()
    if missing:
        raise ValueError('Required symbols not found: '+', '.join(sorted(missing)))
    if any(not isinstance(v,str) or not v for v in symbols.values()):
        raise ValueError('Invalid extracted symbol')
    return {k:v.replace("\\", "").strip() for k,v in symbols.items()}


class Parser:
    def __init__(self,is_local=False):
        self.root=Path(__file__).resolve().parent.parent
        self.output_swf=str(self.root/'tfm.swf')
        self.is_local=is_local
        self.fetched={}
        self.ready=False
        self.last_error=None
        self._session=None
        self._hash=None
        self._next_check=0
        self._headers={}
        self.source_url=os.getenv('TFM_SWF_URL',tfm_swf_url)
        self.interval=max(8,float(os.getenv('TFM_REFRESH_SECONDS','60')))
        self.dumpscript=[]

    def dump_tool(self):
        custom=os.getenv('SWFDUMP_PATH')
        if custom:return custom
        for name in ('swfdump.exe','swfdump'):
            candidate=self.root/'tools'/name
            if candidate.is_file() and (os.name=='nt' or name=='swfdump'):
                return str(candidate)
        tool=shutil.which('swfdump')
        if not tool:raise RuntimeError('swfdump not found in DisneyParser/tools or PATH')
        return tool

    async def run_console(self,target):
        process=await asyncio.create_subprocess_exec(self.dump_tool(),'-a',str(target),
                   stdout=asyncio.subprocess.PIPE,stderr=asyncio.subprocess.PIPE)
        try:
            out,err=await asyncio.wait_for(process.communicate(),60)
        except BaseException:
            if process.returncode is None:process.kill()
            await process.wait()
            raise
        if process.returncode:
            raise RuntimeError('swfdump failed; the downloaded format may have changed')
        self.dumpscript=out.decode('utf-8',errors='replace').splitlines()
        return self.dumpscript

    async def process_download(self,data):
        digest=hashlib.sha256(data).hexdigest()
        if digest==self._hash and self.ready:
            return False
        game=await asyncio.to_thread(unpack_game,data)
        with tempfile.TemporaryDirectory(prefix='.update-',dir=self.root) as directory:
            staged=Path(directory)/'tfm.swf'
            staged.write_bytes(game)
            symbols=await collect_symbols(await self.run_console(staged))
            staged.replace(self.output_swf)
            self.fetched=symbols
            self._hash=digest
            self.ready=True
        print('SWF refreshed; extracted '+str(len(symbols))+' symbols',flush=True)
        return True

    async def start(self):
        if time.monotonic()<self._next_check:return
        self._next_check=time.monotonic()+self.interval
        downloaded=False
        try:
            if self._session is None:
                self._session=aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=60))
            async with self._session.get(self.source_url,headers=self._headers) as response:
                if response.status==304 and self.ready:return
                response.raise_for_status()
                data=await response.content.read(64*1024*1024+1)
                # StreamReader.read(n) may return before EOF; finish with bounded accumulation.
                while not response.content.at_eof() and len(data)<=64*1024*1024:
                    data+=await response.content.read(1024*1024)
                if len(data)>64*1024*1024:raise ValueError('SWF download too large')
                downloaded=True
                headers={}
                if response.headers.get('ETag'):headers['If-None-Match']=response.headers['ETag']
                if response.headers.get('Last-Modified'):headers['If-Modified-Since']=response.headers['Last-Modified']
            await self.process_download(data)
            self._headers=headers
            self.last_error=None
        except (aiohttp.ClientError, OSError, TimeoutError, ValueError, RuntimeError, IndexError, KeyError) as error:
            # A newly downloaded unsupported build invalidates old mappings.
            if downloaded:
                self.ready=False
                self.fetched={}
                self._headers={}
            message=type(error).__name__
            if isinstance(error,(ValueError,RuntimeError)):message+=': '+str(error)
            if self.last_error!=message:print('SWF refresh unavailable ('+message+')',flush=True)
            self.last_error=message

    async def close(self):
        if self._session is not None:
            await self._session.close()
            self._session=None
