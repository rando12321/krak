// Java / VerifyBindings.java / Java 21 + FFDec / validate extracted UI classes and members against game ABC
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import java.io.*;import java.util.*;
class VerifyBindings {
 static ABC abc;static Properties names=new Properties();static String symbol(String key){return new String(Base64.getDecoder().decode(names.getProperty(key)),java.nio.charset.StandardCharsets.UTF_8);}
 static boolean member(int cls,String name,Set<Integer> seen){if(cls<0||!seen.add(cls))return false;var i=abc.instance_info.get(cls);for(var t:i.instance_traits.traits)if(abc.constants.getString(abc.constants.getMultiname(t.name_index).name_index).equals(name))return true;for(var t:abc.class_info.get(cls).static_traits.traits)if(abc.constants.getString(abc.constants.getMultiname(t.name_index).name_index).equals(name))return true;int parent=-1;for(int x=0;x<abc.instance_info.size();x++)if(abc.instance_info.get(x).name_index==i.super_index)parent=x;return member(parent,name,seen);}
 public static void main(String[] args)throws Exception {
  names.load(new FileInputStream(args[1]));SWF s=new SWF(new FileInputStream(args[0]),false);for(Tag t:s.getTags())if(t instanceof DoABC2Tag)abc=((DoABC2Tag)t).getABC();int count=0;
  String[][] groups={{"ui_element_class_name","set_prep_ui","add_ui_element","set_box","set_draggable","set_scrollable","set_shape"},{"prep_ui_class_name","prep_ui1_instance","prep_ui4_instance"},{"ui_items_list_class_name","select_item"},{"main_ui_class_name","add_ui"}};
  for(var g:groups){int c=abc.findClassByName(symbol(g[0]));if(c<0)throw new Exception("Class binding missing: "+g[0]);for(int j=1;j<g.length;j++){if(!member(c,symbol(g[j]),new HashSet<>()))throw new Exception("Member missing: "+g[j]+" in "+g[0]);count++;}}
  System.out.println("PASS: 4 UI classes and "+count+" UI members exist in game bytecode");
 }
}
