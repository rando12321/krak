# Python / legacy_symbols.py / Python 3.11 / derive native inventory notification types without fixed addresses
import re
PROP=r'<q>\[public\]::([^\s,:=<>]+)'
def extract_legacy_symbols(lines,symbols):
 text='\n'.join(lines)
 classes={m.group(1):m.group() for m in re.finditer(r'(?m)^[^\n]*\bclass '+PROP+r' extends [^\n]+\{.*?(?=\n[^\n]*\bclass <q>[^\n]* extends |\Z)',text,re.S)}
 icons=[];wrappers=[]
 for name,body in classes.items():
  factory=r'method '+re.escape('<q>[public]::'+name)+r' '+PROP+r'=\(<q>\[public\]::int, <q>\[public\]::int = -1, <q>\[public\]::Boolean = false, <q>\[public\]::Boolean = false\)'
  if re.search(factory,body):icons.append(name)
  if re.search(r'constructor .*?=\(<q>\[public\]flash.display::DisplayObject, <q>\[public\]::Function = null, <q>\[public\]::Object = null\)',body) and 'callpropvoid <q>[public]::addChild, 1 params' in body:wrappers.append(name)
 if len(icons)!=1 or len(wrappers)!=1:raise ValueError('Ambiguous inventory icon/notification types')
 return {'legacy_inventory_class':icons[0],'legacy_inventory_wrapper':wrappers[0]}
