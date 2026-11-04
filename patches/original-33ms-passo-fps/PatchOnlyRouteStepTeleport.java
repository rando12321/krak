import com.jpexs.decompiler.flash.*;import com.jpexs.decompiler.flash.tags.*;import com.jpexs.decompiler.flash.abc.*;import com.jpexs.decompiler.flash.abc.types.traits.*;import java.io.*;import java.util.*;
class PatchOnlyRouteStepTeleport {
 static ABC abc(SWF s){for(var t:s.getTags())if(t instanceof DoABC2Tag && ((DoABC2Tag)t).getABC().findClassByName("disney.RoutePlayerNative")>=0)return ((DoABC2Tag)t).getABC();throw new IllegalStateException("Missing original Robot");}
 public static void main(String[] args)throws Exception{
  var original=new SWF(new FileInputStream(args[0]),false);var patched=new SWF(new FileInputStream(args[0]),false);var a=abc(original);var b=abc(patched);int ci=b.findClassByName("disney.RoutePlayerNative");int changedMethod=-1;
  for(var t:b.instance_info.get(ci).instance_traits.traits)if(t instanceof TraitMethodGetterSetter && "apply".equals(b.constants.getString(b.constants.getMultiname(t.name_index).name_index))){
   var body=b.findBody(((TraitMethodGetterSetter)t).method_info);var code=body.getCode();int found=0;
   for(int i=4;i<code.code.size();i++){var op=code.code.get(i);if(op.definition.instructionCode!=0x4f || !"followSample".equals(b.constants.getString(b.constants.getMultiname(op.operands[0]).name_index)))continue;
    if(op.operands[1]!=6)throw new IllegalStateException("Unexpected followSample arity");
    for(int p=0;p<2;p++){var load=code.code.get(i-4+p*2);var get=code.code.get(i-3+p*2);if(load.definition.instructionCode!=0x62 || get.definition.instructionCode!=0x66 || !(p==0 ? "x":"y").equals(b.constants.getString(b.constants.getMultiname(get.operands[0]).name_index)))throw new IllegalStateException("Unexpected coordinate producers");}
    op.operands[0]=b.constants.getQnameId("movement",0x16,"",true);op.operands[1]=4;
    for(int j=i-1;j>=i-4;j--)code.removeInstruction(j,body);body.setModified();found++;break;
   }
   if(found!=1)throw new IllegalStateException("Expected one step correction call");changedMethod=body.method_info;
  }
  if(changedMethod<0)throw new IllegalStateException("Missing apply method");var changed=new TreeSet<Integer>();
  if(a.method_info.size()!=b.method_info.size() || a.instance_info.size()!=b.instance_info.size())throw new IllegalStateException("Class/method counts changed");
  for(var before:a.bodies)if(!Arrays.equals(before.getCodeBytes(),b.findBody(before.method_info).getCodeBytes()))changed.add(before.method_info);
  if(!changed.equals(Set.of(changedMethod)))throw new IllegalStateException("Unexpected method changes: "+changed);
  var body=b.findBody(changedMethod);var stats=body.getCode().getStats(b,body,body.init_scope_depth,false);if(stats==null || stats.maxstack>body.max_stack || stats.maxscope>body.max_scope_depth)throw new IllegalStateException("Invalid stack/scope");
  for(var t:patched.getTags())if(t instanceof DoABC2Tag && ((DoABC2Tag)t).getABC()==b)t.setModified(true);patched.setModified(true);try(var out=new FileOutputStream(args[1])){patched.saveTo(out);}
  System.out.println("PASS: only RoutePlayerNative.apply changed; movement replaces followSample; all other original method bodies byte-for-byte preserved; class/method counts and stack/scope valid");
 }
}
