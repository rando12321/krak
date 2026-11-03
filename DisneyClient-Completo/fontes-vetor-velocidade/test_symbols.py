# Python / test_symbols.py / Python 3.11 / repair the supplied game's missing movement fields and validate native contracts
import asyncio,sys,json,unittest
from pathlib import Path
sys.path.insert(0,'/workspace/work/speed-native-current/parser-test')
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
    self.assertEqual(len(result),13);self.assertNotEqual(result['player_moving_left'],result['player_moving_right'])
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
class CurrentNativeTests(unittest.TestCase):
 def current(self):
  root=Path('/workspace/work/speed-native-current');return (root/'game.dump').read_text(),json.loads((root/'base-keys.json').read_text())
 def test_exact_uploaded_build_repairs_wrong_field(self):
  text,raw=self.current();result=extract_physics_symbols(text.splitlines(),raw)
  self.assertNotEqual(result['physics_state'],raw['physics_state']);self.assertEqual(result['physics_state'],''.join('\\'+x for x in '5117488824354'));self.assertIn('get_linear_velocity',result)
 def test_typed_but_wrong_vector_is_not_trusted(self):
  text,raw=self.current();raw['physics_state']=''.join('\\'+x for x in '3871582547884');result=extract_physics_symbols(text.splitlines(),raw)
  self.assertEqual(result['physics_state'],''.join('\\'+x for x in '5117488824354'))
 def test_ambiguous_walk_rejected(self):
  text,raw=self.current();walk=Path('/workspace/work/speed-native-current/walk.dump').read_text();other=''.join('\\'+x for x in '3871582547884')
  altered=walk.replace('        00000)', '        99990) + 0:1 getlocal_3\n        99991) + 1:1 getproperty <q>[public]::'+other+'\n        99992) + 1:1 getproperty <q>[public]::'+raw['physics_state_vx']+'\n        00000)',1)
  with self.assertRaisesRegex(ValueError,'velocity field missing or ambiguous'):extract_physics_symbols(text.replace(walk,altered).splitlines(),raw)
 def test_current_build_integrates_all_symbols(self):
  text,raw=self.current();keys=asyncio.run(collect_symbols(text.splitlines()));self.assertEqual(len(keys),137);self.assertEqual(keys['physics_state'],'5117488824354');self.assertIn('player_moving_left',keys);self.assertIn('mass_set',keys)
if __name__=='__main__':unittest.main()

