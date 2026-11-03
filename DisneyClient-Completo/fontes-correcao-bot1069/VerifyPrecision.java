// Java 21 + FFDec 26.4.0. Compare an already-patched input with its precision update.
import com.jpexs.decompiler.flash.*;
import com.jpexs.decompiler.flash.tags.*;
import com.jpexs.decompiler.flash.abc.*;
import com.jpexs.decompiler.flash.abc.types.traits.*;
import java.io.*;
import java.util.*;
class VerifyPrecision {
 static ABC abc(String file)throws Exception {
  SWF swf=new SWF(new FileInputStream(file),false);
  for(Tag tag:swf.getTags())if(tag instanceof DoABC2Tag && ((DoABC2Tag)tag).getABC().findClassByName("disney.RoutePlayerFixed1069")>=0)return ((DoABC2Tag)tag).getABC();
  throw new IllegalStateException("Missing route helper");
 }
 public static void main(String[] args)throws Exception {
  ABC a=abc(args[0]),b=abc(args[1]);
  int helper=a.findClassByName("disney.RoutePlayerFixed1069"),boundary=-1;
  for(var script:a.script_info)for(var trait:script.traits.traits)if(trait instanceof TraitClass && ((TraitClass)trait).class_info==helper)boundary=script.init_index;
  if(boundary<0 || helper!=a.instance_info.size()-1 || b.instance_info.size()!=a.instance_info.size())throw new IllegalStateException("Unexpected class layout");
  int preserved=0,checked=0;
  for(int i=0;i<helper;i++)if(a.instance_info.get(i).name_index!=b.instance_info.get(i).name_index || a.instance_info.get(i).iinit_index!=b.instance_info.get(i).iinit_index || a.class_info.get(i).cinit_index!=b.class_info.get(i).cinit_index)throw new IllegalStateException("Original class changed: "+i);
  for(var body:a.bodies)if(body.method_info<boundary){
   var after=b.findBody(body.method_info);
   if(after==null || !Arrays.equals(body.getCodeBytes(),after.getCodeBytes()))throw new IllegalStateException("Original method changed: "+body.method_info);
   preserved++;
  }
  for(var body:b.bodies)if(body.method_info>=boundary){
   var stats=body.getCode().getStats(b,body,body.init_scope_depth,false);
   if(stats==null || stats.maxstack>body.max_stack || stats.maxscope>body.max_scope_depth)throw new IllegalStateException("Invalid stack/scope at "+body.method_info);
   checked++;
  }
  System.out.println("PASS: "+preserved+" pre-existing method bodies outside RoutePlayerFixed1069 unchanged; "+checked+" helper bodies verified");
 }
}
