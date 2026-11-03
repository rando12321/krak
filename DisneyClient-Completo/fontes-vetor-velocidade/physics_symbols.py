# Python / physics_symbols.py / Python 3.11 / derive movement directions and native mass operations from the shipped game
import re
from .bot_symbols import PROP

def extract_physics_symbols(lines,symbols):
 text='\n'.join(lines)
 classes={m.group(1):m.group() for m in re.finditer(r'(?m)^[^\n]*\bclass '+PROP+r' extends [^\n]+\{.*?(?=\n[^\n]*\bclass <q>[^\n]* extends |\Z)',text,re.S)}
 body_types=set(re.findall(r'var <q>\[public\]::'+re.escape(symbols['player_physics'])+':'+PROP,text))
 if len(body_types)!=1:raise ValueError('Ambiguous physics body')
 body=classes[body_types.pop()]
 walk_class=classes[symbols['anim_class_name']]
 walk=next((m.group() for m in re.finditer(r'(?m)^    .*?method .*?\n    \}',walk_class,re.S) if '::'+symbols['update_coord']+'=' in m.group()),None)
 if not walk:raise ValueError('Native walk method missing')
 rows=[]
 for line in walk.splitlines():
  m=re.search(r'^\s*(\d+)\) \+ \d+:\d+ (.*)',line)
  if m:rows.append((int(m.group(1)),m.group(2).strip()))
 positions={n:i for i,(n,_) in enumerate(rows)};directions={}
 for i,(n,op) in enumerate(rows):
  if not op.startswith('iffalse ->') or i<2:continue
  prop=re.fullmatch('getproperty '+PROP,rows[i-1][1])
  if not prop or rows[i-2][1]!='getlocal_1':continue
  end=positions.get(int(op.split('->')[1]));block='\n'.join(v for _,v in rows[i+1:end]) if end else ''
  if 'setproperty <q>[public]::'+symbols['physics_state_vx'] not in block:continue
  role='player_moving_left' if re.search(r'(?m)^negate$',block) else 'player_moving_right'
  if role in directions:raise ValueError('Ambiguous movement direction')
  directions[role]=prop.group(1)
 if len(directions)!=2:raise ValueError('Both movement directions required')
 # Optional getter names can rotate or have several aliases. The typed velocity
 # field is stable enough to validate independently and must not discard directions.
 body_fields=dict(re.findall(r'(?m)^    slot \d+: var '+PROP+':'+PROP,body))
 # Derive the body local from the native walk routine, then the vector whose
 # horizontal component is read there. Do not trust the older broad Move match.
 def register(op,kind):
  m=re.fullmatch(kind+r'local(?:_([0-3])| r(\d+))',op)
  return int(m.group(1) if m.group(1) is not None else m.group(2)) if m else None
 body_locals=set()
 for i,(_,op) in enumerate(rows):
  if i<2 or i+2>=len(rows):continue
  if op=='getproperty <q>[public]::'+symbols['player_physics'] and register(rows[i-1][1],'get')==1:
   for _,following in rows[i+1:i+3]:
    local=register(following,'set')
    if local is not None:body_locals.add(local)
 velocity_fields=set()
 for i,(_,op) in enumerate(rows):
  if i+2>=len(rows) or register(op,'get') not in body_locals:continue
  field=re.fullmatch('getproperty '+PROP,rows[i+1][1])
  if field and body_fields.get(field.group(1))==symbols['b2vec2'] and rows[i+2][1]=='getproperty <q>[public]::'+symbols['physics_state_vx']:
   velocity_fields.add(field.group(1))
 if len(velocity_fields)!=1:raise ValueError('Native walk velocity field missing or ambiguous')
 velocity_field=velocity_fields.pop()
 getter=[]
 for method in re.finditer(r'(?m)^    [^\n]*\bmethod [^\n]+.*?\n    \}',body,re.S):
  name=re.search(r'method <q>\[public\]::'+re.escape(symbols['b2vec2'])+' '+PROP+r'=\(\)\(0 params, 0 optional\)',method.group())
  if not name:continue
  ops=[m.group(1).strip() for line in method.group().splitlines() if (m:=re.search(r'\) \+ \d+:\d+ (.*)',line))]
  ops=[op for op in ops if not op.startswith(('debug','nop'))]
  if ops==['getlocal_0','pushscope','getlocal_0','getproperty <q>[public]::'+velocity_field,'returnvalue']:
   getter.append(name.group(1))
 # Direction flags must be Boolean fields on the same player accepted by the native walk routine.
 player_type=re.search('::'+re.escape(symbols['update_coord'])+r'=\('+PROP,walk).group(1)
 fields=dict(re.findall(r'(?m)^    slot 0: var '+PROP+':'+PROP,classes[player_type]))
 if any(fields.get(v)!='Boolean' for v in directions.values()):raise ValueError('Direction fields are not player booleans')
 from .weight_symbols import extract_weight_symbols
 result=dict(directions,physics_state=velocity_field)
 if len(set(getter))==1:result['get_linear_velocity']=getter[0]
 try:result.update(extract_weight_symbols(lines,dict(symbols,physics_state=velocity_field)))
 except (ValueError, KeyError, IndexError) as error:
  print('Mass symbols unavailable: '+str(error),flush=True)
 return result
