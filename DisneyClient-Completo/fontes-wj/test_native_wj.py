# Python / test_native_wj.py / Python 3.11 / verify exact signature selection, byte restoration, ownership and failure handling
import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from native_wj import NativeWj,PatchError,AOB,ORIGINAL,PATCHED
PATTERN=bytes(0x11 if s=='??' else int(s,16) for s in AOB.split())
class FakeProcess:
 def __init__(self,size=4096):self.memory=bytearray(size);self.identity=('flash',1);self.writes=[];self.pid=1;self.short=False
 def __enter__(self):return self
 def __exit__(self,*args):pass
 def executable_regions(self):yield 0x1000,len(self.memory)
 def read(self,address,length):
  if self.short:return b''
  return bytes(self.memory[address-0x1000:address-0x1000+length])
 def write(self,address,data):self.writes.append((address,data));self.memory[address-0x1000:address-0x1000+len(data)]=data
 def put(self,offset):self.memory[offset:offset+len(PATTERN)]=PATTERN
class NativeTests(unittest.TestCase):
 def setup_manager(self,p):return NativeWj(finder=lambda:1,opener=lambda pid:p)
 def test_unique_apply_off_restore_one_byte(self):
  p=FakeProcess();p.put(100);m=self.setup_manager(p)
  self.assertTrue(m.set_enabled(True,'me')['enabled']);self.assertEqual(p.read(0x1064,4),PATCHED);self.assertEqual(p.writes,[(0x1067,b'\x45')])
  self.assertTrue(m.set_enabled(True,'me')['enabled']);self.assertEqual(len(p.writes),1)
  self.assertFalse(m.set_enabled(False,'me')['enabled']);self.assertEqual(p.read(0x1064,4),ORIGINAL);self.assertEqual(p.writes[-1],(0x1067,b'\x40'))
 def test_missing_pattern_no_writes(self):
  p=FakeProcess();m=self.setup_manager(p)
  with self.assertRaisesRegex(PatchError,'nao encontrado'):m.set_enabled(True,'me')
  self.assertFalse(p.writes)
 def test_duplicate_pattern_no_writes(self):
  p=FakeProcess();p.put(50);p.put(500)
  with self.assertRaisesRegex(PatchError,'ambiguo'):self.setup_manager(p).set_enabled(True,'me')
  self.assertFalse(p.writes)
 def test_chunk_boundary_and_dedup(self):
  p=FakeProcess(2*1024*1024);offset=1024*1024-20;p.put(offset);m=self.setup_manager(p)
  self.assertTrue(m.set_enabled(True,'me')['enabled']);self.assertEqual(p.writes,[(0x1000+offset+3,b'\x45')])
 def test_changed_bytes_not_clobbered(self):
  p=FakeProcess();p.put(100);m=self.setup_manager(p);m.set_enabled(True,'me');p.memory[103]=0x99
  with self.assertRaisesRegex(PatchError,'codigo mudou'):m.set_enabled(False,'me')
  self.assertEqual(len(p.writes),1);self.assertEqual(p.memory[103],0x99)
 def test_other_session_cannot_disable(self):
  p=FakeProcess();p.put(100);m=self.setup_manager(p);m.set_enabled(True,'me')
  with self.assertRaisesRegex(PatchError,'outra sessao'):m.set_enabled(False,'other')
  self.assertEqual(len(p.writes),1)
 def test_pid_reuse_does_not_touch_new_instance(self):
  p=FakeProcess();p.put(100);m=self.setup_manager(p);m.set_enabled(True,'me');p.identity=('flash',2)
  self.assertFalse(m.set_enabled(False,'me')['enabled']);self.assertEqual(len(p.writes),1)
 def test_incomplete_scan_no_writes(self):
  p=FakeProcess();p.put(100);p.short=True
  with self.assertRaisesRegex(PatchError,'incompleta'):self.setup_manager(p).set_enabled(True,'me')
  self.assertFalse(p.writes)
 def test_cleanup_restores(self):
  p=FakeProcess();p.put(100);m=self.setup_manager(p);m.set_enabled(True,'me');m.close();self.assertEqual(p.read(0x1064,4),ORIGINAL)
if __name__=='__main__':unittest.main()
