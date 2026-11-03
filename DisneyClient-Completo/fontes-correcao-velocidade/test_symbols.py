# Python / test_symbols.py / Python 3.11 / repair the supplied game's missing movement fields and validate native contracts
import asyncio,sys,json,unittest
from pathlib import Path
sys.path.insert(0,'/workspace/work/speed-fix/parser-test')
from tfmparser.physics_symbols import extract_physics_symbols
from tfmparser.parser import collect_symbols
class Tests(unittest.TestCase):
 def test_uploaded_and_two_reference_builds(self):
  for name in ['user-game','new-158','original-game']:
   with self.subTest(name=name):
    if name=='user-game':
     path=Path('/workspace/work/disney-user-fix/user-game.dump');norm=json.loads(Path('/workspace/work/disney-user-fix/user-keys.json').read_text());raw={k:''.join('\\'+x for x in v) if v.isdigit() else v for k,v in norm.items()}
     self.assertNotIn('player_moving_right',raw);self.assertNotIn('player_moving_left',raw)
    else:
     path=Path('/workspace/work/disney-fix/'+name+'.dump');raw=json.loads(Path('/workspace/work/disney-fix/'+name+'.dump.keys.json').read_text())
    result=extract_physics_symbols(path.read_text().splitlines(),raw)
    self.assertEqual(len(result),12);self.assertNotEqual(result['player_moving_left'],result['player_moving_right'])
 def test_invalid_build_does_not_guess(self):
  with self.assertRaises((ValueError,KeyError)):extract_physics_symbols([],{'player_physics':'unknown'})
class RegressionTests(unittest.TestCase):
 def setup_native(self):
  import re
  from tfmparser.bot_symbols import PROP
  text=Path('/workspace/work/disney-user-fix/user-game.dump').read_text();norm=json.loads(Path('/workspace/work/disney-user-fix/user-keys.json').read_text());raw={k:''.join('\\'+x for x in v) if v.isdigit() else v for k,v in norm.items()}
  result=extract_physics_symbols(text.splitlines(),raw);getter=result['get_linear_velocity']
  method=next(m.group() for m in re.finditer(r'(?m)^    [^\n]*\bmethod [^\n]+.*?\n    \}',text,re.S) if '::'+getter+'=' in m.group())
  return text,raw,method,getter
 def test_missing_getter_preserves_speed_symbols(self):
  text,raw,method,getter=self.setup_native();result=extract_physics_symbols(text.replace(method,'').splitlines(),raw)
  self.assertNotIn('get_linear_velocity',result);self.assertIn('player_moving_left',result);self.assertIn('mass_set',result)
 def test_ambiguous_getter_uses_typed_vector(self):
  text,raw,method,getter=self.setup_native();alias=method.replace('::'+getter+'=','::aliasVelocity=');result=extract_physics_symbols(text.replace(method,method+'\n'+alias).splitlines(),raw)
  self.assertNotIn('get_linear_velocity',result);self.assertIn('player_moving_right',result)
 def test_final_getter_with_debug_is_accepted(self):
  text,raw,method,getter=self.setup_native();changed=method.replace('     method','    final  method',1).replace('        00000)', '        99999) + 0:0 debugline 1\n        00000)',1)
  result=extract_physics_symbols(text.replace(method,changed).splitlines(),raw);self.assertEqual(result['get_linear_velocity'],getter)
 def test_mass_extraction_failure_preserves_speed(self):
  from unittest.mock import patch
  text,raw,method,getter=self.setup_native()
  with patch('tfmparser.weight_symbols.extract_weight_symbols',side_effect=ValueError('unsupported mass')):result=extract_physics_symbols(text.splitlines(),raw)
  self.assertIn('player_moving_right',result);self.assertNotIn('mass_set',result)
if __name__=='__main__':unittest.main()
