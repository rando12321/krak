// Java / VerifyAutoplay.java / Java 21 + FFDec / verify native network/timer blocks are unreachable and method bounds remain valid
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.*;import java.io.*;import java.util.*;
class VerifyAutoplay {
 static ABC abc(SWF s){for(Tag t:s.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)return ((DoABC2Tag)t).getABC();throw new RuntimeException("Loader missing");}
 public static void main(String[] args)throws Exception {
  ABC a=abc(new SWF(new FileInputStream(args[0]),false)),b=abc(new SWF(new FileInputStream(args[1]),false));Set<Integer> changed=new TreeSet<>();
  for(var body:a.bodies)if(!Arrays.equals(body.getCodeBytes(),b.findBody(body.method_info).getCodeBytes()))changed.add(body.method_info);
  if(!changed.equals(Set.of(86)))throw new Exception("Unexpected changes: "+changed);
  if(b.instance_info.size()!=a.instance_info.size()+1||b.findClassByName("disney.RoutePlayer")<0)throw new Exception("Class count mismatch");
  int checked=0;for(var body:b.bodies)if(body.method_info>=a.method_info.size()||changed.contains(body.method_info)){
   var stats=body.getCode().getStats(b,body,body.init_scope_depth,false);if(stats==null||stats.maxstack>body.max_stack||stats.maxscope>body.max_scope_depth)throw new Exception("Invalid stack/scope bounds at "+body.method_info);checked++;
  }
  AVM2Code c=b.findBody(87).getCode();Map<Long,Integer> positions=new HashMap<>();for(int i=0;i<c.code.size();i++)positions.put(c.code.get(i).getAddress(),i);
  Set<Integer> reached=new HashSet<>();Deque<Integer> queue=new ArrayDeque<>();queue.add(0);Set<String> forbidden=Set.of("socket_class","check_timer","check_timestamp","check_pos","check_id","new_check");
  while(!queue.isEmpty()){
   int i=queue.remove();if(i<0||i>=c.code.size()||!reached.add(i))continue;var ins=c.code.get(i);int op=ins.definition.instructionCode;
   if(op==0x66||op==0x61){String name=b.constants.getString(b.constants.getMultiname(ins.operands[0]).name_index);if(name!=null&&forbidden.contains(name))throw new Exception("Obsolete interceptor remains reachable: "+name);}
   if(op==0x47||op==0x48||op==3)continue;
   if(op>=0x0c&&op<=0x1a){long address=ins.getAddress()+ins.getBytesLength()+ins.operands[0];Integer target=positions.get(address);if(target==null)throw new Exception("Invalid branch target");queue.add(target);if(op!=0x10)queue.add(i+1);}
   else if(op==0x1b){queue.add(positions.get(ins.getAddress()+ins.operands[0]));for(int k=2;k<ins.operands.length;k++)queue.add(positions.get(ins.getAddress()+ins.operands[k]));}
   else queue.add(i+1);
  }
  System.out.println("PASS: only original method 86 changed; loop and ConnectionGuard unchanged; "+checked+" new/hooked method bodies bounded; obsolete socket/timer blocks unreachable across "+reached.size()+" reachable instructions");
 }
}
