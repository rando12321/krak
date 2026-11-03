// Java / PatchFollow.java / Java 21 + FFDec / retire mass and speed controllers and attach performance controls
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.avm2.instructions.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;import java.util.*;
class PatchSettings{public static void main(String[]args)throws Exception{
 SWF s=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;for(Tag t:s.getTags())if(t instanceof DoABC2Tag && ((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;if(tag==null)throw new Exception("Loader missing");var a=tag.getABC();var idx=s.getAbcIndex();idx.selectAbc(a);
 new ActionScript3Parser(idx).addScript(Files.readString(Path.of(args[1])),"SettingsControls.as",a.instance_info.size(),a.script_info.size(),s.getDocumentClass(),a);
 var body=a.findBody(86);var code=body.getCode();int pos=code.code.size()-1;if(code.code.get(pos).definition.instructionCode!=0x47)throw new Exception("Missing return");int helper=a.findClassByName("disney.SettingsControls");
 code.insertInstruction(pos,new AVM2Instruction(0,0x60,new int[]{a.instance_info.get(helper).name_index}),body);code.insertInstruction(pos+1,new AVM2Instruction(0,0xd0,new int[]{}),body);code.insertInstruction(pos+2,new AVM2Instruction(0,0x4f,new int[]{a.constants.getQnameId("attach",0x16,"",true),1}),body);
 body.max_stack=Math.max(body.max_stack,2);body.setModified();tag.setModified(true);s.setModified(true);try(var out=new FileOutputStream(args[2])){s.saveTo(out);}System.out.println("Follow controller attached");
}}
