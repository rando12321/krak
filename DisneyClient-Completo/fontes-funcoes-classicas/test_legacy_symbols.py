# Python / test_legacy_symbols.py / Python 3 / reject missing and ambiguous notification mappings
import unittest
from pathlib import Path
from legacy_symbols import extract_legacy_symbols
class Tests(unittest.TestCase):
 def test_actual_native_game(self):
  found=extract_legacy_symbols(Path('/workspace/work/disney-user-fix/user-game.dump').read_text().splitlines(),{})
  self.assertEqual(set(found),{'legacy_inventory_class','legacy_inventory_wrapper'})
  self.assertTrue(all(found.values()))
 def test_missing_rejected(self):
  with self.assertRaises(ValueError):extract_legacy_symbols([], {})
 def test_ambiguous_rejected(self):
  text=Path('/workspace/work/disney-user-fix/user-game.dump').read_text()
  found=extract_legacy_symbols(text.splitlines(),{})
  fake=' class <q>[public]::secondInventoryType extends <q>[public]::Object{\n method <q>[public]::secondInventoryType <q>[public]::factory=(<q>[public]::int, <q>[public]::int = -1, <q>[public]::Boolean = false, <q>[public]::Boolean = false)\n}'
  with self.assertRaises(ValueError):extract_legacy_symbols((text+'\n'+fake).splitlines(),{})
if __name__=='__main__':unittest.main()
