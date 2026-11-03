// Java / PatchTitle.java / Java 21 + FFDec / replace only startup title hook
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;
class PatchSpeedLimit {public static void main(String[]args)throws Exception{
 SWF s=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;for(Tag t:s.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("disney.PhysicsGuardV2")>=0)tag=(DoABC2Tag)t;
 if(tag==null)throw new Exception("Missing marker");ABC a=tag.getABC();var idx=s.getAbcIndex();idx.selectAbc(a);new ActionScript3Parser(idx).addScript(Files.readString(Path.of(args[1])),"PhysicsGuardV3.as",a.instance_info.size(),a.script_info.size(),s.getDocumentClass(),a);
 int old=a.instance_info.get(a.findClassByName("disney.PhysicsGuardV2")).name_index,replacement=a.instance_info.get(a.findClassByName("disney.PhysicsGuardV3")).name_index,count=0;var body=a.findBody(86);
 for(var ins:body.getCode().code)if(ins.definition.instructionCode==0x60&&ins.operands[0]==old){ins.operands[0]=replacement;count++;}
 if(count!=1)throw new Exception("Unexpected marker hooks: "+count);body.setModified();tag.setModified(true);s.setModified(true);try(var out=new FileOutputStream(args[2])){s.saveTo(out);}System.out.println("Title hook replaced: Sdds Menu, animated RGB");
}}
