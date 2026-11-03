# Python / test_jump_symbols.py / Python 3.11 / native jump derivation and fail-closed regressions
import json,pathlib,sys,types,unittest
BASE=pathlib.Path(__file__).parent
pkg=types.ModuleType('jump_fixture');pkg.__path__=[str(BASE/'parser')];sys.modules['jump_fixture']=pkg
from jump_fixture.jump_symbols import extract_jump_symbols
class JumpTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.text=pathlib.Path('/workspace/work/speed-native-current/game.dump').read_text()
  cls.symbols=json.loads(pathlib.Path('/workspace/work/speed-native-current/base-keys.json').read_text())
  cls.field=extract_jump_symbols(cls.text.splitlines(),cls.symbols)['is_jumping']
 def test_current_native(self):self.assertEqual(self.field,''.join('\\'+d for d in '5125558656827'))
 def test_rotating_symbol(self):
  renamed='\\1\\2\\3\\4\\5\\6\\7'
  self.assertEqual(extract_jump_symbols(self.text.replace(self.field,renamed).splitlines(),self.symbols)['is_jumping'],renamed)
 def test_missing_method(self):
  with self.assertRaises(ValueError):extract_jump_symbols(self.text.splitlines(),dict(self.symbols,jump='missing'))
 def test_nonboolean_rejected(self):
  replaced=self.text.replace('::'+self.field+':<q>[public]::Boolean','::'+self.field+':<q>[public]::Number')
  self.assertNotEqual(replaced,self.text)
  with self.assertRaises(ValueError):extract_jump_symbols(replaced.splitlines(),self.symbols)
 def test_parser_integration(self):
  from jump_fixture.physics_symbols import extract_physics_symbols
  result=extract_physics_symbols(self.text.splitlines(),self.symbols)
  self.assertEqual(result['is_jumping'],self.field)
  self.assertIn('player_moving_left',result);self.assertIn('physics_state',result)
if __name__=='__main__':unittest.main()
