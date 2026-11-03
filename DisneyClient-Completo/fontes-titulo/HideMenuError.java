// Java / HideMenuError.java / Java 21 + FFDec / hide startup menu error banner while retaining its text
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import java.io.*;import java.util.*;
class HideMenuError{public static void main(String[]args)throws Exception{
 SWF s=new SWF(new FileInputStream(args[0]),false);int count=0;
 for(Tag t:s.getTags())if(t instanceof DoABC2Tag){var a=((DoABC2Tag)t).getABC();for(var body:a.bodies){var c=body.getCode();boolean found=false;for(int i=0;i<c.code.size();i++){var ins=c.code.get(i);if(ins.definition.instructionCode==0x2c&&"Falha ao construir o menu. Codigo Flash: ".equals(a.constants.getString(ins.operands[0])))found=true;
 if(found&&ins.definition.instructionCode==0x61&&"visible".equals(a.constants.getString(a.constants.getMultiname(ins.operands[0]).name_index))&&c.code.get(i-1).definition.instructionCode==0x26){c.code.set(i-1,new com.jpexs.decompiler.flash.abc.avm2.instructions.AVM2Instruction(c.code.get(i-1).getAddress(),0x27,new int[]{}));body.setModified();t.setModified(true);count++;found=false;}}}}
 if(count!=1)throw new Exception("Expected one error banner, found "+count);s.setModified(true);try(var out=new FileOutputStream(args[1])){s.saveTo(out);}System.out.println("PASS: menu failure banner hidden; message text retained");
}}
