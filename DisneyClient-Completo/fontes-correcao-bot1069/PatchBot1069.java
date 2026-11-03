// Java / PatchBot1069.java / Java 21 + FFDec / append saved-route player without altering native networking
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.*;import com.jpexs.decompiler.flash.abc.avm2.instructions.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;
class PatchBot1069 {
 public static void main(String[]args)throws Exception{
  SWF swf=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;for(Tag t:swf.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;
  if(tag==null)throw new IllegalStateException("Missing loader");ABC a=tag.getABC();var idx=swf.getAbcIndex();idx.selectAbc(a);
  new ActionScript3Parser(idx).addScript(Files.readString(Path.of(args[1])),"RoutePlayerFixed1069.as",a.instance_info.size(),a.script_info.size(),swf.getDocumentClass(),a);
  int helper=a.findClassByName("disney.RoutePlayerFixed1069"),main=a.findClassByName("ChargeurTransformice_fla.MainTimeline");MethodBody loaded=null;
  for(var t:a.instance_info.get(main).instance_traits.traits)if(t instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter&&a.constants.getString(a.constants.getMultiname(t.name_index).name_index).equals("swf_loaded"))loaded=a.findBody(((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)t).method_info);
  if(loaded==null||helper<0)throw new IllegalStateException("Missing callback");var c=loaded.getCode();int count=0;
  int old=a.findClassByName("disney.RoutePlayer");
  for(var ins:c.code)if(ins.definition.instructionCode==0x60 && ins.operands[0]==a.instance_info.get(old).name_index){ins.operands[0]=a.instance_info.get(helper).name_index;count++;}
  int statements=a.findClassByName("ChargeurTransformice_fla.Statements"),guarded=0;
  for(var trait:a.instance_info.get(statements).instance_traits.traits){
   if(!(trait instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter))continue;
   String name=a.constants.getString(a.constants.getMultiname(trait.name_index).name_index);
   if(!java.util.Set.of("play_map","play_sequence","step").contains(name))continue;
   var body=a.findBody(((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)trait).method_info);var code=body.getCode();
   code.insertInstruction(0,new AVM2Instruction(0,0xd0,new int[]{}),body);
   code.insertInstruction(1,new AVM2Instruction(0,0x66,new int[]{a.constants.getQnameId("main_instance",0x16,"",true)}),body);
   code.insertInstruction(2,new AVM2Instruction(0,0x66,new int[]{a.constants.getQnameId("auto_play",0x16,"",true)}),body);
   code.insertInstruction(3,new AVM2Instruction(0,0x12,new int[]{1}),body);
   code.insertInstruction(4,new AVM2Instruction(0,0x47,new int[]{}),body);
   code.code.get(3).operands[0]=1;
   body.max_stack=Math.max(body.max_stack,1);body.setModified();guarded++;
  }
  int packetHooks=0;
  var originalTraits=new java.util.ArrayList<>(a.instance_info.get(main).instance_traits.traits);
  for(var trait:originalTraits)if(trait instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter && "handle_packet".equals(a.constants.getString(a.constants.getMultiname(trait.name_index).name_index))){
   var originalTrait=(com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)trait;
   var info=a.method_info.get(originalTrait.method_info);
   int aliasMethod=a.addMethodInfo(new MethodInfo(info.param_types.clone(),info.ret_type,info.name_index,info.flags,info.optional,info.paramNames));
   var body=a.findBody(originalTrait.method_info);var aliasBody=body.clone(true);aliasBody.method_info=aliasMethod;a.addMethodBody(aliasBody);
   var aliasTrait=originalTrait.clone();aliasTrait.name_index=a.constants.getQnameId("sddsNativeHandlePacket",0x16,"",true);aliasTrait.method_info=aliasMethod;aliasTrait.disp_id=0;a.instance_info.get(main).instance_traits.traits.add(aliasTrait);
   AVM2Code wrapper=new AVM2Code();wrapper.code=new java.util.ArrayList<>(java.util.List.of(
    new AVM2Instruction(0,0xd0,new int[]{}),new AVM2Instruction(0,0x30,new int[]{}),
    new AVM2Instruction(0,0x60,new int[]{a.instance_info.get(helper).name_index}),
    new AVM2Instruction(0,0xd0,new int[]{}),new AVM2Instruction(0,0xd1,new int[]{}),new AVM2Instruction(0,0xd2,new int[]{}),
    new AVM2Instruction(0,0x4f,new int[]{a.constants.getQnameId("processNativePacket",0x16,"",true),3}),new AVM2Instruction(0,0x47,new int[]{})));
   body.setCode(wrapper);body.exceptions=new ABCException[0];body.max_stack=4;body.max_scope_depth=Math.max(body.max_scope_depth,body.init_scope_depth+1);body.setModified();packetHooks++;
  }
  if(packetHooks!=1)throw new IllegalStateException("Native victory wrapper missing");
  if(guarded!=3)throw new IllegalStateException("Legacy playback guard incomplete");
  if(count!=1)throw new IllegalStateException("Unexpected returns");loaded.max_stack=Math.max(loaded.max_stack,2);loaded.setModified();tag.setModified(true);swf.setModified(true);try(var out=new FileOutputStream(args[2])){swf.saveTo(out);}System.out.println("RoutePlayerFixed1069 compiled; original route hook redirected; legacy playback guarded; genuine native victory protected from NoDelay; login unchanged");
 }
}
