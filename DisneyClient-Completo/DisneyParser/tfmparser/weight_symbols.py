# Python / weight_symbols.py / Python 3.11 / derive native mass data and setter roles from the player body
import re
from .bot_symbols import PROP

def extract_weight_symbols(lines,symbols):
 text='\n'.join(lines)
 classes={m.group(1):m.group() for m in re.finditer(r'(?m)^[^\n]*\bclass '+PROP+r' extends [^\n]+\{.*?(?=\n[^\n]*\bclass <q>[^\n]* extends |\Z)',text,re.S)}
 body_types=set(re.findall(r'var <q>\[public\]::'+re.escape(symbols['player_physics'])+':'+PROP,text))
 if len(body_types)!=1:raise ValueError('Ambiguous mass body')
 body=classes[body_types.pop()];candidates=[]
 for method in re.finditer(r'(?m)^     method <q>\[public\]::void '+PROP+r'=\('+PROP+r'\)\(1 params, 0 optional\).*?\n    \}',body,re.S):
  name,data_type=method.group(1),method.group(2)
  if data_type not in classes:continue
  fields=dict(re.findall(r'(?m)^    slot 0: var '+PROP+':'+PROP,classes[data_type]))
  numbers={n for n,t in fields.items() if t=='Number'};vectors={n for n,t in fields.items() if t==symbols['b2vec2']}
  if len(fields)!=3 or len(numbers)!=2 or len(vectors)!=1:continue
  code=method.group();pairs=re.findall(r'getlocal_1[^\n]*\n[^\n]*getproperty '+PROP+r'\n[^\n]*(?:initproperty|setproperty) '+PROP,code)
  pairs=[p for p in pairs if p[0] in numbers]
  if len(pairs)!=2:continue
  center=vectors.pop()
  chain=re.findall(r'getlocal_0[^\n]*\n[^\n]*getproperty '+PROP+r'\n[^\n]*getproperty '+PROP+r'\n[^\n]*getlocal_1[^\n]*\n[^\n]*getproperty '+re.escape('<q>[public]::'+center)+r'\n[^\n]*callpropvoid',code)
  if len(chain)!=1:continue
  candidates.append(dict(mass_data_class_name=data_type,mass_set=name,mass_body_mass=pairs[0][1],mass_body_inertia=pairs[1][1],mass_data_mass=pairs[0][0],mass_data_inertia=pairs[1][0],mass_data_center=center,mass_body_sweep=chain[0][0],mass_sweep_center=chain[0][1]))
 if len(candidates)!=1:raise ValueError('Native mass setter unavailable or ambiguous')
 return candidates[0]
