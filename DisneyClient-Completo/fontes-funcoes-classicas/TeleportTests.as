// ActionScript 3 / LegacyTests.as / Ruffle AVM2 / ported control and lifecycle checks
package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.events.MouseEvent;import flash.events.Event;import flash.events.KeyboardEvent;import flash.text.TextField;import flash.geom.Point;import flash.external.ExternalInterface;import flash.utils.getTimer;
 public class RgbMouseTests {
  private static var count:int=0;
  private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  private static function click(farm:Sprite,id:String):void{farm.getChildByName("sddsLegacy_"+id).dispatchEvent(new MouseEvent(MouseEvent.CLICK));}
  public static function run(display:MovieClip):void{
   var result:String;
   try{
    var r:MovieClip=new MovieClip();display.addChild(r);var farm:Sprite=new Sprite();var game:MovieClip=new MovieClip();var world:Sprite=new Sprite();var mouse:MovieClip=new MovieClip();world.addChild(mouse);game.addChild(world);r.addChild(game);game["mouse"]=mouse;game["world"]=world;mouse["dead"]=false;
    r["Keys"]={player:"mouse",is_dead:"dead",tfm_obj_container:"world",legacy_inventory_class:"MockIcon",legacy_inventory_wrapper:"MockNotification",app_domain:{applicationDomain:{getDefinition:function(name:String):Class{return name=="Vector" ? Point : name=="MockIcon" ? MockIcon : MockNotification;}}}};
    r["tfm"]=game;r["Interface"]={farm_ui:farm};r["current_map_code"]="@1";r["current_round_code"]=1;r["insta_win"]=true;r["insta_death2"]=true;r["insta_death"]=true;r["insta_win_timeout"]=0;r["insta_death_timeout"]=0;
    var calls:Object={move:0,win:0,die:0,x:0,y:0};r["Statements"]={move_player:function(x:Number,y:Number):void{calls.move++;calls.x=x;calls.y=y;},player_victory:function():void{calls.win++;},player_death:function():void{calls.die++;}};
    var velocity:Object={vx:7,vy:8};var body:Object={locked:false,position:null};
    body.setPosition=function(point:Point,angle:Number):Boolean{if(body.locked)return false;calls.move++;calls.x=Math.round(point.x*30);calls.y=Math.round(point.y*30);body.position=point;return true;};
    body.getVelocity=function():Object{return velocity;};mouse["body"]=body;
    r.Keys.player_physics="body";r.Keys.bot_set_position="setPosition";r.Keys.b2vec2="Vector";r.Keys.get_linear_velocity="getVelocity";r.Keys.physics_state_vx="vx";r.Keys.physics_state_vy="vy";
    var mode:LegacyOptionsV2=new LegacyOptionsV2(r);var start:int=getTimer();mode.update(start);check(farm.getChildByName("sddsLegacy_teleport")!=null && farm.getChildByName("sddsLegacy_die")!=null,"six toggles present");
    var time:TextField=farm.getChildByName("sddsLegacyFarmTime") as TextField;check(time!=null && time.text=="5000","Farm Time default");var children:int=farm.numChildren;mode.update(start+100);check(farm.numChildren==children,"no duplicated controls");
    mode.teleport(12.4,22.7);check(calls.move==1 && calls.x==12 && calls.y==23,"teleport uses native body and rounds pixels");
    check(mouse.x==12 && mouse.y==23 && velocity.vx==0 && velocity.vy==0,"display and velocity agree with physics");
    check(Math.abs(body.position.x-12/30)<0.000001,"pixels converted to physics metres");
    body.locked=true;var blocked:Boolean=false;try{mode.teleport(99,99);}catch(locked:Error){blocked=true;}check(blocked && mouse.x==12 && calls.move==1,"locked physics cannot fake success");body.locked=false;
    var failed:Boolean=false;try{mode.teleport(Number.NaN,0);}catch(e:Error){failed=true;}check(failed && calls.move==1,"invalid teleport rejected");
    mode.keyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,70));check(calls.move==1,"disabled hotkey no-op");mode.keyUp(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,70));
    click(farm,"teleport");mode.keyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,70));mode.keyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,70));check(calls.move==2,"one action per key press");mode.keyUp(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,70));
    r.stage.focus=time;mode.keyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,70));check(calls.move==2,"typing does not teleport");mode.keyUp(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,70));r.stage.focus=r;
    click(farm,"fake");var expected:Point=mouse.parent.globalToLocal(new Point(r.stage.mouseX,r.stage.mouseY));mode.keyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,86));check(mouse.x==expected.x && mouse.y==expected.y && calls.move==2,"fake teleport changes only display");mode.keyUp(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,86));
    click(farm,"win");check(!r.insta_win && !r.insta_death2 && !r.insta_death,"legacy automation disables duplicate old flags");var now:int=getTimer();mode.update(now+100);check(calls.win==0,"farm delay enforced");mode.update(now+5100);check(calls.win==1,"Auto Win uses existing statement");mode.update(now+5200);check(calls.win==1,"no per-frame repeat");
    click(farm,"die");mode.update(now+10500);check(calls.win==1 && calls.die==1,"Auto Die excludes Auto Win");
    time.text="0";time.dispatchEvent(new Event(Event.CHANGE));mode.update(now+20000);check(calls.die==1,"zero interval rejected");time.text="5000";time.dispatchEvent(new Event(Event.CHANGE));mouse.dead=true;mode.update(now+26000);check(calls.die==1,"dead player no automation");
    mouse.dead=false;mode.update(now+30000);mode.update(now+34000);check(calls.die==1,"respawn resets delay");mode.update(now+35100);check(calls.die==2,"automation resumes after delay");click(farm,"die");
    var popup:MockNotification=new MockNotification();var icon:MockIcon=new MockIcon();popup.addChild(icon);game.addChild(popup);var unrelated:Sprite=new Sprite();var inventoryIcon:MockIcon=new MockIcon();unrelated.addChild(inventoryIcon);game.addChild(unrelated);
    click(farm,"inventory");mode.update(now+36000);check(!popup.visible && unrelated.visible && inventoryIcon.visible,"only received-item notification hidden");click(farm,"inventory");check(popup.visible,"notification restored on disable");
    var box:Sprite=new Sprite();box.graphics.beginFill(0xFFFFFF);box.graphics.drawRect(0,0,37,39);box.x=150;box.y=120;world.addChild(box);click(farm,"collect");var moves:int=calls.move;mode.update(now+37000);check(calls.move==moves+1,"Collect Box uses native movement");mode.update(now+37600);check(calls.move==moves+1,"box not collected repeatedly");click(farm,"collect");
    while(farm.numChildren)farm.removeChildAt(0);
    LegacyOptionsV2.attach(r);r.stage.dispatchEvent(new Event(Event.ENTER_FRAME));click(farm,"teleport");r.stage.focus=r;
    var bubbled:Boolean=false;var nativeHandler:Function=function(event:KeyboardEvent):void{bubbled=true;r.stage.focus=time;};r.stage.addEventListener(KeyboardEvent.KEY_DOWN,nativeHandler);
    moves=calls.move;r.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,70));check(calls.move==moves+1 && !bubbled,"production capture handles F before chat bubbling");
    r.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,70));check(calls.move==moves+1 && !bubbled,"holding F neither repeats teleport nor opens chat");
    r.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,70));r.stage.removeEventListener(KeyboardEvent.KEY_DOWN,nativeHandler);
    result="PASS: "+count+" teleport and legacy checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
