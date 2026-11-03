// Java / PatchConnection.java / Java 21 + FFDec / bypass obsolete socket/timer interception without changing game networking
import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.*;import com.jpexs.decompiler.flash.abc.avm2.*;import com.jpexs.decompiler.flash.abc.avm2.instructions.*;import com.jpexs.decompiler.flash.abc.avm2.parser.script.*;import java.io.*;import java.nio.file.*;
class PatchConnection {
 static String name(ABC a,AVM2Instruction i){int op=i.definition.instructionCode;if(op==0x66||op==0x61)return a.constants.getString(a.constants.getMultiname(i.operands[0]).name_index);return "";}
 static int find(ABC a,AVM2Code c,String n,int op,int start){for(int i=start;i<c.code.size();i++)if(c.code.get(i).definition.instructionCode==op&&n.equals(name(a,c.code.get(i))))return i;throw new IllegalStateException("Anchor missing: "+n);}
 static void jump(AVM2Code code,MethodBody body,AVM2Instruction from,AVM2Instruction to){int pos=code.code.indexOf(from);var ins=new AVM2Instruction(0,0x10,new int[]{0});code.insertInstruction(pos,ins,body);ins.operands[0]=(int)(to.getAddress()-ins.getAddress()-ins.getBytesLength());}
 public static void main(String[] args)throws Exception {
  SWF swf=new SWF(new FileInputStream(args[0]),false);DoABC2Tag tag=null;for(Tag t:swf.getTags())if(t instanceof DoABC2Tag&&((DoABC2Tag)t).getABC().findClassByName("ChargeurTransformice_fla.MainTimeline")>=0)tag=(DoABC2Tag)t;
  if(tag==null)throw new IllegalStateException("Loader missing");ABC a=tag.getABC();var index=swf.getAbcIndex();index.selectAbc(a);
  new ActionScript3Parser(index).addScript(Files.readString(Path.of(args[1])),"ConnectionGuard.as",a.instance_info.size(),a.script_info.size(),swf.getDocumentClass(),a);
  int main=a.findClassByName("ChargeurTransformice_fla.MainTimeline"),helper=a.findClassByName("disney.ConnectionGuard");MethodBody loop=null,loaded=null;
  for(var trait:a.instance_info.get(main).instance_traits.traits){String n=a.constants.getString(a.constants.getMultiname(trait.name_index).name_index);if(trait instanceof com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter){var m=(com.jpexs.decompiler.flash.abc.types.traits.TraitMethodGetterSetter)trait;if(n.equals("loop_game"))loop=a.findBody(m.method_info);if(n.equals("swf_loaded"))loaded=a.findBody(m.method_info);}}
  if(loop==null||loaded==null||helper<0)throw new IllegalStateException("Callback missing");var c=loop.getCode();
  int netStart=find(a,c,"socket_class",0x66,0)-2,netEnd=find(a,c,"last_bulle_socket_instance",0x61,netStart)+1;
  int checks=find(a,c,"frame_loop_class",0x66,netEnd)-2;int delay=find(a,c,"change_jump_delay",0x66,checks);int checksEnd=-1;
  int timer=find(a,c,"check_timer",0x66,checks);for(int i=timer;i<delay;i++)if(c.code.get(i).definition.instructionCode==0x62&&c.code.get(i).operands[0]==17){checksEnd=i;break;}
  if(netStart!=47||netEnd!=245||checks!=539||checksEnd!=624)throw new IllegalStateException("Unexpected block layout");
  var netFrom=c.code.get(netStart);var netTo=c.code.get(netEnd);var checkFrom=c.code.get(checks);var checkTo=c.code.get(checksEnd);
  jump(c,loop,checkFrom,checkTo);jump(c,loop,netFrom,netTo);loop.setModified();
  var code=loaded.getCode();int count=0;for(int i=code.code.size()-1;i>=0;i--)if(code.code.get(i).definition.instructionCode==0x47){code.insertInstruction(i,new AVM2Instruction(0,0x60,new int[]{a.instance_info.get(helper).name_index}),loaded);code.insertInstruction(i+1,new AVM2Instruction(0,0xd0,new int[]{}),loaded);code.insertInstruction(i+2,new AVM2Instruction(0,0x4f,new int[]{a.constants.getQnameId("attach",0x16,"",true),1}),loaded);count++;}
  if(count!=1)throw new IllegalStateException("Unexpected callback returns");loaded.max_stack=Math.max(loaded.max_stack,2);loaded.setModified();tag.setModified(true);swf.setModified(true);
  try(var out=new FileOutputStream(args[2])){swf.saveTo(out);}System.out.println("Preserved native socket handlers and checker timers; changed methods="+loaded.method_info+","+loop.method_info);
 }
}
