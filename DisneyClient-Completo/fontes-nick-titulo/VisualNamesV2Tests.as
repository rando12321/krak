// ActionScript 3 / VisualNamesV2Tests.as / Ruffle AVM2 / independent nickname and title controls
package disney {
 import flash.display.MovieClip;
 import flash.display.Sprite;
 import flash.events.Event;
 import flash.events.MouseEvent;
 import flash.text.TextField;
 import flash.external.ExternalInterface;
 public class RgbMouseTests {
  private static var count:int=0;
  private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  public static function run(display:MovieClip):void {
   var result:String;
   try {
    var root:MovieClip=new MovieClip();var general:Sprite=new Sprite();var player:MovieClip=new MovieClip();player["nativeName"]="Original";var avatar:Sprite=new Sprite();avatar.graphics.beginFill(0xFFFFFF);avatar.graphics.drawCircle(0,0,15);player.addChild(avatar);player["avatar"]=avatar;
    root["Keys"]={player:"mouse",player_bitmap:"avatar"};root["tfm"]={mouse:player};root["Interface"]={general_ui:general};
    var plate:Sprite=new Sprite();plate.graphics.beginFill(0x3E424D);plate.graphics.drawRect(0,0,74,28);plate.x=-30;plate.y=-50;player.addChild(plate);
    var mode:VisualNamesV2=new VisualNamesV2(root);mode.update();var nick:Sprite=general.getChildByName("sddsVisualNick") as Sprite;var title:Sprite=general.getChildByName("sddsVisualTitulo") as Sprite;
    check(nick!=null && title!=null,"two controls");mode.update();check(general.numChildren==2,"no duplicate rows");
    check(!player.getChildByName("sddsVisualOverlay0").visible && !player.getChildByName("sddsVisualOverlay1").visible,"disabled defaults");
    var input:TextField=nick.getChildAt(1) as TextField;input.text="<b>Nome</b>";input.dispatchEvent(new Event(Event.CHANGE));nick.getChildAt(0).dispatchEvent(new MouseEvent(MouseEvent.CLICK));mode.update();
    var overlay:Sprite=player.getChildByName("sddsVisualOverlay0") as Sprite;check(overlay.x==7 && overlay.y==-49,"native nameplate position and center");check(overlay.visible && TextField(overlay.getChildAt(0)).text=="<b>Nome</b>","nickname literal text");
    check(!player.getChildByName("sddsVisualOverlay1").visible,"title independent");
    input=title.getChildAt(1) as TextField;input.text="Campeao";input.dispatchEvent(new Event(Event.CHANGE));title.getChildAt(0).dispatchEvent(new MouseEvent(MouseEvent.CLICK));mode.update();check(player.getChildByName("sddsVisualOverlay1").visible,"title enabled");
    nick.getChildAt(0).dispatchEvent(new MouseEvent(MouseEvent.CLICK));check(!overlay.visible && player.nativeName=="Original","original data unchanged on disable");
    var next:MovieClip=new MovieClip();root.tfm.mouse=next;mode.update();check(player.getChildByName("sddsVisualOverlay1")==null && next.getChildByName("sddsVisualOverlay1").visible,"respawn follows player and removes old overlays");
    result="PASS: "+count+" visual names checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
