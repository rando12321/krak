// ActionScript 3 / ScrollTests.as / Ruffle AVM2 / nested scroll interception and dynamic bounds checks
package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.display.Shape;import flash.events.MouseEvent;import flash.geom.Rectangle;import flash.external.ExternalInterface;
 public class RgbMouseTests {
  private static var count:int=0;private static function check(ok:Boolean,s:String):void{if(!ok)throw new Error(s);count++;}
  public static function run(display:MovieClip):void{
   var result:String;
   try{
    var r:MovieClip=new MovieClip();display.addChild(r);var view:Sprite=new Sprite();view.scrollRect=new Rectangle(0,0,535,232);r.addChild(view);var options:Sprite=new Sprite();view.addChild(options);var general:MovieClip=new MovieClip();options.addChild(general);
    var body:Sprite=new Sprite();body.graphics.beginFill(0);body.graphics.drawRect(0,0,510,800);general.addChild(body);body.y=-80;var mask:Shape=new Shape();mask.graphics.beginFill(0);mask.graphics.drawRect(0,0,535,232);general.addChild(mask);body.mask=mask;
    var bar:Sprite=new Sprite();bar.x=520;bar.graphics.beginFill(0);bar.graphics.drawRect(0,0,5,300);general.addChild(bar);var enabled:Boolean=true;general["setScroll"]=function(value:Boolean):void{enabled=value;};r["Keys"]={set_scrollable:"setScroll"};r["Interface"]={general_ui:general,options_ui:options};var nativeWheel:int=0;var modernWheel:int=0;general.addEventListener(MouseEvent.MOUSE_WHEEL,function(e:MouseEvent):void{nativeWheel++;});view.addEventListener(MouseEvent.MOUSE_WHEEL,function(e:MouseEvent):void{modernWheel++;});
    var fix:PlayerScrollFix=new PlayerScrollFix(r);fix.update();check(!enabled && body.mask==null && body.y==0,"native scroll and mask reset");check(!bar.visible,"obsolete native scrollbar hidden");
    body.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,0,0,null,false,false,false,false,-1));check(view.scrollRect.y==22,"one scroll step per wheel event");check(nativeWheel==0 && modernWheel==0,"both competing scroll handlers intercepted");
    body.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,0,0,null,false,false,false,false,-100));check(view.scrollRect.y==576,"lower boundary includes final rows");
    body.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,0,0,null,false,false,false,false,100));check(view.scrollRect.y==0,"upper boundary clamped");
    body.graphics.clear();body.graphics.beginFill(0);body.graphics.drawRect(0,0,510,100);fix.update();body.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,0,0,null,false,false,false,false,-100));check(view.scrollRect.y==0,"short content does not scroll into blank space");
    options.removeChild(general);var farm:Sprite=new Sprite();options.addChild(farm);fix.update();farm.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,0,0,null,false,false,false,false,-1));check(modernWheel==1,"other tabs preserve existing wheel behavior");
    options.removeChild(farm);options.addChild(general);body.graphics.clear();body.graphics.beginFill(0);body.graphics.drawRect(0,0,510,800);fix.update();check(view.scrollRect.y==0,"returning to Player resets offset");
    view.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,0,0,null,false,false,false,false,-1));check(view.scrollRect.y==22 && modernWheel==1,"viewport target event handled once");
    result="PASS: "+count+" Player scroll checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
