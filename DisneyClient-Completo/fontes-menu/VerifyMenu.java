// Java / VerifyMenu.java / Java 21 + FFDec / bound-check new bytecode and preserve original methods
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import java.io.*;import java.util.*;
class VerifyMenu {
 static ABC abc(SWF s){for(Tag t:s.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)return ((DoABC2Tag)t).getABC();throw new RuntimeException("No loader ABC");}
 public static void main(String[] args)throws Exception{
  ABC a=abc(new SWF(new FileInputStream(args[0]),false)),b=abc(new SWF(new FileInputStream(args[1]),false));Set<Integer> changed=new TreeSet<>();
  if(b.instance_info.size()!=a.instance_info.size()+1)throw new Exception("Class count mismatch");
  for(var body:a.bodies)if(!Arrays.equals(body.getCodeBytes(),b.findBody(body.method_info).getCodeBytes()))changed.add(body.method_info);
  if(!changed.equals(Set.of(86)))throw new Exception("Unexpected modified methods: "+changed);
  int checked=0;for(var body:b.bodies)if(body.method_info>=a.method_info.size()||changed.contains(body.method_info)){
   var stats=body.getCode().getStats(b,body,body.init_scope_depth,false);
   if(stats==null||stats.maxstack>body.max_stack||stats.maxscope>body.max_scope_depth)throw new Exception("Stack/scope mismatch: "+body.method_info);checked++;
  }
  if(b.findClassByName("disney.MenuBootstrap")<0)throw new Exception("Helper missing");System.out.println("PASS: only original method 86 modified; "+checked+" new/hooked bodies have valid stack/scope bounds");
 }
}
