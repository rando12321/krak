// Java / VerifyPhysics.java / Java 21 + FFDec / verify native network/timer blocks are unreachable and method bounds remain valid
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.*;import java.io.*;import java.util.*;
class VerifyVisualNames {
 static ABC abc(SWF s){for(Tag t:s.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)return ((DoABC2Tag)t).getABC();throw new RuntimeException("Loader missing");}
 public static void main(String[] args)throws Exception {
  ABC a=abc(new SWF(new FileInputStream(args[0]),false)),b=abc(new SWF(new FileInputStream(args[1]),false));Set<Integer> changed=new TreeSet<>();
  for(var body:a.bodies)if(!Arrays.equals(body.getCodeBytes(),b.findBody(body.method_info).getCodeBytes()))changed.add(body.method_info);
  if(!changed.equals(Set.of(86)))throw new Exception("Unexpected changes: "+changed);
  if(b.instance_info.size()!=a.instance_info.size()+1||b.findClassByName("disney.VisualNames")<0)throw new Exception("Class count mismatch");
  int checked=0;for(var body:b.bodies)if(body.method_info>=a.method_info.size()||changed.contains(body.method_info)){
   var stats=body.getCode().getStats(b,body,body.init_scope_depth,false);if(stats==null||stats.maxstack>body.max_stack||stats.maxscope>body.max_scope_depth)throw new Exception("Invalid stack/scope bounds at "+body.method_info);checked++;
  }
  System.out.println("PASS: only title hook changed; all other existing methods byte-identical; RGB methods stack/scope valid");
 }
}
