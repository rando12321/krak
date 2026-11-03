// Java / RenameButton.java / Java 21 + FFDec / rename only the menu button label
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import java.io.*;import java.util.*;
class RenameButton {public static void main(String[]args)throws Exception {
 SWF s=new SWF(new FileInputStream(args[0]),false);int count=0;
 for(Tag t:s.getTags())if(t instanceof DoABC2Tag){var a=((DoABC2Tag)t).getABC();for(int i=1;i<a.constants.getStringCount();i++)if("Menu Disney".equals(a.constants.getString(i))){a.constants.setString(i,"Menu SDDS");count++;t.setModified(true);}}
 if(count!=1)throw new Exception("Expected one label, found "+count);s.setModified(true);try(var out=new FileOutputStream(args[1])){s.saveTo(out);}
 SWF saved=new SWF(new FileInputStream(args[1]),false);int verified=0;var before=s.getTags();var after=saved.getTags();for(int j=0;j<before.size();j++)if(before.get(j) instanceof DoABC2Tag){var a=((DoABC2Tag)before.get(j)).getABC();var b=((DoABC2Tag)after.get(j)).getABC();for(var body:a.bodies){if(!Arrays.equals(body.getCodeBytes(),b.findBody(body.method_info).getCodeBytes()))throw new Exception("Method changed");verified++;}if(a.constants.getStringId("Menu SDDS",false)<=0||a.constants.getStringId("Menu Disney",false)>0)throw new Exception("Incorrect label");}
 System.out.println("PASS: Menu SDDS saved; "+verified+" method bodies preserved");
}}
