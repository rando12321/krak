// ActionScript 3 / PerformanceTests.as / Ruffle AVM2 / retirement, frame measurement and native ping request checks
package disney {
 import flash.geom.Rectangle;import flash.display.MovieClip;import flash.display.Sprite;import flash.events.MouseEvent;import flash.events.Event;import flash.text.TextField;import flash.external.ExternalInterface;
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
    var controller:PerformanceControlsV2=new PerformanceControlsV2(root);controller.update(0);
    check(!root.mass_reduction && !root.change_movement_speed,"retired flags disabled");
    check(general.getChildByName("oldMass")==null && general.getChildByName("oldSpeed")==null,"retired rows removed");
    check(root.Interface.keys.mass==null && root.Interface.keys.movement==null && root.Interface.keys.other===keep,"retired saved controls removed");
    check(root.KeyboardHandler.shortcuts.F9==null && root.KeyboardHandler.shortcuts["CTRL F1"]==null && root.KeyboardHandler.shortcuts.Q===keep && shortcuts.numChildren==0,"retired shortcut rows and bindings removed");
    check(other.y==28,"only retired rows reflowed; performance rows appended");
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
    check(PerformanceControlsV2.isPingReply("Pong!") && PerformanceControlsV2.isPingReply("Servidor: Ping: 45 ms"),"native ping reply patterns recognized");check(!PerformanceControlsV2.isPingReply("Player: ping 45 ms") && !PerformanceControlsV2.isPingReply("Mostrar ping"),"chat and menu text are not ping replies");
    click(general,"ping");controller.update(2000);check(sent.length==1 && sent[0]=="ping","native ping command sent: "+hud.text+" sent="+sent.length);chat.text+="\nPong!";controller.update(2300);check(hud.text.indexOf("300 ms")>=0 && hud.text.indexOf("777")<0,"ping measures request-response time without random value");
    controller.update(2500);check(sent.length==1,"ping rate limited");
    controller.update(12000);check(sent.length==2,"next ping after ten seconds");controller.update(20100);check(hud.text.indexOf("sem resposta")>=0,"missing reply reported honestly");
    click(general,"ping");controller.update(40000);check(sent.length==2,"disabling ping stops requests");
    click(general,"ping");controller.update(40100);controller.update(40300);check(hud.text.indexOf("medindo")>=0,"old Pong text does not satisfy a new request");click(general,"ping");click(general,"fps");check(!hud.visible,"HUD hidden when both displays off");
    var r2:MovieClip=new MovieClip();display.addChild(r2);var g2:Sprite=new Sprite();var shared:Sprite=new Sprite();g2.addChild(shared);
    var mass2:Sprite=row(0);var massBox2:Sprite=new Sprite();mass2.addChild(massBox2);shared.addChild(mass2);
    var speed2:Sprite=row(26);var speedBox2:Sprite=new Sprite();speed2.addChild(speedBox2);shared.addChild(speed2);
    var jump:Sprite=row(52);jump.name="highJump";var toggles:int=0;jump.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{toggles++;});shared.addChild(jump);
    var last:Sprite=row(500);last.name="lastPlayerOption";shared.addChild(last);
    r2.Keys={};r2.Interface={general_ui:g2,keys_ui:new Sprite(),mass_check_box:massBox2,movement_check_box:speedBox2,keys:{}};
    var second:PerformanceControlsV2=new PerformanceControlsV2(r2);second.update(0);
    check(shared.parent===g2 && jump.parent===shared && last.parent===shared,"native shared wrapper and other options preserved");
    check(mass2.parent==null && speed2.parent==null,"only exact retired rows removed inside wrapper");
    jump.dispatchEvent(new MouseEvent(MouseEvent.CLICK));check(toggles==1,"high jump original callback remains clickable");
    check(g2.getChildByName("sddsPerformance_ping").y>last.y,"FPS controls placed after native content");
    var viewport:Sprite=new Sprite();viewport.scrollRect=new Rectangle(0,0,535,232);r2.addChild(viewport);var options:Sprite=new Sprite();viewport.addChild(options);options.addChild(g2);r2.Interface.options_ui=options;
    var wheel:WheelScrollFixV2=new WheelScrollFixV2(r2);wheel.update();
    r2.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL,true,true,20,20,null,false,false,false,false,-100));
    check(viewport.scrollRect.y>200,"restored native options actually produce wheel overflow");
    check(jump.parent===shared && last.parent===shared,"scroll preparation keeps native high jump and last option");
    result="PASS: "+count+" performance control checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
