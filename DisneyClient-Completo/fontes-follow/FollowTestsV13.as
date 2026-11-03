// ActionScript 3 / FollowTests.as / Ruffle AVM2 / live position, velocity, wall-jump trajectory and cancellation checks
package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.utils.ByteArray;import flash.events.KeyboardEvent;import flash.text.TextField;import flash.external.ExternalInterface;import flash.geom.Point;
 public class RgbMouseTests {
  private static var count:int=0;private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error(name);count++;}
  public static function run(display:MovieClip):void{
   var result:String;
   try{
    var r:MovieClip=new MovieClip();display.addChild(r);r.stage.focus=r.stage;var pressed:Object={};r.stage.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{pressed[e.keyCode]=true;});r.stage.addEventListener(KeyboardEvent.KEY_UP,function(e:KeyboardEvent):void{pressed[e.keyCode]=false;});
    var teleports:int=0;var lastPacket:ByteArray;var placements:Array=[];var body:Object={velocity:{vx:0,vy:0},place:function(p:Point,a:Number):Boolean{placements.push(p);return true;}};
    var local:Object={nick:"Self#0001",x:0,y:0,dead:false,body:body,down:false,side:false};var target:Object={nick:"Target#0000",x:345,y:180,dead:false,jumpActive:false,left:false,right:true,down:false,body:{velocity:{vx:3,vy:0}}};
    local.crouch=function(side:Boolean):void{};local.stand=function(side:Boolean):void{};
    r["Keys"]={is_jumping:"jumpActive",packet_handler_class:{receive:function(bytes:ByteArray):void{teleports++;lastPacket=bytes;}},packet_handler:"receive",map_class:{current:{number:{code:1}}},map_instance:"current",bot_map_code_object:"number",bot_map_code_value:"code",player:"self",player_list:"players",player_name:"nick",is_dead:"dead",player_physics:"body",bot_set_position:"place",physics_state:"velocity",physics_state_vx:"vx",physics_state_vy:"vy",app_domain:{applicationDomain:{getDefinition:function(n:String):Class{return Point;}}},b2vec2:"Point",player_moving_left:"left",player_moving_right:"right",is_down:"down",crouch:"crouch",crouch2:"stand",static_side:"side"};
    r["tfm"]={self:local,players:[{nick:"Target#0002",x:0,y:0},target]};r["auto_play"]=true;
    var follow:FollowControllerV13=new FollowControllerV13(r);check(!follow.command("/room abc"),"other commands unaffected");follow.command("/follow target#0000");follow.update(0);
    check(local.x==345 && local.y==180,"immediate exact target position");check(teleports==1 && lastPacket.readUnsignedByte()==8 && lastPacket.readUnsignedByte()==3,"initial native teleport applied");check(placements.length==1 && placements[0].x==11.5 && placements[0].y==6,"native physics coordinates scaled correctly");check(body.velocity.vx==0 && body.velocity.vy==0 && pressed[39],"coordinates do not overwrite velocity");check(!r.auto_play,"autoplay disabled");
    target.jumpActive=true;target.x=350;target.y=160;target.body.velocity.vx=-2;target.body.velocity.vy=-5;target.right=false;target.left=true;follow.update(20);check(local.x==350 && local.y==160 && pressed[37] && !pressed[39] && pressed[38],"live wall jump direction and rising trajectory");
    target.x=344;target.y=140;target.body.velocity.vx=2;target.right=true;target.left=false;follow.update(40);check(local.x==344 && local.y==140 && pressed[39] && !pressed[37],"wall jump reversal follows latest state without replay");
    target.jumpActive=false;target.body.velocity.vy=4;target.y=145;follow.update(60);check(!pressed[38] && body.velocity.vy==0,"native jump state releases without velocity writes");
    var input:TextField=new TextField();input.type="input";r.addChild(input);r.stage.focus=input;var before:int=placements.length;follow.update(100);check(placements.length==before && !pressed[39],"typing pauses synchronization");r.stage.focus=r.stage;
    local.dead=true;follow.update(120);check(placements.length==before,"death pauses synchronization");local.dead=false;target.x=500;follow.update(140);check(local.x==500,"respawn resynchronizes immediately");r.tfm.players=[];follow.update(160);check(!pressed[39],"absent target releases control");r.tfm.players=[target];target.x=600;follow.update(180);check(local.x==600,"returning target reacquired");
    follow.command("/follow off");target.x=700;follow.update(200);check(local.x==600 && !pressed[39],"off stops position and keys");follow.command("/follow Self#0001");follow.update(220);check(local.x==600,"self rejected");follow.command("/follow Target");follow.update(240);check(local.x==600,"discriminator required");
    follow.command("/follow Target#0000");body.place=function(p:Point,a:Number):Boolean{return false;};follow.update(260);check(local.x==600 && !pressed[39],"locked physics stops without visual-only teleport");
    body.place=function(p:Point,a:Number):Boolean{placements.push(p);return true;};follow.update(800);check(local.x==700 && teleports>=2,"temporary locked physics retries without clearing target");
    var initial:int=teleports;follow.update(820);check(teleports==initial,"initial teleport not resent each frame");
    r.Keys.map_class.current={number:{code:2}};target.x=800;follow.update(840);check(teleports==initial+1 && local.x==800,"new round synchronizes again");
    local.body=null;follow.update(860);target.x=900;local.body=body;follow.update(880);check(local.x==900 && teleports==initial+2,"body unavailable during spawn resumes automatically");
    var localSpace:Sprite=new Sprite();localSpace.x=50;localSpace.y=70;localSpace.scaleX=2;localSpace.scaleY=2;r.addChild(localSpace);
    var targetSpace:Sprite=new Sprite();targetSpace.x=250;targetSpace.y=170;r.addChild(targetSpace);
    var own:MovieClip=new MovieClip();own["nick"]="Self#0001";own["dead"]=false;own["body"]=body;own["down"]=false;localSpace.addChild(own);
    var remote:MovieClip=new MovieClip();remote["nick"]="Target#0000";remote["dead"]=false;remote["body"]=target.body;remote["left"]=false;remote["right"]=true;remote["down"]=false;remote.x=40;remote.y=60;targetSpace.addChild(remote);
    r.tfm.self=own;r.tfm.players=[remote];follow.update(900);check(own.x==120 && own.y==80,"different parent transforms converted to local world space");check(placements[placements.length-1].x==4 && Math.abs(placements[placements.length-1].y-80/30)<0.0001,"converted coordinates reach native physics");
    check(body.velocity.vx==0 && body.velocity.vy==0,"display conversion preserves velocity fields");
    var b:ByteArray=new ByteArray();b.writeByte(4);b.writeByte(4);b.writeInt(0);b.writeInt(1);b.writeBoolean(true);b.writeBoolean(false);b.writeInt(999999);b.writeInt(-999999);b.writeShort(0);b.writeShort(0);b.writeBoolean(false);b.writeByte(0);b.position=0;follow.packet(b,920);
    check(own.x==120 && own.y==80,"raw packet coordinates cannot replace v3 display mapping");
    remote.x=60;remote.y=80;follow.update(940);check(own.x==130 && own.y==90,"v3 coordinates refresh every frame without a new packet");
    result="PASS: "+count+" live follow checks";
   }catch(e:Error){result="FAIL: "+e.message+" #"+e.errorID;}
   ExternalInterface.call("recordTest",result);
  }
 }
}
