# Python / bot_symbols.py / Python 3.11 / derive route playback symbols from native game bytecode
import re
from collections import Counter

PROP = r'<q>\[public\]::([^\s,:=<>]+)'

def extract_bot_symbols(lines, symbols):
    text='\n'.join(lines)
    def blocks():
        for m in re.finditer(r'(?m)^[^\n]*\bclass '+PROP+r' extends [^\n]+\{.*?(?=\n[^\n]*\bclass <q>[^\n]* extends |\Z)', text, re.S):
            yield m.group(1),m.group()
    classes=dict(blocks())
    mc,mi=symbols['map_class_name'],symbols['map_instance']
    # A native encoded Number has exactly one public numeric instance slot.
    numeric={}
    for name,body in classes.items():
        slots=re.findall(r'(?m)^    slot 0: var '+PROP+r':<q>\[public\]::(\w+)',body)
        if len(slots)==1 and slots[0][1]=='Number':numeric[name]=slots[0][0]
    mapbody=classes[mc]
    fields=dict(re.findall(r'(?m)^    slot \d+: var '+PROP+r':'+PROP,mapbody))
    chain=re.compile(r'getlex '+re.escape('<q>[public]::'+mc)+r'\n[^\n]*getproperty '+re.escape('<q>[public]::'+mi)+r'\n[^\n]*getproperty '+PROP+r'\n[^\n]*getproperty '+PROP)
    pairs=Counter((a,b) for a,b in chain.findall(text) if numeric.get(fields.get(a))==b)
    if len(pairs)!=1:raise ValueError('Ambiguous native map number')
    (code_object,code_value),_=pairs.most_common(1)[0]
    # New-map packet shape includes code, count, round, compressed XML, author,
    # category and four flags. The first flag is the reverse-map flag.
    packets=[]
    for _,body in classes.items():
        for c in re.finditer(r'constructor .*?\n    \}',body,re.S):
            cons=c.group();reads=re.findall(r'callproperty <q>\[public\]::(read\w+)',cons)
            if reads[:9]==['readInt','readShort','readByte','readUTF','readByte','readBoolean','readBoolean','readBoolean','readBoolean']:
                flags=re.findall(r'callproperty <q>\[public\]::readBoolean, 0 params\n[^\n]*initproperty '+PROP,cons)
                if len(flags)==4:packets.append(flags[0])
    if len(set(packets))!=1:raise ValueError('Ambiguous native map mirror flag')
    reverse=packets[0]
    obj=symbols['obj_container']
    # Static width and height are copied from the native map's object container.
    copies=re.findall(r'getlex '+re.escape('<q>[public]::'+mc)+r'\n[^\n]*getlocal_0[^\n]*\n[^\n]*getproperty '+re.escape('<q>[public]::'+obj)+r'\n[^\n]*getproperty '+PROP+r'\n[^\n]*setproperty '+PROP,mapbody)
    same=[a for a,b in copies if a==b]
    if len(same)<2:raise ValueError('Native map dimensions unavailable')
    body_types=set(re.findall(r'var <q>\[public\]::'+re.escape(symbols['player_physics'])+':'+PROP,text))
    if len(body_types)!=1:raise ValueError('Ambiguous native player body')
    body=classes[body_types.pop()]
    setters=re.findall(r'method <q>\[public\]::Boolean '+PROP+r'=\(<q>\[public\]::'+re.escape(symbols['b2vec2'])+r', <q>\[public\]::Number\)\(2 params, 0 optional\)',body)
    if len(setters)!=1:raise ValueError('Native body position setter unavailable')
    return dict(bot_set_position=setters[0],bot_map_code_object=code_object,bot_map_code_value=code_value,bot_reverse=reverse,bot_map_width=same[0])
