// Java / PatchStartText.java / Java 21 + FFDec 26.4 / insert startup marker into completed game-load callback
import com.jpexs.decompiler.flash.SWF;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.instructions.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;
class PatchLegacy {public static void main(String[] args)throws Exception {
 SWF swf=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;
 for(Tag t:swf.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;
 if(tag==null)throw new IllegalStateException("No loader ABC");ABC abc=tag.getABC();int oldClasses=abc.instance_info.size(),oldScripts=abc.script_info.size();var index=swf.getAbcIndex();index.selectAbc(abc);
 new ActionScript3Parser(index).addScript(Files.readString(Path.of(args[1])),"LegacyOptions.as",oldClasses,oldScripts,swf.getDocumentClass(),abc);
 int main=abc.findClassByName("ChargeurTransformice_fla.MainTimeline"),helper=abc.findClassByName("disney.LegacyOptions"),method=-1;
 for(var trait:abc.instance_info.get(main).instance_traits.traits)if(abc.constants.getString(abc.constants.getMultiname(trait.name_index).name_index).equals("swf_loaded"))method=((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)trait).method_info;
 if(method<0||helper<0)throw new IllegalStateException("Class or callback missing");MethodBody body=abc.findBody(method);var code=body.getCode();
 if(code.code.size()<3||code.code.get(0).definition.instructionCode!=0xD0||code.code.get(1).definition.instructionCode!=0x30)throw new IllegalStateException("Unexpected method prologue");
 int insertion=code.code.size()-1; if(code.code.get(insertion).definition.instructionCode!=0x47)throw new Exception("Expected return");
 code.insertInstruction(insertion,new AVM2Instruction(0,0x60,new int[]{abc.instance_info.get(helper).name_index}),body);
 code.insertInstruction(insertion+1,new AVM2Instruction(0,0xD0,new int[]{}),body);
 code.insertInstruction(insertion+2,new AVM2Instruction(0,0x4F,new int[]{abc.constants.getQnameId("attach",0x16,"",true),1}),body);
 body.max_stack=Math.max(body.max_stack,2);body.setModified();tag.setModified(true);swf.setModified(true);
 try(var out=new FileOutputStream(args[2])){swf.saveTo(out);}System.out.println("Startup text hook: swf_loaded method="+method+" classes="+oldClasses+" -> "+abc.instance_info.size());
}}
