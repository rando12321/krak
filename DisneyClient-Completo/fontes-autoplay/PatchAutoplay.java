// Java / PatchAutoplay.java / Java 21 + FFDec / append saved-route player without altering native networking
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.*;import com.jpexs.decompiler.flash.abc.avm2.instructions.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;
class PatchAutoplay {
 public static void main(String[]args)throws Exception{
  SWF swf=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;for(Tag t:swf.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;
  if(tag==null)throw new IllegalStateException("Missing loader");ABC a=tag.getABC();var idx=swf.getAbcIndex();idx.selectAbc(a);
  new ActionScript3Parser(idx).addScript(Files.readString(Path.of(args[1])),"RoutePlayer.as",a.instance_info.size(),a.script_info.size(),swf.getDocumentClass(),a);
  int helper=a.findClassByName("disney.RoutePlayer"),main=a.findClassByName("ChargeurTransformice_fla.MainTimeline");MethodBody loaded=null;
  for(var t:a.instance_info.get(main).instance_traits.traits)if(t instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter&&a.constants.getString(a.constants.getMultiname(t.name_index).name_index).equals("swf_loaded"))loaded=a.findBody(((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)t).method_info);
  if(loaded==null||helper<0)throw new IllegalStateException("Missing callback");var c=loaded.getCode();int count=0;
  for(int i=c.code.size()-1;i>=0;i--)if(c.code.get(i).definition.instructionCode==0x47){c.insertInstruction(i,new AVM2Instruction(0,0x60,new int[]{a.instance_info.get(helper).name_index}),loaded);c.insertInstruction(i+1,new AVM2Instruction(0,0xd0,new int[]{}),loaded);c.insertInstruction(i+2,new AVM2Instruction(0,0x4f,new int[]{a.constants.getQnameId("attach",0x16,"",true),1}),loaded);count++;}
  if(count!=1)throw new IllegalStateException("Unexpected returns");loaded.max_stack=Math.max(loaded.max_stack,2);loaded.setModified();tag.setModified(true);swf.setModified(true);try(var out=new FileOutputStream(args[2])){swf.saveTo(out);}System.out.println("RoutePlayer compiled and attached; existing networking unchanged");
 }
}
