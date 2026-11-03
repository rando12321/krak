# Python / jump_symbols.py / Python 3.11 / derive remote jump state from native Boolean jump method
import collections
import re
from .bot_symbols import PROP

def extract_jump_symbols(lines, symbols):
    text = '\n'.join(lines)
    jump = symbols.get('jump')
    if not jump:
        raise ValueError('Native jump method missing')
    candidates = []
    for match in re.finditer(r'(?m)^[^\n]*\bclass '+PROP+r' extends [^\n]+\{.*?(?=\n[^\n]*\bclass <q>[^\n]* extends |\Z)', text, re.S):
        player = match.group()
        fields = dict(re.findall(r'(?m)^    slot \d+: var '+PROP+':'+PROP, player))
        for method in re.finditer(r'(?m)^    [^\n]*\bmethod [^\n]+.*?\n    \}', player, re.S):
            body = method.group()
            signature = '::'+jump+'=(<q>[public]::Boolean, <q>[public]::int = 0)(2 params, 1 optional)'
            if signature not in body:
                continue
            writes = collections.Counter(re.findall(r'(?:init|set)property '+PROP, body))
            # The animation/state latch is set on jump(true), cleared on jump(false).
            repeated = [name for name, count in writes.items() if count == 2 and fields.get(name) == 'Boolean']
            if len(repeated) != 1:
                raise ValueError('Jump state missing or ambiguous')
            field = repeated[0]
            if len(re.findall(r'getproperty <q>\[public\]::'+re.escape(field)+r'(?:\s|$)', body)) < 2:
                raise ValueError('Jump state does not have matching native guards')
            candidates.append(field)
    if len(candidates) != 1:
        raise ValueError('Native jump class missing or ambiguous')
    return {'is_jumping': candidates[0]}
