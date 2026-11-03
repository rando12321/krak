// ActionScript 3 / NativeFormatTests.as / Ruffle AVM2 / execute the actual uploaded game's movement packet constructor
package disney {
 import flash.display.MovieClip;import flash.utils.ByteArray;import flash.utils.getDefinitionByName;import flash.external.ExternalInterface;
 public class NativeFormatTests {
  private static var count:int=0;
  private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  private static function key(digits:String):String{var text:String="";for(var i:int=0;i<digits.length;i++)text+=String.fromCharCode(int(digits.charAt(i)));return text;}
  public static function run(display:MovieClip):void {
   var result:String;
   try{
    var NativePacket:Class=getDefinitionByName(key("7653661552")) as Class;
    var x:String=key("832341856581");var y:String=key("4683714731");var vx:String=key("288887425823");var vy:String=key("5434721882586");
    var old:ByteArray=new ByteArray();old.writeByte(8);old.writeByte(3);old.writeShort(279);old.writeShort(99);old.writeByte(0);old.writeShort(0);old.writeShort(0);old.writeByte(0);old.position=0;
    var broken:Object=new NativePacket(old);check(Math.round(broken[x]*30)==1 && Math.round(broken[y]*30)==23,"old shorts reproduce misread 279/99 as 1/23");
    var cases:Array=[[279,99],[98,120],[486,181],[660,163],[-42,83],[1,1],[-32768,32767],[-1,-64],[64,127],[128,129],[8192,-8192],[0,0]];
    for each(var pair:Array in cases){
     var bytes:ByteArray=LegacyOptionsV5.encodePosition(pair[0],pair[1]);var decoded:Object=new NativePacket(bytes);
     var expectedX:int=pair[0]==0 ? 1 : pair[0];var expectedY:int=pair[1]==0 ? 1 : pair[1];
     check(Math.abs(decoded[x]*30-expectedX)<0.001 && Math.abs(decoded[y]*30-expectedY)<0.001,"actual native decoder position: "+pair);
     check(decoded[vx]==0 && decoded[vy]==0,"coordinates do not spill into velocity: "+pair);
     check(bytes.bytesAvailable==0,"exact native packet boundary: "+pair);
    }
    result="PASS: "+count+" actual native movement decoder checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
