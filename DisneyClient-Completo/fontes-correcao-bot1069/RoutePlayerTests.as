package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.text.TextField;import flash.geom.Point;import flash.utils.ByteArray;
 import flash.utils.setTimeout;import flash.events.Event;import flash.events.KeyboardEvent;import flash.events.MouseEvent;import flash.external.ExternalInterface;
 public class RoutePlayerTests {
  private static var count:int=0;private static var host:MovieClip;private static var previous:Object;
  private static var capturedPacket:ByteArray;
  private static var capturedChannel:String;
  public static function captureNative(target:MovieClip,bytes:ByteArray,channel:String):void{capturedPacket=bytes;capturedChannel=channel;}
  private static function check(value:Boolean,name:String):void{if(!value)throw new Error("FAIL: "+name);count++;}
  private static function walk(x:Number,delay:Number,vx:Number=200,right:Boolean=true,left:Boolean=false):Array{return [{x:0,y:0,vx:vx,vy:-100,mr:right,ml:left,jump:true,frame:7},"walk",delay];}
  private static function victory(id:int=42,order:int=1):ByteArray{var b:ByteArray=new ByteArray();b.writeByte(8);b.writeByte(6);b.writeByte(0);b.writeInt(id);b.writeShort(100);b.writeByte(order);b.writeShort(1500);b.position=0;return b;}
  private static function death(id:int=42):ByteArray{var b:ByteArray=new ByteArray();b.writeByte(1);b.writeByte(1);b.writeUTF(String.fromCharCode(8,5)+String.fromCharCode(1)+id+String.fromCharCode(1)+"1");b.position=0;return b;}
  private static function respawn(id:int=42):ByteArray{var b:ByteArray=new ByteArray();b.writeByte(144);b.writeByte(2);b.writeUTF("Player");b.writeInt(id);b.position=0;return b;}
  private static function fixture():Object {
   if(previous){previous.root.auto_play=false;previous.robot.advance(999999);if(previous.root.parent)previous.root.parent.removeChild(previous.root);}
   var r:MovieClip=new MovieClip();host.addChild(r);var events:Array=[];var inputs:Object={};var placements:Array=[];var animationCalls:int=0;var sent:int=0;
   var render:Object={scaleX:2,currentFrame:1,totalFrames:4,currentLabels:[{name:"Course",frame:1},{name:"Statique",frame:2},{name:"Saut",frame:3}]};
   var animate:Function=function(...args):void{animationCalls++;};render.gotoAndPlay=animate;render.gotoAndStop=animate;render.play=animate;render.stop=animate;
   var body:Object={position:{x:0,y:0},velocity:{vx:0,vy:0},locked:false};
   body.setPosition=function(p:Point,angle:Number):Boolean{if(body.locked)return false;body.position.x=p.x;body.position.y=p.y;placements.push({x:p.x,y:p.y});return true;};body.getForm=function():Object{return {position:body.position};};
   body.setPosition=function(...args):Boolean{throw new Error("forbidden physical write");};
   var player:Object={id:42,x:0,y:0,body:body,clip:render,dead:false,left:false,right:false,down:false,side:true};
   player.jump=animate;player.run=animate;player.idle=animate;player.crouch=animate;player.stand=animate;
   var map:Object={codeObject:{number:123},container:{mirror:false}};
   var keys:Object={bot_map_code_object:"codeObject",bot_map_code_value:"number",bot_reverse:"mirror",bot_map_width:"width",player_physics:"body",map_class:{instance:map,width:800},map_instance:"instance",player:"mouse",player_id:"id",frame_loop_class:{victoryTime:0},victory_time:"victoryTime",player_clip:"clip",is_dead:"dead",obj_container:"container",move_class:{free:true},move_free:"free",timer_class:{locked:false},timer_prop:"locked",player_moving_left:"left",player_moving_right:"right",jump:"jump",animation_course:"run",static_animation:"idle",is_down:"down",crouch:"crouch",crouch2:"stand",static_side:"side",text_field:"field",get_x_form:"getForm",pos_x:"x",pos_y:"y",bot_set_position:"setPosition",physics_state:"velocity",physics_state_vx:"vx",physics_state_vy:"vy",b2vec2:"Point",app_domain:{applicationDomain:{getDefinition:function(name:String):Class{return Point;}}},maps:{}};
   var delay:TextField=new TextField();delay.text="0";r.Keys=keys;var game:MovieClip=new MovieClip();game.mouse=player;r.addChild(game);r.tfm=game;r.auto_play_disable_on_move=true;
   var keyboard:Function=function(event:KeyboardEvent):void{events.push({code:event.keyCode,down:event.type==KeyboardEvent.KEY_DOWN,target:event.target===game});inputs[event.keyCode]=event.type==KeyboardEvent.KEY_DOWN;};game.addEventListener(KeyboardEvent.KEY_DOWN,keyboard);game.addEventListener(KeyboardEvent.KEY_UP,keyboard);r.auto_play=true;r.no_delay=true;r.last_victory_order=1;r.last_victory_time=0;r.current_round_code=99;
   r.Interface={status_field:new TextField(),bot_delay_input:{field:delay}};
   r.Statements={disable_auto_play:function():void{},send_hole_packet:function():void{sent++;},send_cheese_packet:function():void{sent++;}};
   keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([walk(1000,0),walk(2000,1000,-200,false,true),["hole",1000]]);
   var native:Object={delivered:0,dropped:0,calls:0,flags:[],throwError:false,packet:null,channel:""};
   r.sddsNativeHandlePacket=function(bytes:ByteArray,channel:String):void{
    native.calls++;native.flags.push(r.no_delay);native.packet=bytes;native.channel=channel;
    if(native.throwError)throw new Error("native test fault",2099);
    if(bytes && bytes.length>=12 && bytes[0]==8 && bytes[1]==6){
     var copy:ByteArray=new ByteArray();copy.writeBytes(bytes,0,bytes.length);copy.position=9;var order:int=copy.readUnsignedByte();
     // Reproduce the exact no_delay / duplicate-order filter from MainTimeline.
     if(r.no_delay && order==r.last_victory_order){native.dropped++;return;}
    }
    native.delivered++;
    if(bytes && bytes.length>=12 && bytes[0]==8 && bytes[1]==6)keys.frame_loop_class.victoryTime=12345;
   };
   previous={root:r,events:events,inputs:inputs,keys:keys,body:body,player:player,map:map,render:render,placements:placements,native:native,robot:new RoutePlayerFixed1069(r),animations:function():int{return animationCalls;},sent:function():int{return sent;}};return previous;
  }
  private static var corpusState:Object;
  private static var corpusField:TextField;
  private static function runCorpusBatch():void {
   var result:String;
   try{
    var end:int=Math.min(int(corpusState.total),int(corpusState.index)+25);
    while(int(corpusState.index)<end){
     var raw:String=String(ExternalInterface.call("getRecordedRoute",int(corpusState.index)));
     var route:Array=RoutePlayerFixed1069.decodeRoute(raw);corpusState.steps+=route.length;
     var motion:Array=RoutePlayerFixed1069.buildTrajectory(route);var converted:Array=RoutePlayerFixed1069.convertKeyboardPlan(route,motion.length ? Number(motion[0].point.x)*0.3 : 0,motion.length ? Number(motion[0].point.y)*0.3 : 0,false,800);ExternalInterface.call("recordConvertedRoute",int(corpusState.index),com.adobe.serialization.json.JSON.encode(converted));for each(var task:Object in converted){corpusState.checkpoints+=task.checks.length;if(!isFinite(task.holdMs) || task.holdMs<0 || [-1,0,1].indexOf(int(task.direction))<0)corpusState.finite=false;}var plan:Array=RoutePlayerFixed1069.buildJumpPlan(route,Number(motion["gravity"]));corpusState.walks+=motion.length;if(motion.length==0)corpusState.empty++;
     for(var i:int=0;i<motion.length;i++){
      if(i>0){if(Number(motion[i].time)<Number(motion[i-1].time))corpusState.ordered=false;if(Boolean(motion[i-1].point.jump) && Boolean(motion[i].point.jump) && RoutePlayerFixed1069.requiresJumpEdge(motion[i-1].point,motion[i].point,Number(motion[i].time)-Number(motion[i-1].time)))corpusState.repeats++;}
      var sample:Object=RoutePlayerFixed1069.sampleTrajectory(motion,Number(motion[i].time),false,800);
      if(!isFinite(sample.x) || !isFinite(sample.y) || !isFinite(sample.vx) || !isFinite(sample.vy))corpusState.finite=false;
      if(i+1<motion.length){sample=RoutePlayerFixed1069.sampleTrajectory(motion,(Number(motion[i].time)+Number(motion[i+1].time))/2,false,800);if(!isFinite(sample.x) || !isFinite(sample.y) || !isFinite(sample.vx) || !isFinite(sample.vy))corpusState.finite=false;}
     }
     for(i=1;i<plan.length;i++)if(Number(plan[i].time)<Number(plan[i-1].time))corpusState.planOrdered=false;
     corpusState.index++;
    }
    if(int(corpusState.index)%100==0 || int(corpusState.index)==int(corpusState.total))ExternalInterface.call("recordCorpusProgress",int(corpusState.index));
    if(int(corpusState.index)<int(corpusState.total)){setTimeout(runCorpusBatch,0);return;}
    check(corpusState.total==2205 && corpusState.steps==165019,"all supplied routes execute the actual AS3 decoder and planner");
    check(corpusState.walks==160217 && corpusState.empty==3,"supplied motion and marker-only routes retain original counts");
    check(corpusState.ordered && corpusState.planOrdered && corpusState.finite,"all supplied endpoints and midpoints remain ordered and finite");
    check(corpusState.checkpoints==160217,"converted plans retain every supplied motion checkpoint");
    check(corpusState.repeats==268,"supplied vy profiles expose repeated takeoffs missed by flag-only playback");
    result="PASS: "+count+" AVM2 assertions; 32 legacy + 2205 supplied routes; internal-keyboard plans validated";
   }catch(error:Error){result="FAIL: corpus route "+corpusState.index+" "+error.message+" #"+error.errorID;}
   corpusField.text=result;trace(result);ExternalInterface.call("recordTest",result);
  }
  public static function run(display:MovieClip):void {host=display;var result:String;
   try{
    ExternalInterface.call("recordTestStage","converter");
    var a:Object={x:0,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};var b:Object={x:345,y:0,vx:345,vy:0,jump:false,mr:false,ml:true,frame:0};var route:Array=[[a,"walk",0],[b,"walk",200],["hole",100]];var original:String=com.adobe.serialization.json.JSON.encode(route);
    var converted:Array=RoutePlayerFixed1069.convertKeyboardPlan(route,0,0,false,800);var move:Object=null;for each(var task:Object in converted)if(task.kind=="move")move=task;
    check(move && move.direction==1 && Math.abs(move.holdMs-1000)<0.01,"103.5px of recorded displacement converts to one second of normal right input, not the old 200ms");check(com.adobe.serialization.json.JSON.encode(route)==original,"conversion never edits the source route");
    var reflected:Array=RoutePlayerFixed1069.convertKeyboardPlan(route,800,0,true,800);var mirrorMove:Object=null;for each(task in reflected)if(task.kind=="move")mirrorMove=task;check(mirrorMove.direction==-1 && Math.abs(mirrorMove.holdMs-move.holdMs)<0.01,"reflection converts physical displacement to left without changing its duration");
    check(RoutePlayerFixed1069.recordedVelocity(65036)==-150,"unsigned vy is decoded with its signed physical value");
    ExternalInterface.call("recordTestStage","internal-controller");
    var f:Object=fixture();a={x:0,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};b={x:100,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);var syntheticEvents:int=0;f.root.tfm.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{syntheticEvents++;});f.robot.advance(0);ExternalInterface.call("recordTestStage","internal-events-ready");f.robot.advance(300);check(f.inputs[39] && !f.inputs[37],"converted movement delivers RIGHT to the internal game keyboard path");check(syntheticEvents>0 && f.events[0].target,"keyboard input is dispatched inside the game SWF and bubbles through its event path");check(f.root.auto_play_disable_on_move,"generated internal events preserve the manual-pause setting");f.robot.advance(400);check(f.inputs[39] && f.robot.currentStep<f.robot.waypointCount,"old timer expiry does not confirm arrival at an unreached target");f.body.position.x=1;f.robot.advance(600);check(f.robot.message.indexOf("checks falhos=0")>=0 || f.robot.currentStep>=1,"observed arrival advances without a failed check");check(f.placements.length==0 && f.body.velocity.vx==0 && f.player.x==0,"checks and input never write physical state");
    f=fixture();a={x:0,y:0,vx:345,vy:0,jump:false,mr:false,ml:true,frame:0};b={x:-100,y:0,vx:65191,vy:0,jump:false,mr:true,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);check(f.inputs[37] && !f.inputs[39],"left input comes from negative target displacement instead of contradictory mr flag");
    f=fixture();a={x:0,y:0,vx:0,vy:0,jump:false,mr:false,ml:false,frame:0};b={x:0,y:-100,vx:0,vy:-250,jump:true,mr:false,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);check(f.inputs[38],"vertical converted task sends an internal UP event to the game");f.robot.advance(350);check(f.inputs[38],"up remains held for its minimum physical impulse");f.robot.advance(390);check(!f.inputs[38],"up is released after the converted tap duration");f.body.position.y=-1;f.robot.advance(420);check(f.robot.currentStep>=1,"airborne target uses observed vertical arrival");
    f=fixture();a={x:0,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};b={x:100,y:0,vx:345,vy:65036,jump:true,mr:true,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);check(f.inputs[39] && !f.inputs[38],"robot walks to a fresh takeoff point before pressing up");f.body.position.x=1;f.robot.advance(600);check(f.inputs[38] && !f.inputs[39],"confirmed launch position triggers a internal up key");f.body.velocity.vy=-5;f.body.position.y=-0.1;f.robot.advance(700);check(!f.inputs[38] && f.robot.currentStep>=3,"launch checkpoint requires an observed impulse before progressing");
    f=fixture();a={x:0,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};b={x:100,y:-100,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);f.body.position.x=1;f.robot.advance(400);check(f.robot.currentStep<f.robot.waypointCount && !f.inputs[37],"wrong height cannot count as arrival or invent backward steering");f.robot.advance(6000);check(f.robot.message.indexOf("nao confirmados")>=0 || f.robot.message.indexOf("checks falhos=1")>=0,"blocked task is reported as unconfirmed rather than silently marked arrived");
    f=fixture();f.root.host_url="http://backend-not-required.invalid/";a={x:0,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};b={x:1000,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);check(f.inputs[39] && f.events.length>0,"internal keyboard requires no Windows driver or HTTP input bridge");f.root.tfm.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,37));check(!f.inputs[39] && f.robot.message.indexOf("pausado")>=0,"real manual input still pauses generated internal controls");

    f=fixture();delete f.body.getForm;f.player.x=Number.NaN;f.player.y=Number.NaN;f.robot.advance(0);f.robot.advance(300);check(f.events.length==0 && f.robot.message.indexOf("posicao")>=0,"arrival-checked conversion waits for a valid live position");
    f=fixture();a={x:0,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};b={x:1000,y:0,vx:345,vy:0,jump:false,mr:true,ml:false,frame:0};f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);f.root.auto_play=false;f.robot.advance(350);check(!f.inputs[37] && !f.inputs[38] && !f.inputs[39],"disabling robot releases internal held keys");
    f=fixture();f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([[a,"walk",0],[b,"walk",100],["hole",100]]);f.robot.advance(0);f.robot.advance(300);f.robot.stopForDisconnect("bulle","close");check(!f.inputs[37] && !f.inputs[38] && !f.inputs[39],"disconnect immediately releases internal keys before removing frame handler");
    var raw:ByteArray=new ByteArray();raw.writeByte(0);raw.writeByte(0);display["handle_packet"](raw,"main");check(capturedPacket===raw && capturedChannel=="main","native packet wrapper remains intact");
    var routes:Array=ExternalInterface.call("getRoutes") as Array;for each(var saved:String in routes)RoutePlayerFixed1069.decodeRoute(saved);check(routes.length==32,"32 legacy formats still decode");
    result="PASS: core converted-keyboard checks";
   }catch(error:Error){result="FAIL: "+error.message+" #"+error.errorID;}
   var field:TextField=new TextField();field.width=780;field.height=400;field.text=result;display.addChild(field);
   if(result.indexOf("PASS:")==0){corpusField=field;corpusState={index:0,total:int(ExternalInterface.call("getRecordedRouteCount")),walks:0,steps:0,repeats:0,empty:0,checkpoints:0,finite:true,ordered:true,planOrdered:true};setTimeout(runCorpusBatch,0);}else{trace(result);ExternalInterface.call("recordTest",result);}
  }
 }
}
