// ActionScript 3 / FollowTests.as / Ruffle AVM2 / normal movement without continuous physics writes or repeated teleports
package disney {
 import flash.display.MovieClip;import flash.events.KeyboardEvent;import flash.text.TextField;import flash.external.ExternalInterface;import flash.utils.ByteArray;
 public class RgbMouseTests {
  private static var count:int=0;private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  private static function signed(b:ByteArray):int{var v:int=0;var shift:int=0;var part:int;do{part=b.readUnsignedByte();v|=(part&127)<<shift;shift+=7;}while(part&128);if(shift<32 && (part&64))v|=(-1)<<shift;return v;}
  public static function run(display:MovieClip):void{
   var result:String;
   try{
    var r:MovieClip=new MovieClip();display.addChild(r);r.stage.focus=r.stage;var pressed:Object={};var jumpPresses:int=0;r.stage.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{pressed[e.keyCode]=true;if(e.keyCode==38)jumpPresses++;});r.stage.addEventListener(KeyboardEvent.KEY_UP,function(e:KeyboardEvent):void{pressed[e.keyCode]=false;});
    var body:Object={velocity:{vx:7,vy:9},place:function(p:Object,a:Number):void{throw new Error("Unexpected physics write");}};
    var local:Object={nick:"Self#0001",x:10,y:20,dead:false,clip:true,body:body};var target:Object={nick:"Target#0000",x:300,y:150,dead:false,clip:false,body:{velocity:{vx:2,vy:-8}}};var teleports:int=0;
    r["Keys"]={player:"self",player_list:"players",player_name:"nick",is_dead:"dead",player_clip:"clip",player_physics:"body",bot_set_position:"place",physics_state:"velocity",physics_state_vx:"vx",physics_state_vy:"vy",packet_handler_class:{receive:function(b:ByteArray):void{b.readUnsignedByte();b.readUnsignedByte();local.x=signed(b);local.y=signed(b);teleports++;}},packet_handler:"receive",map_class:{current:{number:{code:1}}},map_instance:"current",bot_map_code_object:"number",bot_map_code_value:"code"};
    r["tfm"]={self:local,players:[target]};var f:FollowControllerV9=new FollowControllerV9(r);f.command("/follow Target#0000");f.update(0);check(teleports==1 && local.x==300 && local.y==150,"single native initial teleport");check(!pressed[38],"rising velocity never triggers jump");
    target.x=400;target.y=50;f.update(20);check(local.x==300 && local.y==150,"target position not copied continuously");check(body.velocity.vx==7 && body.velocity.vy==9,"local velocity untouched");check(pressed[39] && !pressed[38] && teleports==1,"normal right movement without flight or repeated teleport");
    target.x=200;f.update(40);check(pressed[37] && !pressed[39],"normal left movement");target.x=302;f.update(60);check(!pressed[37] && !pressed[39],"distance deadzone");
    r.Keys.is_jumping="jumpActive";target.jumpActive=true;f.update(80);check(pressed[38],"known real jump state copied");f.update(90);check(jumpPresses==1,"held target jump produces one native key press");target.jumpActive=false;f.update(100);check(!pressed[38],"known jump release copied");
    var input:TextField=new TextField();input.type="input";r.addChild(input);r.stage.focus=input;f.update(120);r.stage.focus=r.stage;f.update(140);check(teleports==1,"typing does not rearm teleport");
    target.x=600;f.update(160);target.dead=true;f.update(180);check(!pressed[39] && teleports==1 && local.x==300,"target entering hole pauses without copying invalid coordinates");target.dead=false;f.update(200);check(pressed[39] && teleports==1,"target returns without repeated teleport");
    r.tfm.players=[];f.update(220);r.tfm.players=[target];f.update(240);check(teleports==1,"temporary target loss does not rearm teleport");
    local.dead=true;f.update(260);local.dead=false;f.update(280);check(teleports==2 && local.x==600,"respawn receives one synchronization");
    r.Keys.map_class.current={number:{code:2}};target.x=700;f.update(300);f.update(320);check(teleports==3 && local.x==700,"round change gets one synchronization");
    f.command("/follow off");target.x=900;f.update(340);check(teleports==3 && !pressed[39],"off releases controls");
    f.command("/follow Target#0000");target.dead=true;f.update(360);check(teleports==3,"command cannot teleport to player already in hole");target.dead=false;f.update(380);check(teleports==4,"pending first synchronization waits for live target");
    check(target.clip===false && teleports==4,"remote local-player flag false does not block following");
    f.keyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,27));f.update(400);check(!pressed[37] && !pressed[39] && !pressed[38],"escape stops controls");
    f.command("/follow Target#0000");f.update(420);r.Keys.player_moving_left="left";r.Keys.player_moving_right="right";target.left=false;target.right=true;f.update(440);check(pressed[39],"native direction starts movement at zero gap");
    target.left=true;target.right=false;f.update(460);check(pressed[37] && !pressed[39],"native reversal reacts without waiting for target gap");
    target.left=false;target.right=false;target.x=local.x+6;f.update(480);check(pressed[39],"six pixel gap already corrects position");
    target.x=local.x+2;f.update(500);check(!pressed[39] && !pressed[37],"small deadzone avoids idle jitter");
    check(body.velocity.vy==9,"latency adjustment does not modify vertical velocity");
    f.stop();f.command("/follow Target#0000");f.update(1000);var baseline:int=teleports;
    target.x=local.x;target.left=false;target.right=false;target.jumpActive=false;
    var packet:Function=function(id:int,l:Boolean,rgt:Boolean,j:Boolean):ByteArray{var b:ByteArray=new ByteArray();b.writeByte(4);b.writeByte(4);b.writeInt(id);b.writeInt(1);b.writeBoolean(rgt);b.writeBoolean(l);b.writeInt(0);b.writeInt(0);b.writeShort(0);b.writeShort(0);b.writeBoolean(j);b.writeByte(0);b.position=0;return b;};
    f.packet(packet(0,false,true,true),1010);check(pressed[39] && pressed[38],"incoming move reacts immediately without frame or visual update");
    f.update(1020);check(pressed[39] && pressed[38],"fresh wire state survives stale visual state");
    f.packet(packet(0,true,false,false),1030);check(pressed[37] && !pressed[39] && !pressed[38],"wire reversal and jump release immediate");
    f.packet(packet(0,false,false,false),1040);check(!pressed[37] && !pressed[39],"wire stop immediate");
    check(teleports==baseline && body.velocity.vx==7 && body.velocity.vy==9,"packet path never teleports or writes velocity");
    f.packet(packet(0,false,true,false),1050);f.update(1400);check(!pressed[39],"stale wire state falls back to normal controller");
    f.packet(packet(4,true,false,true),1410);check(!pressed[37] && !pressed[38],"unrelated packet ignored");
    f.stop();f.packet(packet(0,true,false,true),1420);check(!pressed[37] && !pressed[38],"off ignores packets");
    result="PASS: "+count+" normal-physics follow checks";
   }catch(e:Error){result="FAIL: "+e.message+" #"+e.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
