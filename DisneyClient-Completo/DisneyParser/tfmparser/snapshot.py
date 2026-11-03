# Python / snapshot.py / Python 3.11 / DisneyParser
import hashlib
import json
from pathlib import Path


def load_snapshot(snapshot_path, swf_path):
    data = json.loads(Path(snapshot_path).read_text(encoding="utf-8"))
    if data.get("schema") != 1:
        raise ValueError("Unsupported symbol snapshot schema")
    digest = hashlib.sha256(Path(swf_path).read_bytes()).hexdigest()
    if data.get("sha256") != digest:
        raise ValueError("SWF and symbol snapshot do not match")
    required = set(json.loads(Path(__file__).with_name("required_symbols.json").read_text()))
    symbols = data.get("symbols")
    if not isinstance(symbols, dict) or not required.issubset(symbols):
        raise ValueError("Symbol snapshot is incomplete")
    if any(not isinstance(value, str) or not value for value in symbols.values()):
        raise ValueError("Invalid symbol name")
    return symbols
