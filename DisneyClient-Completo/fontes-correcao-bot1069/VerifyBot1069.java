import com.jpexs.decompiler.flash.*;
import com.jpexs.decompiler.flash.tags.*;
import com.jpexs.decompiler.flash.abc.*;
import com.jpexs.decompiler.flash.abc.types.*;
import com.jpexs.decompiler.flash.abc.types.traits.*;
import java.io.*;
import java.util.*;
class VerifyBot1069 {
 static ABC abc(SWF s){for(Tag t:s.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)return ((DoABC2Tag)t).getABC();throw new RuntimeException("Missing loader");}
 public static void main(String[]args)throws Exception {
  ABC a=abc(new SWF(new FileInputStream(args[0]),false)),b=abc(new SWF(new FileInputStream(args[1]),false));
  int main=a.findClassByName("ChargeurTransformice_fla.MainTimeline"),loaded=-1,packet=-1,alias=-1;
  for(var t:a.instance_info.get(main).instance_traits.traits)if(t instanceof TraitMethodGetterSetter&&a.constants.getString(a.constants.getMultiname(t.name_index).name_index).equals("swf_loaded"))loaded=((TraitMethodGetterSetter)t).method_info;
  for(var trait:a.instance_info.get(main).instance_traits.traits)if(trait instanceof TraitMethodGetterSetter && "handle_packet".equals(a.constants.getString(a.constants.getMultiname(trait.name_index).name_index)))packet=((TraitMethodGetterSetter)trait).method_info;
  for(var trait:b.instance_info.get(main).instance_traits.traits)if(trait instanceof TraitMethodGetterSetter && "sddsNativeHandlePacket".equals(b.constants.getString(b.constants.getMultiname(trait.name_index).name_index)))alias=((TraitMethodGetterSetter)trait).method_info;
  if(alias<0 || !Arrays.equals(a.findBody(packet).getCodeBytes(),b.findBody(alias).getCodeBytes()))throw new Exception("Original native packet handler not preserved byte-for-byte");
  Set<Integer> changed=new TreeSet<>();
  for(var body:a.bodies)if(!Arrays.equals(body.getCodeBytes(),b.findBody(body.method_info).getCodeBytes()))changed.add(body.method_info);
  Set<Integer> expected=new TreeSet<>();expected.add(loaded);expected.add(packet);
  int statements=a.findClassByName("ChargeurTransformice_fla.Statements");
  for(var trait:a.instance_info.get(statements).instance_traits.traits)if(trait instanceof TraitMethodGetterSetter){
   String name=a.constants.getString(a.constants.getMultiname(trait.name_index).name_index);
   if(Set.of("play_map","play_sequence","step").contains(name))expected.add(((TraitMethodGetterSetter)trait).method_info);
  }
  if(expected.size()!=5 || !changed.equals(expected))throw new Exception("Unexpected modified methods: "+changed);
  for(int method:expected)if(method!=loaded && method!=packet){
   var code=b.findBody(method).getCode();int[] ops={0xd0,0x66,0x66,0x12,0x47};
   for(int i=0;i<5;i++)if(code.code.get(i).definition.instructionCode!=ops[i])throw new Exception("Invalid legacy guard prefix at "+method);
   if(code.code.get(3).operands[0]!=1)throw new Exception("Invalid guard branch");
   byte[] before=a.findBody(method).getCodeBytes(),after=b.findBody(method).getCodeBytes();
   if(!Arrays.equals(before,Arrays.copyOfRange(after,after.length-before.length,after.length)))throw new Exception("Legacy body changed beyond guard at "+method);
  }


  if(b.instance_info.size()!=a.instance_info.size()+1||b.findClassByName("disney.RoutePlayerFixed1069")<0)throw new Exception("Fixed route class missing");
  int checked=0;
  for(var body:b.bodies)if(body.method_info>=a.method_info.size()||changed.contains(body.method_info)){
   var stats=body.getCode().getStats(b,body,body.init_scope_depth,false);
   if(stats==null||stats.maxstack>body.max_stack||stats.maxscope>body.max_scope_depth)throw new Exception("Stack/scope bounds invalid at "+body.method_info);
   checked++;
  }
  System.out.println("PASS: only swf_loaded, native victory wrapper and 3 legacy playback guards modified; original packet processor preserved as exact alias; login and all other original methods preserved; "+checked+" method bodies verified; RoutePlayerFixed1069 added");
 }
}
