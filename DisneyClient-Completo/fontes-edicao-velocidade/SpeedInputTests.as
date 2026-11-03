// ActionScript 3 / RoutePlayerTests.as / Ruffle AVM2 / focused regression tests for the uploaded client's physics guard
package disney {
 import flash.display.MovieClip;
 import flash.text.TextField;
 import flash.geom.Point;
 import flash.external.ExternalInterface;
 public class RoutePlayerTests {
  private static var count:int=0;
  private static function check(ok:Boolean,name:String):void{if(!ok)throw new Error("FAIL: "+name);count++;}
  private static function fixture():Object {
   var r:MovieClip=new MovieClip();var body:Object={mass:10,inertia:4,velocity:{vx:1,vy:0},sweep:{center:{vx:1,vy:2}},writes:0,locked:false};
   var p:Object={body:body,clip:true,dead:false,cheese:false,left:false,right:true};
   body.getVelocity=function():Object{return body.velocity;};
   body.setMass=function(data:MockMassData):void {if(body.locked)return;body.writes++;body.mass=data.mass;body.inertia=data.inertia;body.sweep.center={vx:data.center.x,vy:data.center.y};};
   var keys:Object={player:"mouse",player_clip:"clip",is_dead:"dead",player_cheese:"cheese",player_physics:"body",player_moving_left:"left",player_moving_right:"right",get_linear_velocity:"getVelocity",physics_state_vx:"vx",physics_state_vy:"vy",mass_data_class:MockMassData,mass_set:"setMass",mass_body_mass:"mass",mass_body_inertia:"inertia",mass_data_mass:"mass",mass_data_inertia:"inertia",mass_data_center:"center",mass_body_sweep:"sweep",mass_sweep_center:"center",pos_x:"vx",pos_y:"vy",b2vec2:"Point",app_domain:{applicationDomain:{getDefinition:function(name:String):Class{return Point;}}},text_field:"field"};
   var mass:TextField=new TextField();mass.text="2";var speed:TextField=new TextField();speed.text="3.45";
   r["Keys"]=keys;r["tfm"]={mouse:p};r["Interface"]={keys:{},mass_input:{field:mass},movement_input:{field:speed}};
   r["mass_reduction"]=false;r["change_movement_speed"]=false;
   for each(var flag:String in ["auto_play","recording","insta_death","insta_win","no_delay","macro"])r[flag]=false;
   return {root:r,keys:keys,body:body,player:p,mass:mass,speed:speed,guard:new PhysicsGuardV4(r)};
  }
  public static function run(display:MovieClip):void {
   var result:String;
   try {
    var fallback:Object=fixture();delete fallback.keys.get_linear_velocity;fallback.keys.physics_state="velocity";fallback.root.change_movement_speed=true;fallback.body.velocity.vy=7;fallback.guard.update();check(Math.abs(fallback.body.velocity.vx-1.1)<0.00001 && fallback.body.velocity.vy==7,"typed native vector fallback changes only horizontal velocity");
    fallback=fixture();fallback.body.velocity.vx=3.45;fallback.root.change_movement_speed=true;fallback.guard.update();check(fallback.body.velocity.vx==3.45,"3.45 is unchanged when already at normal speed");
    fallback.speed.text="5,0";for(var step:int=0;step<30;step++)fallback.guard.update();check(Math.abs(fallback.body.velocity.vx-5)<0.00001,"higher target increases and caps speed");
        var capped:Object=fixture();capped.speed.text="57,35";capped.guard.update();check(capped.speed.text=="9.9" && capped.body.velocity.vx==1,"oversized saved input corrected even when option disabled");
    capped=fixture();capped.speed.text="57.35";capped.body.velocity.vx=57.35;capped.root.change_movement_speed=true;capped.guard.update();check(capped.speed.text=="9.9" && capped.body.velocity.vx<=9.9,"old excessive positive speed capped");
    capped=fixture();capped.speed.text="99";capped.player.left=true;capped.player.right=false;capped.body.velocity.vx=-50;capped.root.change_movement_speed=true;capped.guard.update();check(capped.body.velocity.vx>=-9.9,"old excessive negative speed capped");
    capped=fixture();capped.speed.text="9,9";capped.body.velocity.vx=9.85;capped.root.change_movement_speed=true;capped.guard.update();check(Math.abs(capped.body.velocity.vx-9.9)<0.000001,"9.9 accepted without acceleration overshoot");
    capped=fixture();capped.speed.text="5.0";capped.guard.update();check(capped.speed.text=="5.0","lower configured values retained");
        var editing:Object=fixture();editing.root.change_movement_speed=true;editing.speed.text="";editing.guard.update();check(editing.root.change_movement_speed && editing.body.velocity.vx==1,"empty field keeps checkbox enabled without acceleration");
    editing.speed.text="0";editing.guard.update();check(editing.root.change_movement_speed && editing.body.velocity.vx==1,"zero during editing pauses without fault");
    editing.speed.text="5.0";editing.guard.update();check(editing.root.change_movement_speed && Math.abs(editing.body.velocity.vx-1.1)<0.00001,"valid input resumes acceleration automatically");
        var f:Object=fixture();f.guard.update();check(f.body.writes==0,"disabled guard leaves body untouched");
    f.root.change_movement_speed=true;f.guard.update();check(Math.abs(f.body.velocity.vx-1.1)<0.00001,"right movement uses validated getter");
    f.player.right=false;f.player.left=true;f.guard.update();check(Math.abs(f.body.velocity.vx-1)<0.00001,"left movement sign correct");
    f.speed.text="1,05";f.player.left=false;f.player.right=true;f.guard.update();check(Math.abs(f.body.velocity.vx-1.05)<0.00001,"decimal comma and no speed overshoot");
    f.player.right=false;f.guard.update();check(Math.abs(f.body.velocity.vx-1.05)<0.00001,"no movement does not accelerate");
    f=fixture();f.root.change_movement_speed=true;delete f.keys.player_moving_left;f.guard.update();check(!f.root.change_movement_speed,"missing movement symbol disables only speed without 1069");
    f=fixture();f.root.change_movement_speed=true;f.speed.text="bad";f.guard.update();check(f.root.change_movement_speed && f.body.velocity.vx==1,"invalid speed pauses without disabling or writing");
    f=fixture();f.root.mass_reduction=true;f.guard.update();check(f.body.mass==9.8 && f.body.inertia==3.92,"two percent means two percent less mass and inertia");
    check(f.body.sweep.center.vx==1 && f.body.sweep.center.vy==2,"mass change preserves local center");
    var writes:int=f.body.writes;f.guard.update();check(f.body.writes==writes,"mass is not rewritten every frame");
    f.mass.text="25";f.guard.update();check(f.body.mass==7.5 && f.body.inertia==3,"changed reduction uses original baseline");
    f.root.mass_reduction=false;f.guard.update();check(f.body.mass==10 && f.body.inertia==4,"off restores original body properties");
    f=fixture();f.root.mass_reduction=true;f.mass.text="100";f.guard.update();check(!f.root.mass_reduction && f.body.mass==10,"zero mass is rejected and original retained");
    f=fixture();f.root.mass_reduction=true;f.root.change_movement_speed=true;f.guard.update();f.player.cheese=true;var velocity:Number=f.body.velocity.vx;f.guard.update();
    check(f.body.mass==10 && f.body.inertia==4,"cheese restores mass before hole processing");check(f.body.velocity.vx==velocity,"cheese suspends speed writes");
    f.player.dead=true;f.guard.update();check(f.body.mass==10 && f.guard.message.indexOf("paused_dead")>=0,"dead player is not modified");
    f.player.dead=false;f.player.cheese=false;f.guard.update();check(f.body.mass==9.8,"new life resumes enabled mass control");
    f=fixture();f.root.mass_reduction=true;f.guard.update();f.body.locked=true;f.root.mass_reduction=false;f.guard.update();check(f.body.mass==9.8,"locked body does not fake a successful restore");
    f.body.locked=false;f.guard.update();check(f.body.mass==10,"pending restore retries when unlocked");
    f=fixture();f.root.mass_reduction=true;delete f.keys.mass_set;f.guard.update();check(!f.root.mass_reduction && f.body.writes==0,"missing mass setter cannot fall back to native walk routine");
    f=fixture();f.root.mass_reduction=true;f.mass.text="0";f.guard.update();check(f.body.mass==10,"zero reduction keeps original mass");
    f=fixture();f.root.mass_reduction=true;f.mass.text="5,5";f.guard.update();check(Math.abs(f.body.mass-9.45)<0.00001,"mass decimal comma preserves reduction semantics");
    f=fixture();f.root.mass_reduction=true;f.guard.update();f.body.mass=12;f.body.inertia=5;f.player.cheese=true;f.guard.update();
    check(f.body.mass==12 && f.body.inertia==5,"engine mass change on cheese is preserved rather than overwritten");
    result="PASS: "+count+" focused physics assertions";
   }catch(error:Error){result=error.message+" #"+error.errorID;}
   var text:TextField=new TextField();text.text=result;text.width=790;text.height=200;display.addChild(text);
   trace(result);if(ExternalInterface.available)ExternalInterface.call("recordTest",result);
  }
 }
}
