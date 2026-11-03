"""Runtime resources: importing this module never opens a connection."""
import asyncio
import os
from pathlib import Path
from aiohttp import ClientSession, ClientTimeout
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / '.env')
session = None
config = {}
records_data = None

async def init_session():
    global session
    if session is None or session.closed:
        session = ClientSession(timeout=ClientTimeout(total=30))
    return session

async def close_session():
    global session
    if session is not None:
        await session.close()
    session = None

def get_session():
    if session is None or session.closed:
        raise RuntimeError('HTTP session not initialized')
    return session
