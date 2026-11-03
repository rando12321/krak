// ActionScript 3 / PhysicsGuardV2.as / Flash Player 10.3+ / repair legacy speed and mass operations without changing native packet handling
package disney {
 import flash.display.MovieClip;
 import flash.events.Event;
 import flash.events.IOErrorEvent;
 import flash.events.SecurityErrorEvent;
 import flash.net.URLLoader;
 import flash.net.URLRequest;
 import flash.net.URLRequestMethod;
 import flash.net.URLVariables;
 import flash.text.TextField;
 import flash.utils.Dictionary;
 import flash.utils.getTimer;
 public class PhysicsGuardV2 {
  private static var attached:Dictionary=new Dictionary(true);
  private var root:MovieClip;
  private var original:Object;
  private var states:Object={};
  private var requests:Array=[];
  private var lastAlive:Boolean=false;
  private var lastCheese:Boolean=false;
  public var message:String="Fisica original";
  public function PhysicsGuardV2(target:MovieClip){root=target;}
  public static function attach(target:MovieClip):void {
   if(!target || !target.stage || attached[target])return;
   var guard:PhysicsGuardV2=new PhysicsGuardV2(target);attached[target]=guard;
   target.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void{guard.update();});
  }
  private function report(feature:String,reason:String,code:int=0):void {
   var identity:String=feature+":"+reason+":"+code;
   if(states[feature]==identity)return;states[feature]=identity;
   message=feature+": "+reason+(code ? " #"+code : "");
   try {
    var data:URLVariables=new URLVariables();data.event="physics";data.code=code;data.channel="client";data.elapsed=getTimer();data.feature=feature;data.reason=reason;
    var flags:Array=[];for each(var name:String in ["auto_play","recording","change_movement_speed","mass_reduction","insta_death","insta_win","no_delay","macro"])if(root[name])flags.push(name);data.options=flags.join(",");
    var request:URLRequest=new URLRequest(root["host_url"]+"client_diagnostics?access_token="+encodeURIComponent(String(root["access_token"]))+"&flash_token="+encodeURIComponent(String(root["tfmdisney"].data.flash_token)));
    request.method=URLRequestMethod.POST;request.data=data;
    var loader:URLLoader=new URLLoader();requests.push(loader);
    var release:Function=function(event:Event):void{var i:int=requests.indexOf(loader);if(i>=0)requests.splice(i,1);};
    loader.addEventListener(Event.COMPLETE,release);loader.addEventListener(IOErrorEvent.IO_ERROR,release);loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,release);loader.load(request);
   }catch(ignored:Error){}
  }
  private function disable(feature:String,k:Object,code:int):void {
   var field:String=feature=="mass" ? "mass_reduction" : "change_movement_speed";root[field]=false;
   try {
    var ui:Object=root["Interface"];var input:Object=ui[feature=="mass" ? "mass_input" : "movement_input"];
    for each(var item:Object in ui["keys"])if(item.ui_input===input && item.ui && item.ui[k.is_selected])item.ui[k.check_button_exec](new flash.events.MouseEvent("mouseDown"));
   }catch(ignored:Error){}
   report(feature,"fault",code);
   var status:TextField=root.stage ? root.stage.getChildByName("sddsConnectionStatus") as TextField : null;
   if(status)status.text=(feature=="mass" ? "Reduzir massa" : "Velocidade")+": desligada por falha local #"+code+" | consulte o diagnostico";
  }
  private function setMass(k:Object,body:Object,mass:Number,inertia:Number,x:Number,y:Number):void {
   var Mass:Class=k.mass_data_class as Class;var VectorType:Class=k.app_domain.applicationDomain.getDefinition(String(k.b2vec2)) as Class;
   var data:Object=new Mass();data[k.mass_data_mass]=mass;data[k.mass_data_inertia]=inertia;data[k.mass_data_center]=new VectorType(x,y);body[k.mass_set](data);
  }
  private function restore(k:Object):Boolean {
   if(!original)return true;
   var value:Object=original;
   try {
    var current:Number=Number(value.body[k.mass_body_mass]);
    var expected:Number=value.reduction<0 ? value.mass : value.mass*(1-value.reduction/100);
    if(Math.abs(current-expected)>0.00001 && (value.pendingMass==null || Math.abs(current-Number(value.pendingMass))>0.00001)) {
     original=null;report("mass","native_mass_changed");return true;
    }
    setMass(k,value.body,value.mass,value.inertia,value.x,value.y);
    if(Math.abs(Number(value.body[k.mass_body_mass])-value.mass)>0.00001){report("mass","restore_pending");return false;}
    original=null;report("mass","restored");return true;
   }catch(error:Error){report("mass","restore_pending",error.errorID);return false;}
  }
  private function applyMass(k:Object,p:Object,body:Object):void {
   for each(var key:String in ["mass_data_class","mass_set","mass_body_mass","mass_body_inertia","mass_data_mass","mass_data_inertia","mass_data_center","mass_body_sweep","mass_sweep_center"])if(!k[key])throw new Error("Mass mapping unavailable",2013);
   if(original && original.body!==body){if(!restore(k)){original=null;report("mass","old_body_removed");}}
   if(!original) {
    var center:Object=body[k.mass_body_sweep][k.mass_sweep_center];
    original={body:body,mass:Number(body[k.mass_body_mass]),inertia:Number(body[k.mass_body_inertia]),x:Number(center[k.pos_x]),y:Number(center[k.pos_y]),reduction:-1,pendingMass:null};
    if(!isFinite(original.mass)||original.mass<=0||!isFinite(original.inertia)||!isFinite(original.x)||!isFinite(original.y)){original=null;throw new Error("Invalid body",2013);}
   }
   var ui:Object=root["Interface"];if(!ui || !ui["mass_input"])return;
   var reduction:Number=Number(String(ui["mass_input"][k.text_field].text).replace(",","."));
   if(!isFinite(reduction)||reduction<0||reduction>=100)throw new Error("Invalid reduction",2014);
   if(reduction!=original.reduction) {
    var ratio:Number=1-reduction/100;original.pendingMass=original.mass*ratio;setMass(k,body,original.mass*ratio,original.inertia*ratio,original.x,original.y);
    if(Math.abs(Number(body[k.mass_body_mass])-original.mass*ratio)<0.00001){original.reduction=reduction;original.pendingMass=null;report("mass","enabled");}
   }
  }
  private function applySpeed(k:Object,p:Object,body:Object):void {
   if(!k.player_moving_left || !k.player_moving_right || !(k.player_moving_left in p) || !(k.player_moving_right in p))throw new Error("Direction mapping unavailable",2011);
   var velocity:Object=null;
   if(k.get_linear_velocity && body[k.get_linear_velocity] is Function)velocity=body[k.get_linear_velocity]();
   else if(k.physics_state && k.physics_state in body)velocity=body[k.physics_state];
   if(!velocity)throw new Error("Velocity vector unavailable",2011);
   if(!velocity || !k.physics_state_vx || !(k.physics_state_vx in velocity))throw new Error("Velocity field unavailable",2011);
   var ui:Object=root["Interface"];if(!ui || !ui["movement_input"])return;
   var speed:Number=Number(String(ui["movement_input"][k.text_field].text).replace(",","."));
   if(!isFinite(speed)||speed<=0)throw new Error("Invalid speed",2012);
   var current:Number=Number(velocity[k.physics_state_vx]);if(!isFinite(current))throw new Error("Invalid velocity",2011);
   if(p[k.player_moving_left] && current>-speed)velocity[k.physics_state_vx]=Math.max(-speed,current-0.1);
   else if(p[k.player_moving_right] && current<speed)velocity[k.physics_state_vx]=Math.min(speed,current+0.1);
   report("speed","enabled");
  }
  public function update():void {
   var k:Object=root["Keys"];if(!k || !root["tfm"] || !k.player)return;
   try {
    var p:Object=root["tfm"][k.player];
    var alive:Boolean=Boolean(p && k.player_clip && p[k.player_clip] && !p[k.is_dead]);
    var cheese:Boolean=Boolean(p && k.player_cheese && p[k.player_cheese]);
    if(lastAlive && !alive)report("round",lastCheese ? "left_with_cheese" : "left_without_cheese");
    lastAlive=alive;lastCheese=cheese;
    if(!alive || cheese) {
     var restored:Boolean=restore(k);
     if(root["mass_reduction"] && restored)report("mass",!alive ? "paused_dead" : "paused_cheese");
     if(root["change_movement_speed"])report("speed",!alive ? "paused_dead" : "paused_cheese");
     return;
    }
    var body:Object=p[k.player_physics];if(!body)return;
    if(original && original.body!==body && !restore(k)){original=null;report("mass","old_body_removed");}
    if(root["mass_reduction"]) {
     try{applyMass(k,p,body);}catch(error:Error){restore(k);disable("mass",k,error.errorID);}
    }else {if(restore(k) && states.mass && states.mass!="mass:off:0")report("mass","off");}
    if(root["change_movement_speed"]) {
     try{applySpeed(k,p,body);}catch(error:Error){disable("speed",k,error.errorID);}
    }else if(states.speed && states.speed!="speed:off:0")report("speed","off");
   }catch(error:Error){if(root["mass_reduction"])disable("mass",k,error.errorID);if(root["change_movement_speed"])disable("speed",k,error.errorID);}
  }
 }
}
