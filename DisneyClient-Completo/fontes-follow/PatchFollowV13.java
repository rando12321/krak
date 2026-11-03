// Java / PatchFollow.java / Java 21 + FFDec / append saved-route player without altering native networking
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.*;import com.jpexs.decompiler.flash.abc.avm2.instructions.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;
class PatchFollowV13 {
 public static void main(String[]args)throws Exception{
  SWF swf=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;for(Tag t:swf.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;
  if(tag==null)throw new IllegalStateException("Missing loader");ABC a=tag.getABC();var idx=swf.getAbcIndex();idx.selectAbc(a);
  new ActionScript3Parser(idx).addScript(Files.readString(Path.of(args[1])),"FollowControllerV13.as",a.instance_info.size(),a.script_info.size(),swf.getDocumentClass(),a);
  int helper=a.findClassByName("disney.FollowControllerV13"),main=a.findClassByName("ChargeurTransformice_fla.MainTimeline");MethodBody loaded=null;
  for(var t:a.instance_info.get(main).instance_traits.traits)if(t instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter&&a.constants.getString(a.constants.getMultiname(t.name_index).name_index).equals("swf_loaded"))loaded=a.findBody(((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)t).method_info);
  if(loaded==null||helper<0)throw new IllegalStateException("Missing callback");var c=loaded.getCode();int count=0;
  int old=a.findClassByName("disney.FollowController");
  for(var op:c.code)if(op.definition.instructionCode==0x60 && op.operands[0]==a.instance_info.get(old).name_index){op.operands[0]=a.instance_info.get(helper).name_index;count++;}
  if(count!=1)throw new IllegalStateException("Expected exactly one old follow hook");
  MethodBody packet=null;
  for(var t:a.instance_info.get(main).instance_traits.traits)if(t instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter&&a.constants.getString(a.constants.getMultiname(t.name_index).name_index).equals("handle_packet"))packet=a.findBody(((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)t).method_info);
  if(packet==null)throw new IllegalStateException("Packet callback missing");
  var pc=packet.getCode();int at=-1;for(int i=0;i<pc.code.size();i++)if(pc.code.get(i).definition.instructionCode==0x30){at=i+1;break;}
  if(at<0)throw new IllegalStateException("Packet scope missing");
  pc.insertInstruction(at,new AVM2Instruction(0,0x60,new int[]{a.instance_info.get(helper).name_index}),packet);
  pc.insertInstruction(at+1,new AVM2Instruction(0,0xd0,new int[]{}),packet);
  pc.insertInstruction(at+2,new AVM2Instruction(0,0xd1,new int[]{}),packet);
  pc.insertInstruction(at+3,new AVM2Instruction(0,0x4f,new int[]{a.constants.getQnameId("receive",0x16,"",true),2}),packet);
  packet.max_stack=Math.max(packet.max_stack,3);packet.setModified();
  loaded.max_stack=Math.max(loaded.max_stack,2);loaded.setModified();tag.setModified(true);swf.setModified(true);try(var out=new FileOutputStream(args[2])){swf.saveTo(out);}System.out.println("FollowControllerV13 compiled and attached; packet observer preserves buffer and original handler");
 }
}
