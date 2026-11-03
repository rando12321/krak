// ActionScript 3 / RgbMouseV3Tests.as / Ruffle AVM2 / tint toggle lifecycle checks
package disney {
 import flash.display.MovieClip;
 import flash.display.Sprite;
 import flash.events.MouseEvent;
 import flash.geom.ColorTransform;
 import flash.external.ExternalInterface;
 public class RgbMouseTests {
  private static var count:int=0;
  private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  public static function run(display:MovieClip):void {
   var result:String;
   try {
    var r:MovieClip=new MovieClip();var general:Sprite=new Sprite();general.graphics.drawRect(0,0,200,100);
    var mouse:MovieClip=new MovieClip();mouse.graphics.beginFill(0xFFFFFF);mouse.graphics.drawCircle(0,0,15);
    mouse.transform.colorTransform=new ColorTransform(0.8,0.9,1,0.7,2,3,4,5);
    var baseline:ColorTransform=mouse.transform.colorTransform;
    var p:MovieClip=mouse;p["clip"]=true;p["bitmap"]=new Sprite();p["dead"]=false;r["Keys"]={player:"mouse",player_clip:"clip",player_bitmap:"bitmap",is_dead:"dead"};r["tfm"]={mouse:p};r["Interface"]={general_ui:general};
    var mode:RgbMouseV3=new RgbMouseV3(r);mode.update();var row:Sprite=general.getChildByName("sddsRgbMouseV3Control") as Sprite;
    check(row!=null,"control present");check(mouse.transform.colorTransform.redMultiplier==baseline.redMultiplier,"disabled by default");
    mode.update();check(general.numChildren==1,"no duplicate controls");
    row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));mode.update();check(mouse.transform.colorTransform.redMultiplier<0.4,"tint enabled");check(mouse.transform.colorTransform.alphaMultiplier==baseline.alphaMultiplier,"alpha preserved");
    row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));check(mouse.transform.colorTransform.redMultiplier==baseline.redMultiplier && mouse.transform.colorTransform.redOffset==2,"original restored on disable");
    row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));mode.update();p.dead=true;mode.update();check(mouse.transform.colorTransform.redMultiplier<0.4,"native display takes precedence over stale dead flag");
    var next:MovieClip=new MovieClip();next["bitmap"]=new Sprite();r.tfm.mouse=next;mode.update();check(mouse.transform.colorTransform.redMultiplier==baseline.redMultiplier,"previous player restored");check(next.transform.colorTransform.redMultiplier<0.36,"new mouse tinted after respawn");
    row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));check(next.transform.colorTransform.redMultiplier==1,"respawn baseline restored");
    result="PASS: "+count+" RGB mouse checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
