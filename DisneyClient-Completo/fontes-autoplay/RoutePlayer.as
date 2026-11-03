// ActionScript 3 / RoutePlayer.as / Flash Player 10.3+ / replay saved routes through native player physics
package disney {
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.text.TextField;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    
    public class RoutePlayer {
        private static var instances:Dictionary = new Dictionary(true);
        private var root:MovieClip;
        private var keys:Object;
        private var map:Object;
        private var player:Object;
        private var body:Object;
        private var code:String = "";
        private var sequence:Array;
        private var index:int = 0;
        private var due:Number = 0;
        private var settle:int = 0;
        private var enabled:Boolean = false;
        private var attempted:Boolean = false;
        private var running:Boolean = false;
        private var paused:Boolean = false;
        private var failure:String = "";
        private var wasAlive:Boolean = false;
        private var mirror:Boolean = false;
        private var width:Number = 800;
        private var reduction:Number = 0;
        private var vectorClass:Class;
        private var lastStatus:int = -1000;
        public var message:String = "Bot: aguardando jogo";
        public static function attach(target:MovieClip):void {
            if (!target || !target.stage || instances[target]) return;
            var robot:RoutePlayer = new RoutePlayer(target);
            instances[target] = robot;
            target.stage.addEventListener(Event.ENTER_FRAME, function(event:Event):void { robot.advance(getTimer()); });
            target.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(event:KeyboardEvent):void {
                if (target.stage.focus is TextField && TextField(target.stage.focus).type=="input") return;
                if (target["auto_play_disable_on_move"] && [37,38,39,40,65,68,83,87].indexOf(event.keyCode)>=0) robot.pause();
            });
        }
        public function RoutePlayer(target:MovieClip) { root=target; }
        private function status(text:String, now:int):void {
            message=text;
            if (now-lastStatus<200) return;
            lastStatus=now;
            var ui:Object=root["Interface"];
            if (ui && ui["status_field"]) ui["status_field"].text=text;
        }
        private function release():void {
            if (player && keys) {
                try {
                    player[keys.player_moving_left]=false;
                    player[keys.player_moving_right]=false;
                    player[keys.jump](false);
                    if (player[keys.is_down]) {
                        player[keys.is_down]=false;
                        player[keys.crouch2](player[keys.static_side]);
                    }
                    if (keys.static_animation) player[keys.static_animation](player[keys.static_side]);
                } catch (ignored:Error) {}
            }
        }
        public function pause():void {
            if (!running) return;
            running=false; paused=true; release();
            message="Bot: pausado pela tecla; reative Autoplay para reiniciar";
        }
        private function wait(text:String, now:int):void {
            if (running) release();
            running=false;
            status(text,now);
        }
        public static function decodeRoute(text:String):Array {
            var route:Array=com.adobe.serialization.json.JSON.decode(text) as Array;
            if (!route || route.length==0 || route.length>100000) throw new Error("Invalid route",2001);
            for (var i:int=0;i<route.length;i++) {
                var entry:Object=route[i];
                var step:Array=entry as Array;
                if (!step || (step.length!=2 && step.length!=3)) throw new Error("Invalid route shape",2002);
                var timing:Object=step[step.length-1];
                if (!(timing is Number) || !isFinite(Number(timing)) || Number(timing)<0 || Number(timing)>3600000) throw new Error("Invalid route timing",2002);
                var action:String=String(step[step.length-2]);
                if (["walk","crouch","duck","cheese","hole","emote"].indexOf(action)<0) throw new Error("Unknown route action",2003);
                if (step.length==2) {
                    if (action!="cheese" && action!="hole") throw new Error("Missing route payload",2004);
                    route[i]=[null,action,timing];
                }
                if (action=="walk") {
                    var movement:Object=step[0];
                    if (!movement) throw new Error("Missing movement",2004);
                    for each (var name:String in ["x","y","vx","vy","frame"]) {
                        if (!(movement[name] is Number) || !isFinite(Number(movement[name])) || Number(movement[name])<-2147483648 || Number(movement[name])>4294967295) throw new Error("Invalid movement",2004);
                    }
                    if (!(movement.mr is Boolean) || !(movement.ml is Boolean) || !(movement.jump is Boolean)) throw new Error("Invalid movement flags",2004);
                }
            }
            return route;
        }
        public function advance(now:int):void {
            try { update(now); }
            catch (error:Error) {
                failure="Bot: erro #"+error.errorID+"; reative para tentar novamente";
                wait(failure,now);
                attempted=true;
            }
        }
        private function update(now:int):void {
            keys=root["Keys"];
            if (!keys || !root["tfm"]) { status("Bot: aguardando jogo",now); return; }
            for each (var symbol:String in ["bot_map_code_object","bot_map_code_value","bot_reverse","bot_map_width","player_physics","physics_state","physics_state_vx","physics_state_vy","bot_set_position","b2vec2"]) {
                if (!keys[symbol]) { wait("Bot: simbolo ausente: "+symbol,now); return; }
            }
            var nextMap:Object=keys.map_class ? keys.map_class[keys.map_instance] : null;
            var nextPlayer:Object=root["tfm"][keys.player];
            if (!nextMap || !nextPlayer) {
                wait("Bot: aguardando mapa/jogador",now);map=null;body=null;wasAlive=false;attempted=false;return;
            }
            var numberObject:Object=nextMap[keys.bot_map_code_object];
            if (!numberObject) { wait("Bot: aguardando codigo do mapa",now);return; }
            var number:Number=Number(numberObject[keys.bot_map_code_value]);
            if (!isFinite(number) || number<=0 || number!=Math.floor(number)) { wait("Bot: mapa sem codigo salvo",now);return; }
            var nextCode:String="@"+number.toFixed(0);
            var nextBody:Object=nextPlayer[keys.player_physics];
            var alive:Boolean=Boolean(nextBody) && Boolean(nextPlayer[keys.player_clip]) && !nextPlayer[keys.is_dead];
            var newRound:Boolean=nextMap!==map || nextCode!=code;
            var respawn:Boolean=alive && (!wasAlive || nextBody!==body || nextPlayer!==player);
            if (newRound || respawn) {
                if (running) release();
                running=false;attempted=false;paused=false;failure="";settle=now+250;
            }
            map=nextMap;player=nextPlayer;body=nextBody;code=nextCode;wasAlive=alive;
            root["current_map_code"]=code;root["current_map_code_int"]=int(number);
            width=Number(keys.map_class[keys.bot_map_width]);
            if (!isFinite(width) || width<1 || width>100000) {wait("Bot: largura do mapa invalida",now);attempted=true;return;}
            mirror=Boolean(map[keys.obj_container][keys.bot_reverse]);
            root["map_width"]=width;root["reverse_map"]=mirror;
            var active:Boolean=Boolean(root["auto_play"]);
            if (!active) {
                if (running) release();
                running=false;enabled=false;attempted=false;paused=false;failure="";
                status("Bot: desligado | "+code,now);return;
            }
            if (!enabled) { enabled=true;attempted=false;paused=false;failure="";settle=now+250; }
            if (!alive) { wait("Bot: aguardando renascer | "+code,now);return; }
            if (paused) {status("Bot: pausado pela tecla; reative Autoplay",now);return;}
            if (now<settle || !keys.move_class || !keys.move_class[keys.move_free] || (keys.timer_class && keys.timer_class[keys.timer_prop])) {
                if(running) {wait("Bot: aguardando liberacao do jogador",now);attempted=false;}
                else status("Bot: aguardando liberacao do jogador",now);
                return;
            }
            if (failure!="") {status(failure,now);return;}
            if (!attempted) {
                var saved:Object=keys.maps ? keys.maps[code] : null;
                if (!saved) { status("Bot: sem rota salva para "+code,now);return; }
                attempted=true;
                sequence=decodeRoute(String(saved));
                vectorClass=keys.app_domain.applicationDomain.getDefinition(String(keys.b2vec2)) as Class;
                if (!vectorClass || !(body[keys.bot_set_position] is Function)) throw new Error("Physics unavailable",2005);
                var ui:Object=root["Interface"];
                reduction=0;
                if (ui && ui["bot_delay_input"]) reduction=Number(ui["bot_delay_input"][keys.text_field].text);
                if (!isFinite(reduction) || reduction<0) reduction=0;
                reduction=Math.min(reduction,1000);
                index=0;due=now;running=true;
            }
            if (!running) {status("Bot: rota finalizada | "+code+" | aguardando proxima rodada",now);return;}
            var count:int=0;
            while (running && now>=due && count<12) {
                apply(sequence[index]);index++;count++;
                if (index>=sequence.length) {running=false;release();break;}
                due+=Math.max(0,Number(sequence[index][2])-reduction);
            }
            // A stalled window must not teleport through an entire route in one frame.
            if (running && count==12 && due<now-250) {failure="Bot: execucao atrasada; aguarde renascer ou reative";wait(failure,now);return;}
            status(running ? "Bot: reproduzindo "+code+" | "+index+"/"+sequence.length : "Bot: rota finalizada | "+code,now);
        }
        private function apply(step:Array):void {
            var action:String=String(step[1]);
            if (action=="walk") {
                var point:Object=step[0];
                var x:Number=int(Number(point.x))/100;
                var y:Number=int(Number(point.y))/100;
                var vx:Number=(int(point.vx)<<16>>16)/100;
                var vy:Number=(int(point.vy)<<16>>16)/100;
                var right:Boolean=Boolean(point.mr);var left:Boolean=Boolean(point.ml);
                if (mirror) {x=width/30-x;vx=-vx;right=Boolean(point.ml);left=Boolean(point.mr);}
                var oldRight:Boolean=Boolean(player[keys.player_moving_right]);
                var oldLeft:Boolean=Boolean(player[keys.player_moving_left]);
                player[keys.player_moving_right]=right;player[keys.player_moving_left]=left;
                if (point.jump) player[keys.jump](true,int(point.frame));else player[keys.jump](false);
                if (right && !oldRight) player[keys.animation_course](true);
                else if (left && !oldLeft) player[keys.animation_course](false);
                else if (!right && !left && (oldRight || oldLeft)) player[keys.static_animation](oldRight);
                var position:Object=new vectorClass(x,y);
                if (body[keys.bot_set_position](position,0)===false) throw new Error("Physics locked",2006);
                body[keys.physics_state][keys.physics_state_vx]=vx;
                body[keys.physics_state][keys.physics_state_vy]=vy;
                player.x=x*30;player.y=y*30;
            } else if (action=="crouch" || action=="duck") {
                player[keys.is_down]=Number(step[0])!=0;
                if (player[keys.is_down]) player[keys.crouch](player[keys.static_side]);
                else player[keys.crouch2](player[keys.static_side]);
            }
            // Native collision/update handlers collect cheese and enter holes.
            // Saved cheese/hole markers and cosmetic emotes consume their recorded time.
        }
    }
}
