// ActionScript 3 / PerformanceTests.as / Ruffle AVM2 / retirement, frame measurement and native ping request checks
package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.events.MouseEvent;import flash.events.Event;import flash.text.TextField;import flash.external.ExternalInterface;
 public class RgbMouseTests {
  private static var count:int=0;
  private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  private static function row(y:Number):Sprite{var item:Sprite=new Sprite();item.y=y;item.graphics.beginFill(0);item.graphics.drawRect(0,0,100,24);return item;}
  private static function click(general:Sprite,id:String):void{var control:Sprite=general.getChildByName("sddsPerformance_"+id) as Sprite;control.getChildAt(0).dispatchEvent(new MouseEvent(MouseEvent.CLICK));}
  public static function run(display:MovieClip):void {
   var result:String;
   try{
    var root:MovieClip=new MovieClip();display.addChild(root);var original:Number=root.stage.frameRate;root["mass_reduction"]=true;root["change_movement_speed"]=true;root["ping"]=777;
    var general:Sprite=new Sprite();var mass:Sprite=row(10);mass.name="oldMass";var massBox:Sprite=new Sprite();mass.addChild(massBox);general.addChild(mass);
    var speed:Sprite=row(36);speed.name="oldSpeed";var speedBox:Sprite=new Sprite();speed.addChild(speedBox);general.addChild(speed);
    var other:Sprite=row(80);general.addChild(other);
    var shortcuts:Sprite=new Sprite();var m:Sprite=row(0);var mb:Sprite=new Sprite();m.addChild(mb);shortcuts.addChild(m);var s:Sprite=row(26);var sb:Sprite=new Sprite();s.addChild(sb);shortcuts.addChild(s);
    var me:Object={button:mb};var se:Object={button:sb};var keep:Object={};root["Interface"]={general_ui:general,keys_ui:shortcuts,mass_check_box:massBox,movement_check_box:speedBox,keys:{mass:me,movement:se,other:keep}};root["KeyboardHandler"]={shortcuts:{F9:me,"CTRL F1":se,Q:keep}};
    var sent:Array=[];var connection:Object={send:function(command:MockCommand):void{sent.push(command.command);}};
    root["Keys"]={player:"mouse",socket_class:{main:connection},main_socket_instance:"main",data_sender:"send",command_packet_class:MockCommand};root["tfm"]={mouse:{}};
    var chat:TextField=new TextField();chat.name="nativeChat";chat.text="Welcome";root.addChild(chat);
    var controller:PerformanceControls=new PerformanceControls(root);controller.update(0);
    check(!root.mass_reduction && !root.change_movement_speed,"retired flags disabled");
    check(general.getChildByName("oldMass")==null && general.getChildByName("oldSpeed")==null,"retired rows removed");
    check(root.Interface.keys.mass==null && root.Interface.keys.movement==null && root.Interface.keys.other===keep,"retired saved controls removed");
    check(root.KeyboardHandler.shortcuts.F9==null && root.KeyboardHandler.shortcuts["CTRL F1"]==null && root.KeyboardHandler.shortcuts.Q===keep && shortcuts.numChildren==0,"retired shortcut rows and bindings removed");
    check(other.y==172,"neighboring rows reflowed");
    var children:int=general.numChildren;controller.update(10);check(general.numChildren==children,"no duplicate performance rows");
    check(general.getChildByName("sddsPerformance_ping")!=null && general.getChildByName("sddsPerformance_fps")!=null && general.getChildByName("sddsPerformance_limit")!=null && general.getChildByName("sddsPerformance_unlock")!=null,"four controls created");
    check(sent.length==0,"ping off sends nothing");
    var limitRow:Sprite=general.getChildByName("sddsPerformance_limit") as Sprite;var input:TextField=limitRow.getChildAt(1) as TextField;input.text="30";input.dispatchEvent(new Event(Event.CHANGE));click(general,"limit");check(root.stage.frameRate==30,"30 FPS limit applied");
    click(general,"fps");for(var frame:int=1;frame<=59;frame++)controller.update(Math.round(frame*1000/59));
    click(general,"fps");click(general,"fps");var hud:TextField=root.stage.getChildByName("sddsPerformanceHud") as TextField;check(hud.visible && hud.text.indexOf("FPS: 60.0")>=0 && hud.text.indexOf("alvo 30")>=0,"FPS counts actual frames rather than configured limit");
    click(general,"unlock");check(root.stage.frameRate==120,"above-60 preset requests 120");
    click(general,"unlock");check(root.stage.frameRate==original,"original rate restored");
    input.text="90";input.dispatchEvent(new Event(Event.CHANGE));click(general,"limit");check(root.stage.frameRate==90,"custom rate above 60 supported");
    input.text="999";input.dispatchEvent(new Event(Event.CHANGE));check(input.text=="120" && root.stage.frameRate==120,"unsupported requested range capped");
    input.text="";input.dispatchEvent(new Event(Event.CHANGE));check(root.stage.frameRate==120,"editing empty FPS value preserves last valid rate");click(general,"limit");check(root.stage.frameRate==original,"disabling limiter restores original");
    check(PerformanceControls.isPingReply("Pong!") && PerformanceControls.isPingReply("Servidor: Ping: 45 ms"),"native ping reply patterns recognized");check(!PerformanceControls.isPingReply("Player: ping 45 ms") && !PerformanceControls.isPingReply("Mostrar ping"),"chat and menu text are not ping replies");
    click(general,"ping");controller.update(2000);check(sent.length==1 && sent[0]=="ping","native ping command sent: "+hud.text+" sent="+sent.length);chat.text+="\nPong!";controller.update(2300);check(hud.text.indexOf("300 ms")>=0 && hud.text.indexOf("777")<0,"ping measures request-response time without random value");
    controller.update(2500);check(sent.length==1,"ping rate limited");
    controller.update(12000);check(sent.length==2,"next ping after ten seconds");controller.update(20100);check(hud.text.indexOf("sem resposta")>=0,"missing reply reported honestly");
    click(general,"ping");controller.update(40000);check(sent.length==2,"disabling ping stops requests");
    click(general,"ping");controller.update(40100);controller.update(40300);check(hud.text.indexOf("medindo")>=0,"old Pong text does not satisfy a new request");click(general,"ping");click(general,"fps");check(!hud.visible,"HUD hidden when both displays off");
    result="PASS: "+count+" performance control checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
