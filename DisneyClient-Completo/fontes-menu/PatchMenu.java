// Java / PatchMenu.java / Java 21 + FFDec 26.4 / Add automatic menu hook to DisneyClient loader
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.tags.*;
import com.jpexs.decompiler.flash.abc.*;
import com.jpexs.decompiler.flash.abc.types.*;
import com.jpexs.decompiler.flash.abc.avm2.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.*;
import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;
import java.io.*;import java.nio.file.*;
class PatchMenu {public static void main(String[] args)throws Exception {
 SWF swf=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;
 for(Tag t:swf.getTags())if(t instanceof DoABC2Tag && ((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;
 if(tag==null)throw new IllegalStateException("Loader ABC missing");
 ABC abc=tag.getABC();int classes=abc.instance_info.size(),scripts=abc.script_info.size();var index=swf.getAbcIndex();index.selectAbc(abc);
 new ActionScript3Parser(index).addScript(Files.readString(Path.of(args[1])),"MenuBootstrap.as",classes,scripts,swf.getDocumentClass(),abc);
 int main=abc.findClassByName("ChargeurTransformice_fla.MainTimeline"),helper=abc.findClassByName("disney.MenuBootstrap");int method=-1;
 for(var trait:abc.instance_info.get(main).instance_traits.traits)if(abc.constants.getString(abc.constants.getMultiname(trait.name_index).name_index).equals("swf_loaded"))method=((com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)trait).method_info;
 if(method<0||helper<0)throw new IllegalStateException("Required class or method missing");
 MethodBody body=abc.findBody(method);var code=body.getCode();int hooks=0;
 for(int i=code.code.size()-1;i>=0;i--)if(code.code.get(i).definition.instructionCode==0x47){
  code.insertInstruction(i,new AVM2Instruction(0,0x60,new int[]{abc.instance_info.get(helper).name_index}),body);
  code.insertInstruction(i+1,new AVM2Instruction(0,0xD0,new int[]{}),body);
  code.insertInstruction(i+2,new AVM2Instruction(0,0x4F,new int[]{abc.constants.getQnameId("attach",0x16,"",true),1}),body);hooks++;
 }
 if(hooks!=1)throw new IllegalStateException("Unexpected return count");body.max_stack=Math.max(body.max_stack,2);body.setModified();tag.setModified(true);swf.setModified(true);
 try(var out=new FileOutputStream(args[2])){swf.saveTo(out);}System.out.println("Hooked swf_loaded method="+method+" classes="+classes+" -> "+abc.instance_info.size());
}}
