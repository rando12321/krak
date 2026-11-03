// ActionScript 3 / RoutePlayerTests.as / AVM2 via Ruffle / saved-route integration tests with a mock native physics API
package disney {
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.geom.Point;
    import flash.external.ExternalInterface;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    public class RoutePlayerTests {
        private static var count:int=0;
        private static function check(ok:Boolean,name:String):void {if(!ok)throw new Error("FAIL: "+name);count++;}
        private static function walk(x:Number,delay:Number):Array {return [{x:x,y:1000,vx:200,vy:-100,mr:true,ml:false,jump:false,frame:0},"walk",delay];}
        private static function fixture():Object {
            var r:MovieClip=new MovieClip();var calls:Array=[];
            var body:Object={velocity:{vx:0,vy:0}};
            body.setPosition=function(p:Point,angle:Number):Boolean {calls.push({x:p.x,y:p.y});return true;};
            var player:Object={body:body,clip:true,dead:false,left:false,right:false,down:false,side:true};
            player.jump=function(value:Boolean,frame:int=0):void {};
            player.run=function(side:Boolean):void {};
            player.idle=function(side:Boolean):void {};
            player.crouch=function(side:Boolean):void {};
            player.stand=function(side:Boolean):void {};
            var map:Object={codeObject:{number:123},container:{mirror:false}};
            var keys:Object={bot_map_code_object:"codeObject",bot_map_code_value:"number",bot_reverse:"mirror",bot_map_width:"width",player_physics:"body",physics_state:"velocity",physics_state_vx:"vx",physics_state_vy:"vy",bot_set_position:"setPosition",b2vec2:"Point",map_class:{instance:map,width:800},map_instance:"instance",player:"mouse",player_clip:"clip",is_dead:"dead",obj_container:"container",move_class:{free:true},move_free:"free",timer_class:{locked:false},timer_prop:"locked",player_moving_left:"left",player_moving_right:"right",jump:"jump",animation_course:"run",static_animation:"idle",is_down:"down",crouch:"crouch",crouch2:"stand",static_side:"side",text_field:"field",maps:{},app_domain:{applicationDomain:{getDefinition:function(name:String):Class{return Point;}}}};
            var delay:TextField=new TextField();delay.text="10";
            r["Keys"]=keys;r["tfm"]={mouse:player};r["auto_play"]=true;r["auto_play_disable_on_move"]=true;
            r["Interface"]={status_field:new TextField(),bot_delay_input:{field:delay}};
            keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([walk(1000,999),walk(2000,1000),[0,"hole",1000]]);
            return {root:r,keys:keys,body:body,player:player,map:map,calls:calls,robot:new RoutePlayer(r)};
        }
        public static function run(display:MovieClip):void {
            var result:String;
            try {
                var f:Object=fixture();f.robot.advance(0);check(f.calls.length==0,"settle before start");f.robot.advance(300);
                check(f.calls.length==1 && f.calls[0].x==10,"first step immediate and scaled");
                check(f.body.velocity.vx==2 && f.body.velocity.vy==-1,"recorded velocity scaled");
                f.robot.advance(1289);check(f.calls.length==1,"honor recorded delay");f.robot.advance(1290);check(f.calls.length==2 && f.player.x==600,"delay reduction and native display position");
                f.robot.advance(2290);f.robot.advance(9000);check(f.calls.length==2 && f.robot.message.indexOf("finalizada")>=0,"completed route does not loop");
                f=fixture();f.map.container.mirror=true;f.robot.advance(0);f.robot.advance(300);check(Math.abs(f.calls[0].x-(800/30-10))<0.001 && f.body.velocity.vx==-2 && f.player.left,"mirrored position velocity and controls");
                f=fixture();f.robot.advance(0);f.robot.advance(300);f.root.auto_play=false;f.robot.advance(400);f.robot.advance(5000);check(f.calls.length==1 && !f.player.right,"disable cancels pending steps");
                f.root.auto_play=true;f.robot.advance(5100);f.robot.advance(5400);check(f.calls.length==2,"enable restarts route");
                f=fixture();f.robot.advance(0);f.robot.advance(300);f.robot.pause();f.robot.advance(3000);check(f.calls.length==1 && f.robot.message.indexOf("pausado")>=0,"manual pause stays paused");
                f=fixture();delete f.keys.maps["@123"];f.robot.advance(0);f.robot.advance(300);check(f.calls.length==0 && f.robot.message.indexOf("sem rota")>=0,"missing map explicit status");
                f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([walk(1000,0)]);f.robot.advance(500);check(f.calls.length==1,"late-loaded route becomes available");
                f=fixture();f.robot.advance(0);f.robot.advance(300);f.player.dead=true;f.robot.advance(400);f.player.dead=false;f.robot.advance(500);f.robot.advance(800);check(f.calls.length==2,"respawn replays same map and body");
                f=fixture();f.robot.advance(0);f.robot.advance(300);f.keys.map_class.instance={codeObject:{number:123},container:{mirror:false}};f.robot.advance(400);f.robot.advance(700);check(f.calls.length==2,"new round with same code restarts");
                f=fixture();f.keys.timer_class.locked=true;f.robot.advance(0);f.robot.advance(300);check(f.calls.length==0,"native countdown preserved");f.keys.timer_class.locked=false;f.robot.advance(500);check(f.calls.length==1,"start after native countdown");
                f=fixture();f.keys.maps["@123"]="[[{},\"walk\",0]]";f.robot.advance(0);f.robot.advance(300);f.robot.advance(1000);check(f.calls.length==0 && f.robot.message.indexOf("erro #2004")>=0,"invalid route stays failed without moving");
                f=fixture();var many:Array=[];for(var i:int=0;i<40;i++)many.push(walk(1000+i,1000));
                f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode(many);f.robot.advance(0);f.robot.advance(300);f.robot.advance(100000);
                check(f.calls.length==13 && f.robot.message.indexOf("atrasada")>=0,"stalled window bounded and stopped");
                f.robot.advance(200000);check(f.calls.length==13,"stalled route stays stopped");
                f=fixture();delete f.keys.bot_reverse;f.robot.advance(0);f.robot.advance(300);check(f.calls.length==0 && f.robot.message.indexOf("simbolo ausente")>=0,"unsupported build stays idle");
                f=fixture();var negative:Array=walk(4294967196,0);negative[0].vx=65535;negative[0].vy=65436;
                f.keys.maps["@123"]=com.adobe.serialization.json.JSON.encode([negative,["cheese",37],["hole",410]]);
                f.robot.advance(0);f.robot.advance(300);
                check(f.calls[0].x==-1 && f.body.velocity.vx==-0.01 && f.body.velocity.vy==-1,"unsigned storage decoded as signed native integers");
                f.robot.advance(327);f.robot.advance(727);check(f.robot.message.indexOf("finalizada")>=0,"legacy two-element markers normalized");
                var welcomeCalls:Array=[];f=fixture();f.keys.chat_class2={show:function(text:String):void{welcomeCalls.push(text);}};f.keys.chat_message2="show";
                var general:Sprite=new Sprite();f.root.Interface.general_ui=general;
                var controls:NativeControls=new NativeControls(f.root);controls.tick(0);controls.tick(1000);
                check(welcomeCalls.length==1 && welcomeCalls[0]=="<BL>BEM VINDO AO SDDS CHEATS</BL>","welcome appears once in local chat");
                check(general.numChildren==1 && general.getChildAt(0).name=="sddsWjFly","native WJ Fly row added without duplicates");
                result="PASS: "+count+" AVM2 route playback assertions";
            } catch(error:Error) {result=error.message+" #"+error.errorID;}
            if (result.indexOf("PASS:")!=0) {report(display,result);return;}
            try {
                var routes:Array=ExternalInterface.call("getRoutes") as Array;
                for each(var saved:String in routes)RoutePlayer.decodeRoute(saved);
                report(display,result+"; "+routes.length+" actual saved routes decoded");
            }catch(error:Error){report(display,"FAIL: actual saved routes: "+error.message+" #"+error.errorID);}

        }
        private static function report(display:MovieClip,result:String):void {
            var field:TextField=new TextField();field.width=780;field.height=400;field.text=result;display.addChild(field);
            trace(result);if(ExternalInterface.available)ExternalInterface.call("recordTest",result);
        }
    }
}
