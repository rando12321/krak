// ActionScript 3 / RoutePlayerFixed1069.as / Flash Player 10.3+ / replay legacy route control states through SWF keyboard events
package disney {
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.text.TextField;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.utils.ByteArray;
    
    public class RoutePlayerFixed1069 {
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
        private var completed:Boolean = false;
        private var debugField:TextField;
        private var debugHeader:TextField;
        private var debugRendered:int=0;
        private var debugPaintAt:int=-1000;
        private var disconnected:Boolean=false;
        private var frameHandler:Function;
        private var socketScanAt:int=-1000;
        private var observedSockets:Dictionary=new Dictionary(true);
        private var sockets:Object={};
        private var socketDisplayAtActivation:String="";
        private var networkSummary:String="sockets ainda nao identificados";
        private var debugPanel:Object;
        private var debugLines:Array=[];
        private var debugCounter:int=0;
        private var activatedAt:int=0;
        private var lastDebugFrame:int=-1000;
        private var diagnosticFrame:Boolean=false;
        private var observedActive:Boolean=false;
        private var lastOperation:String="nenhuma chamada de movimento";
        private var paused:Boolean = false;
        private var failure:String = "";
        private var wasAlive:Boolean = false;
        private var mirror:Boolean = false;
        private var routeMirror:Boolean=false;
        private var routeMirrorKnown:Boolean=false;
        private var width:Number = 800;
        private var routeStartedAt:int=0;
        private var expectedElapsed:Number=0;
        private var lastAppliedAt:int=0;
        private var lastPosition:Object;
        private var lastPositionAt:int=-1;
        private var measuredVx:Number=0;
        private var measuredVy:Number=0;
        private var velocitySampleValid:Boolean=false;
        private var previousWalk:Object;
        private var lastWalkRecordedAt:Number=0;
        private var trajectory:Array=[];
        private var jumpPlan:Array=[];
        private var jumpPlanIndex:int=0;
        // Median ballistic estimate from the supplied 2,205 recorded routes.
        private static const RECORDED_GRAVITY:Number=299.1643454038997;
        private static const RECORDED_JUMP_VY:Number=-150;
        private var lastMotionLogAt:int=-1000;
        private var lastFeedbackAt:int=0;
        private var velocityCoasting:Boolean=false;
        private var heldKeys:Object={};
        private var emittingKey:Boolean=false;
        private var manualKeyHandler:Function;
        private var deactivateHandler:Function;
        private var serverOutcome:String="sem evento de vitoria/morte recebido";
        private var lastLocalPlayerId:int=-1;
        private var serverState:String="";
        private var serverStateMap:Object;
        private var serverStateRound:String="";
        private var pauseReason:String="Bot: pausado pela tecla; reative Autoplay";
        public function get currentStep():int{return index;}
        public function get waypointCount():int{return sequence ? sequence.length : 0;}
        private var lastStatus:int = -1000;
        public var message:String = "Bot: aguardando jogo";
        public static function attach(target:MovieClip):void {
            if (!target || !target.stage || instances[target]) return;
            var robot:RoutePlayerFixed1069 = new RoutePlayerFixed1069(target);
            instances[target] = robot;
            robot.frameHandler=function(event:Event):void{robot.advance(getTimer());};
            target.stage.addEventListener(Event.ENTER_FRAME,robot.frameHandler,false,1000);

        }
        public function RoutePlayerFixed1069(target:MovieClip) { root=target;instances[target]=this;diagnosticFrame=true;activatedAt=getTimer();diagnostic("constructor","ANTES");diagnostic("constructor","DEPOIS");
            if(root.stage){
                manualKeyHandler=function(event:KeyboardEvent):void{
                    if(emittingKey || !running || !root.stage)return;
                    if(root.stage.focus is TextField && TextField(root.stage.focus).type=="input")return;
                    if(root["auto_play_disable_on_move"] && [37,38,39,40,65,68,83,87].indexOf(event.keyCode)>=0)pause();
                };
                root.stage.addEventListener(KeyboardEvent.KEY_DOWN,manualKeyHandler,true,10000);
                root.stage.addEventListener(KeyboardEvent.KEY_DOWN,manualKeyHandler,false,10000);
                deactivateHandler=function(event:Event):void{
                    if(!root.stage || !running)return;
                    running=false;paused=true;pauseReason="Bot: pausado por perda de foco | reative para reiniciar";release();status(pauseReason,getTimer());
                };
                root.stage.addEventListener(Event.DEACTIVATE,deactivateHandler);
            }
        }
        private function diagnostic(name:String,phase:String,detail:String=""):void {
            if(!diagnosticFrame || disconnected)return;
            var row:String="["+(++debugCounter)+" +"+(getTimer()-activatedAt)+"ms] "+phase+" "+name+(detail!="" ? " | "+detail : "");
            trace("[BOTTRACE] "+row);
            debugLines.push(row);
            if(name=="teclado" || name=="sincronizar" || name.indexOf("player.")==0 || name.indexOf("body.")==0)lastOperation=row;
            refreshDiagnostic();
        }
        private function logButton(panel:Object,title:String,x:Number,y:Number,callback:Function):void {
            var button:flash.display.Sprite=new flash.display.Sprite();
            button.x=x;button.y=y;button.buttonMode=true;button.mouseChildren=false;
            button.graphics.beginFill(0x29425B);button.graphics.drawRoundRect(0,0,100,23,5,5);button.graphics.endFill();
            var text:TextField=new TextField();text.defaultTextFormat=new flash.text.TextFormat("_sans",11,0xFFFFFF);
            text.text=title;text.width=96;text.height=21;text.x=4;text.y=2;text.selectable=false;button.addChild(text);
            button.addEventListener(flash.events.MouseEvent.CLICK,function(event:flash.events.MouseEvent):void{event.stopPropagation();callback();});
            panel.addChild(button);
        }
        private function refreshDiagnostic(force:Boolean=false):void {
            if(!force && getTimer()-debugPaintAt<100)return;
            debugPaintAt=getTimer();
            try {
                var ui:Object=root["Interface"];
                var panel:Object=ui && hasSlot(ui,"bot_ui") ? ui["bot_ui"] : null;
                if(panel && panel!==debugPanel) {
                    debugPanel=panel;debugRendered=0;
                    var top:Number=panel.height+10;
                    debugHeader=new TextField();debugHeader.name="autoplayDiagnosticState";
                    debugHeader.defaultTextFormat=new flash.text.TextFormat("_typewriter",10,0xE5EDF7);
                    debugHeader.width=525;debugHeader.height=112;debugHeader.y=top;
                    debugHeader.multiline=true;debugHeader.wordWrap=true;debugHeader.selectable=true;panel.addChild(debugHeader);
                    logButton(panel,"Inicio",0,top+114,function():void{debugField.scrollV=1;});
                    logButton(panel,"Fim",106,top+114,function():void{debugField.scrollV=debugField.maxScrollV;});
                    logButton(panel,"Copiar tudo",212,top+114,function():void{flash.system.System.setClipboard(debugHeader.text+"\n"+debugLines.join("\n"));});
                    debugField=new TextField();debugField.name="autoplayDiagnosticLabel";
                    debugField.defaultTextFormat=new flash.text.TextFormat("_typewriter",10,0xE5EDF7);
                    debugField.width=525;debugField.height=260;debugField.y=top+142;
                    debugField.multiline=true;debugField.wordWrap=true;debugField.selectable=true;
                    debugField.mouseWheelEnabled=false;
                    debugField.background=true;debugField.backgroundColor=0x102034;
                    debugField.border=true;debugField.borderColor=0x607080;
                    debugField.addEventListener(flash.events.MouseEvent.MOUSE_WHEEL,function(event:flash.events.MouseEvent):void{
                        event.stopPropagation();debugField.scrollV=Math.max(1,Math.min(debugField.maxScrollV,debugField.scrollV-event.delta*3));
                    });
                    panel.addChild(debugField);
                }
                if(debugHeader)debugHeader.text="AUTOPLAY / DIAGNOSTICO LOCAL - HISTORICO DA SESSAO\n"+
                    "mapa="+code+" ativo="+observedActive+" executando="+running+" tentou="+attempted+" concluiu="+completed+
                    " passo="+index+"/"+(sequence ? sequence.length : 0)+" registros="+debugLines.length+"\nRede: "+networkSummary+"\nServidor: "+serverOutcome+"\nUltima operacao: "+lastOperation;
                if(debugField) {
                    var follow:Boolean=debugRendered==0 || debugField.scrollV>=debugField.maxScrollV;
                    if(debugRendered<debugLines.length){
                        debugField.appendText(debugLines.slice(debugRendered).join("\n")+"\n");debugRendered=debugLines.length;
                    }
                    if(follow)debugField.scrollV=debugField.maxScrollV;
                }
            }catch(ignored:Error){}
        }
        private function status(text:String, now:int):void {
            message=text;refreshDiagnostic();
            if (now-lastStatus<200) return;
            lastStatus=now;
            var ui:Object=root["Interface"];
            if (ui && ui["status_field"]) ui["status_field"].text=text;
        }
        private function prepareKeyboard():void {
            if(!root.stage)throw new Error("palco do jogo indisponivel",2010);
            var game:flash.display.InteractiveObject=root["tfm"] as flash.display.InteractiveObject;
            // Focus the game once when arming; never send held arrows into chat.
            if(game && game.stage===root.stage)root.stage.focus=game;else root.stage.focus=null;
        }
        private function emitKey(code:uint,down:Boolean):void {
            if(!root.stage)throw new Error("palco do teclado indisponivel",2010);
            var stage:flash.display.Stage=root.stage;
            var game:flash.display.DisplayObject=root["tfm"] as flash.display.DisplayObject;
            var target:flash.events.IEventDispatcher=game && game.stage===stage ? game : stage;
            var previousFocus:flash.display.InteractiveObject=stage.focus;
            var manualFlag:Boolean=Boolean(root["auto_play_disable_on_move"]);
            emittingKey=true;root["auto_play_disable_on_move"]=false;
            try{
                if(!down && stage.focus is TextField && TextField(stage.focus).type=="input")stage.focus=null;
                diagnosticFrame=true;diagnostic("teclado","ANTES","codigo="+code+" "+(down ? "KEY_DOWN" : "KEY_UP"));
                target.dispatchEvent(new KeyboardEvent(down ? KeyboardEvent.KEY_DOWN : KeyboardEvent.KEY_UP,true,false,0,code));
                diagnostic("teclado","DEPOIS","codigo="+code);
            }finally{
                root["auto_play_disable_on_move"]=manualFlag;emittingKey=false;
                if(!down && previousFocus && previousFocus.stage===stage)restoreFocus(previousFocus);
            }
        }
        private function observedPosition():Object {
            var getter:Function=safeRead(body,safeRead(keys,"get_x_form")) as Function;
            if(getter!=null){
                var transform:Object=getter.apply(body,[]);
                var physical:Object=safeRead(transform,"position");
                var px:Object=safeRead(physical,safeRead(keys,"pos_x"));
                var py:Object=safeRead(physical,safeRead(keys,"pos_y"));
                if(px!=null && py!=null && isFinite(Number(px)) && isFinite(Number(py)))return {x:Number(px)*30,y:Number(py)*30};
            }
            var x:Object=safeRead(player,"x");var y:Object=safeRead(player,"y");
            if(x==null || y==null || !isFinite(Number(x)) || !isFinite(Number(y)))return {x:Number.NaN,y:Number.NaN};
            return {x:Number(x),y:Number(y)};
        }
        public static function resolveRouteMirror(route:Array,spawnX:Number,mapWidth:Number,reported:Boolean):Boolean {
            if(!isFinite(spawnX) || !isFinite(mapWidth) || mapWidth<200)return reported;
            var elapsed:Number=0;
            for each(var step:Array in route){
                elapsed+=Number(step[2]);
                if(elapsed>1500)return reported;
                if(String(step[1])!="walk")continue;
                var anchor:Number=int(Number(step[0].x))/100*30;
                if(anchor<0 || anchor>mapWidth || spawnX<0 || spawnX>mapWidth)return reported;
                var normalError:Number=Math.abs(spawnX-anchor);
                var reverseError:Number=Math.abs(spawnX-(mapWidth-anchor));
                // Only decisive, near-spawn evidence may override metadata.
                // Central starts, late samples and large drift remain unchanged.
                var nearSpawn:Number=Math.min(90,mapWidth*0.15);
                if(Math.min(normalError,reverseError)<=nearSpawn && Math.abs(normalError-reverseError)>=mapWidth*0.35)return reverseError<normalError;
                return reported;
            }
            return reported;
        }
        private function routeInput(point:Object):Object {
            return mirror ? {left:Boolean(point.mr),right:Boolean(point.ml)} : {left:Boolean(point.ml),right:Boolean(point.mr)};
        }
        private function waypoint(point:Object):Object {
            var x:Number=int(Number(point.x))/100*30;
            if(mirror)x=width-x;
            return {x:x,y:int(Number(point.y))/100*30};
        }
        // Legacy packets store signed hundredths of Box2D units/second.
        // Compare in pixels/second: one Box2D unit is 30 pixels.
        public static function recordedVelocity(value:Number):Number {
            return (int(value)<<16>>16)/100*30;
        }
        private function observedVelocity():Object {
            var state:Object=safeRead(body,safeRead(keys,"physics_state"));
            var getter:Function=safeRead(body,safeRead(keys,"get_linear_velocity")) as Function;
            if(getter!=null){try{state=getter.apply(body,[]);}catch(ignoredVelocity:Error){}}
            var vx:Object=safeRead(state,safeRead(keys,"physics_state_vx"));
            var vy:Object=safeRead(state,safeRead(keys,"physics_state_vy"));
            if(vx!=null && vy!=null && isFinite(Number(vx)) && isFinite(Number(vy)))return {vx:Number(vx)*30,vy:Number(vy)*30,valid:true,source:"fisica"};
            return {vx:measuredVx,vy:measuredVy,valid:velocitySampleValid,source:"deslocamento"};
        }
        public static function estimateRouteGravity(route:Array):Number {
            var estimates:Array=[];var before:Object=null;var beforeTime:Number=0;var time:Number=0;
            for each(var step:Array in route){
                time+=Number(step[2]);if(String(step[1])!="walk")continue;
                var point:Object=step[0];
                if(before){
                    var seconds:Number=(time-beforeTime)/1000;
                    var va:Number=recordedVelocity(Number(before.vy));var vb:Number=recordedVelocity(Number(point.vy));
                    var dy:Number=(Number(point.y)-Number(before.y))*0.3;
                    if(seconds>0.03 && seconds<0.5 && vb>va && Math.abs(dy-(va+vb)*0.5*seconds)<Math.max(3,Math.abs(dy)*0.2)){
                        var g:Number=(vb-va)/seconds;
                        if(g>100 && g<700)estimates.push(g);
                    }
                }
                before=point;beforeTime=time;
            }
            if(estimates.length<6)return RECORDED_GRAVITY;
            estimates.sort(Array.NUMERIC);var middle:int=estimates.length>>1;
            return estimates.length%2==1 ? Number(estimates[middle]) : (Number(estimates[middle-1])+Number(estimates[middle]))/2;
        }
        public static function buildTrajectory(route:Array):Array {
            var result:Array=[];result["gravity"]=estimateRouteGravity(route);var time:Number=0;
            for each(var step:Array in route){
                time+=Number(step[2]);
                if(String(step[1])=="walk")result.push({time:time,point:step[0]});
            }
            return result;
        }
        public static function requiresJumpEdge(before:Object,point:Object,elapsedMs:Number,gravity:Number=-1):Boolean {
            if(gravity<=0)gravity=RECORDED_GRAVITY;
            if(!Boolean(point.jump))return false;
            if(!before || !Boolean(before.jump))return true;
            if(elapsedMs<=0)return false;
            var vy:Number=recordedVelocity(Number(point.vy));
            var predicted:Number=recordedVelocity(Number(before.vy))+gravity*elapsedMs/1000;
            // jump is a sampled state, not a key edge. A fresh -150px/s
            // impulse can occur while successive snapshots both say true.
            return Math.abs(vy-RECORDED_JUMP_VY)<=6 && predicted-vy>60;
        }
        public static function buildJumpPlan(route:Array,gravity:Number=-1):Array {
            if(gravity<=0)gravity=estimateRouteGravity(route);
            var plan:Array=[];var time:Number=0;var before:Object=null;var beforeTime:Number=0;
            for each(var step:Array in route){
                time+=Number(step[2]);if(String(step[1])!="walk")continue;
                var point:Object=step[0];
                if(requiresJumpEdge(before,point,time-beforeTime,gravity)){
                    var launch:Number=time;var vy:Number=recordedVelocity(Number(point.vy));
                    var age:Number=(vy-RECORDED_JUMP_VY)/gravity*1000;
                    // Invert the rising ballistic state only when the inferred
                    // launch fits inside the observed interval. Otherwise retain
                    // its timestamp rather than guessing outside the recording.
                    if(vy<0 && age>0 && age<=time-beforeTime)launch=time-age;
                    plan.push({time:launch,down:true});
                }else if(before && Boolean(before.jump) && !Boolean(point.jump))plan.push({time:time,down:false});
                before=point;beforeTime=time;
            }
            return plan;
        }
        private function recordedPhase(now:int):Number {
            return Math.max(lastWalkRecordedAt,expectedElapsed-Math.max(0,due-now));
        }
        private function advanceJumpPlan(now:int):void {
            var phase:Number=recordedPhase(now);var count:int=0;
            while(jumpPlanIndex<jumpPlan.length && Number(jumpPlan[jumpPlanIndex].time)<=phase && count<64){
                var event:Object=jumpPlan[jumpPlanIndex++];count++;
                if(Boolean(event.down) && Boolean(heldKeys[38]))setKey(38,false);
                setKey(38,Boolean(event.down));
                diagnosticFrame=true;diagnostic("salto.calculado",Boolean(event.down) ? "IMPULSO" : "SOLTAR","tempoGravado="+Number(event.time).toFixed(1)+"ms fase="+phase.toFixed(1)+"ms");
            }
        }
        public static function sampleTrajectory(samples:Array,time:Number,reflected:Boolean,mapWidth:Number):Object {
            if(!samples || samples.length==0)return null;
            var gravity:Number=Number(samples["gravity"]);if(!isFinite(gravity) || gravity<=0)gravity=RECORDED_GRAVITY;
            var lo:int=0;var hi:int=samples.length;
            while(lo<hi){var mid:int=(lo+hi)>>1;if(Number(samples[mid].time)<=time)lo=mid+1;else hi=mid;}
            var i:int=Math.max(0,lo-1);var a:Object=samples[i];var pa:Object=a.point;
            var x:Number=int(Number(pa.x))*0.3;var y:Number=int(Number(pa.y))*0.3;
            var vx:Number=recordedVelocity(Number(pa.vx));var vy:Number=recordedVelocity(Number(pa.vy));
            var continuousX:Boolean=false;
            if(i+1<samples.length && time>=Number(a.time)){
                var b:Object=samples[i+1];var pb:Object=b.point;var duration:Number=(Number(b.time)-Number(a.time))/1000;
                if(duration>0){
                    var u:Number=Math.max(0,Math.min(1,(time-Number(a.time))/(duration*1000)));
                    var bx:Number=int(Number(pb.x))*0.3;var by:Number=int(Number(pb.y))*0.3;
                    var bvx:Number=recordedVelocity(Number(pb.vx));var bvy:Number=recordedVelocity(Number(pb.vy));
                    var average:Number=(vx+bvx)/2;
                    continuousX=Math.abs((bx-x)/duration-average)<=Math.max(20,Math.abs(average)*0.35);
                    // A consistent segment supports a velocity-constrained cubic.
                    // Discontinuous legacy corrections remain diagnostics only.
                    if(continuousX){
                        var u2:Number=u*u;var u3:Number=u2*u;
                        var hx:Number=(2*u3-3*u2+1)*x+(u3-2*u2+u)*duration*vx+(-2*u3+3*u2)*bx+(u3-u2)*duration*bvx;
                        var hvx:Number=((6*u2-6*u)*x+(3*u2-4*u+1)*duration*vx+(-6*u2+6*u)*bx+(3*u2-2*u)*duration*bvx)/duration;
                        x=hx;vx=hvx;
                    }else {x+=(bx-x)*u;vx+=(bvx-vx)*u;}
                    // Do not smear an endpoint takeoff backwards over a flight.
                    if(requiresJumpEdge(pa,pb,duration*1000,gravity)){
                        var flightTime:Number=u*duration;
                        var launchAge:Number=(bvy-RECORDED_JUMP_VY)/gravity;
                        var launchOffset:Number=duration;
                        if(bvy<0 && launchAge>0 && launchAge<=duration)launchOffset=duration-launchAge;
                        if(flightTime>=launchOffset && launchOffset<duration){
                            var sinceLaunch:Number=flightTime-launchOffset;
                            var launchY:Number=by-RECORDED_JUMP_VY*launchAge-0.5*gravity*launchAge*launchAge;
                            y=launchY+RECORDED_JUMP_VY*sinceLaunch+0.5*gravity*sinceLaunch*sinceLaunch;
                            vy=RECORDED_JUMP_VY+gravity*sinceLaunch;
                        }else if(Boolean(pa.jump) || Math.abs(vy)>24){
                            y+=vy*flightTime+0.5*gravity*flightTime*flightTime;
                            vy+=gravity*flightTime;
                        }else {y+=(by-y)*u;vy=0;}
                    }else {y+=(by-y)*u;vy+=(bvy-vy)*u;}
                }
            }
            return {x:reflected ? mapWidth-x : x,y:y,vx:reflected ? -vx : vx,vy:vy,continuousX:continuousX};
        }
        private function referenceVelocity(now:int):Object {
            var phase:Number=recordedPhase(now);
            return sampleTrajectory(trajectory,phase,mirror,width);
        }
        private function synchronizeMotion(current:Object,now:int):void {
            if(!previousWalk)return;
            var actual:Object=observedVelocity();var reference:Object=referenceVelocity(now);
            var input:Object=routeInput(previousWalk);
            var left:Boolean=input.left;var right:Boolean=input.right;
            var direction:int=int(right)-int(left);
            // Keyboard feedback trims excess ground speed with release/repress,
            // never by applying an unrecorded opposite direction or editing physics.
            var canTrim:Boolean=Boolean(actual.valid) && direction!=0 && !Boolean(previousWalk.jump) && !Boolean(heldKeys[38]) && Math.abs(Number(actual.vy))<24 && Math.abs(Number(reference.vy))<24 && Number(reference.vx)*direction>6;
            if(canTrim){
                var expected:Number=Number(reference.vx)*direction;
                // Small tracking error becomes bounded speed feedback, never
                // a position gate, teleport or an opposite-direction command.
                var errorX:Number=Number(reference.x)-Number(current.x);
                if(Boolean(reference.continuousX) && isFinite(errorX) && Math.abs(errorX)<=90){
                    var correctionLimit:Number=Math.min(30,expected*0.25);
                    expected+=Math.max(-correctionLimit,Math.min(correctionLimit,errorX*direction*2));
                }
                var observed:Number=Number(actual.vx)*direction;
                var band:Number=Math.max(9,expected*0.12);
                if(!velocityCoasting && observed>expected+band)velocityCoasting=true;
                else if(velocityCoasting && observed<expected+band/2)velocityCoasting=false;
            }else velocityCoasting=false;
            if(now-lastFeedbackAt>=40){
                var wantLeft:Boolean=left && !velocityCoasting;
                var wantRight:Boolean=right && !velocityCoasting;
                if(Boolean(heldKeys[37])!=wantLeft || Boolean(heldKeys[39])!=wantRight){
                    if(!wantLeft)setKey(37,false);if(!wantRight)setKey(39,false);
                    if(wantLeft)setKey(37,true);if(wantRight)setKey(39,true);
                    lastFeedbackAt=now;
                }
            }
            if(now-lastMotionLogAt>=500){
                lastMotionLogAt=now;diagnosticFrame=true;
                var target:Object=reference;
                diagnostic("movimento","MEDIDO","vx="+Number(actual.vx).toFixed(1)+" vy="+Number(actual.vy).toFixed(1)+"px/s gravado="+Number(reference.vx).toFixed(1)+","+Number(reference.vy).toFixed(1)+"px/s fonte="+actual.source+" valido="+actual.valid+" modulacao="+velocityCoasting+" erroXY="+(target.x-current.x).toFixed(1)+","+(target.y-current.y).toFixed(1)+"px; referencia cinetica sem bloquear passos");
            }
        }
        private function restoreFocus(focus:flash.display.InteractiveObject):void {
            try{root.stage.focus=focus;}catch(ignoredFocus:Error){}
        }
        private function setKey(code:uint,down:Boolean):void {
            if(Boolean(heldKeys[code])==down)return;
            // Register before dispatch so synchronous callbacks cannot duplicate it.
            heldKeys[code]=down;
            try{emitKey(code,down);}catch(error:Error){heldKeys[code]=!down;throw error;}
        }
        private function movement(left:Boolean,right:Boolean,jump:Boolean):void {
            // Release opposite directions before pressing the next direction.
            if(!left)setKey(37,false);if(!right)setKey(39,false);if(!jump)setKey(38,false);
            if(left)setKey(37,true);if(right)setKey(39,true);if(jump)setKey(38,true);
        }
        private function release():void {
            diagnosticFrame=true;diagnostic("release","ANTES");
            for each(var code:uint in [37,38,39,40]){
                if(!Boolean(heldKeys[code]))continue;
                try{setKey(code,false);}catch(error:Error){heldKeys[code]=false;diagnostic("release","ERRO","codigo="+code+" erro="+error.errorID);}
            }
            diagnostic("release","DEPOIS");
        }
        private static function packetValue(target:Object,name:*):* {
            try{if(target!=null && name!=null && String(name) in target)return target[String(name)];}catch(ignored:Error){}return null;
        }
        public static function processNativePacket(target:MovieClip,bytes:ByteArray,channel:String):void {
            var original:Function=packetValue(target,"sddsNativeHandlePacket") as Function;
            if(original==null)throw new Error("processador nativo indisponivel",2020);
            var bot:RoutePlayerFixed1069=instances[target] as RoutePlayerFixed1069;
            var k:Object=packetValue(target,"Keys");var local:Object=packetValue(packetValue(target,"tfm"),packetValue(k,"player"));
            var rawId:* = packetValue(local,packetValue(k,"player_id"));
            var localId:int=rawId==null ? (bot ? bot.lastLocalPlayerId : -1) : int(rawId);
            if(bot && rawId!=null)bot.lastLocalPlayerId=localId;
            var ownVictory:Boolean=false;var ownDeath:Boolean=false;var ownRespawn:Boolean=false;var receivedOrder:int=-1;
            if(bytes && bytes.length>=2 && (channel=="main" || channel=="bulle")){
                try {
                    var copy:ByteArray=new ByteArray();
                    if(bytes[0]==8 && bytes[1]==6 && bytes.length>=12){
                        copy.writeBytes(bytes,0,bytes.length);copy.position=3;
                        ownVictory=localId>=0 && copy.readInt()==localId;receivedOrder=int(bytes[9])<<24>>24;
                    }else if(bytes[0]==144 && bytes[1]==2 && bytes.length>=4){
                        copy.writeBytes(bytes,0,bytes.length);copy.position=2;copy.readUTF();
                        ownRespawn=localId>=0 && copy.bytesAvailable>=4 && copy.readInt()==localId;
                    }else if(bytes[0]==1 && bytes[1]==1 && bytes.length>=4){
                        copy.writeBytes(bytes,0,bytes.length);copy.position=2;
                        var parts:Array=copy.readUTF().split(String.fromCharCode(1));var eventCode:String=String(parts[0]);
                        ownDeath=localId>=0 && eventCode.length>=2 && eventCode.charCodeAt(0)==8 && eventCode.charCodeAt(1)==5 && parts.length>1 && Number(parts[1])==localId;
                    }
                }catch(ignored:Error){}
            }
            var noDelay:Boolean=Boolean(packetValue(target,"no_delay"));
            // The native handler may suppress duplicate victory orders when
            // no_delay is on. A real OWN victory must always reach the game.
            if(ownVictory)target["no_delay"]=false;
            if(bot && (ownVictory || ownDeath) && !bot.disconnected){
                bot.diagnosticFrame=true;
                bot.serverOutcome=ownVictory ? "servidor confirmou VITORIA" : "servidor confirmou MORTE";
                bot.serverState=ownVictory ? "win" : "dead";
                bot.serverStateMap=packetValue(packetValue(k,"map_class"),packetValue(k,"map_instance"));
                bot.serverStateRound=String(packetValue(target,"current_round_code"));
                bot.running=false;if(bot.player===local)bot.release();
                bot.diagnostic(ownVictory ? "servidor.vitoria" : "servidor.morte","RECEBIDO","jogador="+localId+" canal="+channel);
                if(ownVictory && noDelay)bot.diagnostic("vitoria.NoDelay","PROTEGIDA","confirmacao real nao sera filtrada por ordem repetida");
            }
            if(bot && ownRespawn){bot.serverState="";bot.serverOutcome="servidor confirmou RENASCIMENTO";bot.running=false;bot.attempted=false;bot.wasAlive=false;bot.settle=getTimer()+250;}
            try{
                original.apply(target,[bytes,channel]);
                if(ownVictory && noDelay){
                    if(packetValue(target,"last_victory_order")!=null)target["last_victory_order"]=receivedOrder;
                    var nativeTime:* = packetValue(packetValue(k,"frame_loop_class"),packetValue(k,"victory_time"));
                    if(nativeTime!=null && packetValue(target,"last_victory_time")!=null)target["last_victory_time"]=nativeTime;
                }
            }
            finally{if(ownVictory)target["no_delay"]=noDelay;if(bot)bot.refreshDiagnostic(true);}
        }
        public function pause():void {
            diagnosticFrame=true;diagnostic("pause","ANTES");
            if (!running) return;
            running=false; paused=true; release();
            pauseReason="Bot: pausado pela tecla; reative Autoplay para reiniciar";message=pauseReason;diagnostic("pause","DEPOIS");
        }
        private function wait(text:String, now:int):void {
            diagnostic("wait","ANTES",text);
            if (running) release();
            running=false;
            if(!completed)attempted=false;
            status(text,now);diagnostic("wait","DEPOIS");
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
            if(disconnected)return;
            scanConnections(now);
            if(disconnected)return;
            var activeNow:Boolean=Boolean(root["auto_play"]);
            diagnosticFrame=now-lastDebugFrame>=500 || activeNow!==observedActive;
            if(diagnosticFrame)lastDebugFrame=now;
            if(activeNow!==observedActive){observedActive=activeNow;if(activeNow){activatedAt=getTimer();socketDisplayAtActivation=connectionDisplay();cancelLegacy();}diagnostic("auto_play","ANTES",activeNow ? "ativar" : "desativar");}
            diagnostic("update","ANTES");
            try { update(now);diagnostic("update","DEPOIS");refreshDiagnostic(true); }

            catch (error:Error) {
                diagnosticFrame=true;diagnostic("update","ERRO",String(error.errorID)+" "+error.message);
                if(error.errorID==2010){wait("Bot: aguardando parser/jogo | "+error.message,now);return;}
                failure="Bot: erro #"+error.errorID+" | "+error.message+"; reative para tentar novamente";
                wait(failure,now);
                attempted=true;
            }
        }
        private function safeRead(target:Object,name:*):* {
            try{if(hasSlot(target,name))return target[String(name)];}catch(ignored:Error){}return null;
        }
        private function cancelLegacy():void {
            var statements:Object=safeRead(root,"Statements");
            var cancel:Function=safeRead(statements,"disable_auto_play") as Function;
            if(cancel!=null){
                diagnostic("legacyScheduler.cancel","ANTES");
                try{cancel.apply(statements,[]);diagnostic("legacyScheduler.cancel","DEPOIS");}
                catch(error:Error){diagnostic("legacyScheduler.cancel","ERRO",String(error.errorID));}
            }
        }
        private function connectionDisplay():String {
            if(!root.stage)return "";
            var label:TextField=root.stage.getChildByName("sddsConnectionStatus") as TextField;
            return label ? label.text : "";
        }
        private function socketInside(wrapper:Object,k:Object):flash.net.Socket {
            if(wrapper is flash.net.Socket)return wrapper as flash.net.Socket;
            var direct:Object=safeRead(wrapper,safeRead(k,"socket_name"));
            if(direct is flash.net.Socket)return direct as flash.net.Socket;
            if(wrapper){
                try{for(var key:String in wrapper){var dynamicValue:Object=safeRead(wrapper,key);if(dynamicValue is flash.net.Socket)return dynamicValue as flash.net.Socket;}}catch(ignoredDynamic:Error){}
                try {
                    var info:XML=flash.utils.describeType(wrapper);
                    for each(var variable:XML in info.variable){var candidate:Object=safeRead(wrapper,String(variable.@name));if(candidate is flash.net.Socket)return candidate as flash.net.Socket;}
                    for each(var accessor:XML in info.accessor){if(String(accessor.@access)=="writeonly")continue;candidate=safeRead(wrapper,String(accessor.@name));if(candidate is flash.net.Socket)return candidate as flash.net.Socket;}
                }catch(ignored:Error){}
            }
            return null;
        }
        private function resolveSocket(channel:String):flash.net.Socket {
            var k:Object=safeRead(root,"Keys");var cls:Object=safeRead(k,"socket_class");
            var wrapper:Object=safeRead(cls,safeRead(k,channel=="main" ? "main_socket_instance" : "bulle_socket_instance"));
            return socketInside(wrapper,k);
        }
        private function bindSocket(socket:flash.net.Socket,channel:String):void {
            if(observedSockets[socket])return;
            observedSockets[socket]={was:socket.connected};
            var lost:Function=function(event:Event):void {
                if(disconnected || !Boolean(root["auto_play"]))return;
                var current:flash.net.Socket=resolveSocket(channel);
                if(current!==socket || sockets[channel]!==socket)return;
                stopForDisconnect(channel,event.type);
            };
            socket.addEventListener(Event.CLOSE,lost,false,10000);
            socket.addEventListener(flash.events.IOErrorEvent.IO_ERROR,lost,false,10000);
            socket.addEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR,lost,false,10000);
        }
        private function scanConnections(now:int):void {
            if(now-socketScanAt<250)return;socketScanAt=now;
            var summary:Array=[];
            for each(var channel:String in ["main","bulle"]){
                var socket:flash.net.Socket=resolveSocket(channel);
                if(!socket){summary.push(channel+"=nao identificado");continue;}
                summary.push(channel+"="+(socket.connected ? "conectado" : "fechado"));
                sockets[channel]=socket;bindSocket(socket,channel);
                var state:Object=observedSockets[socket];
                if(state.was && !socket.connected && Boolean(root["auto_play"])){
                    stopForDisconnect(channel,"connected=false");return;
                }
                state.was=socket.connected;
            }
            networkSummary=summary.join(" | ");
            var display:String=connectionDisplay();
            if(Boolean(root["auto_play"]) && observedActive && display!="" && display!=socketDisplayAtActivation && /^(Socket .* encerrado|Erro de rede|Erro de seguranca de rede|Desconectado)/i.test(display)) {
                var faultChannel:String=display.toLowerCase().indexOf("bulle")>=0 ? "bulle" : "main";
                var replacement:flash.net.Socket=resolveSocket(faultChannel);
                if(!replacement || !replacement.connected)stopForDisconnect(faultChannel,"diagnostico nativo: "+display);
            }
        }
        public function stopForDisconnect(channel:String,reason:String):void {
            if(disconnected)return;
            trace("disconnect");debugLines.push("disconnect");
            diagnosticFrame=true;diagnostic("disconnect","ANTES",channel+" "+reason);
            cancelLegacy();release();running=false;paused=true;enabled=false;observedActive=false;
            message="disconnect | Autoplay parado e log congelado | reabra o cliente";
            diagnostic("disconnect","CONGELADO",channel+" "+reason);
            refreshDiagnostic(true);
            disconnected=true;
            if(frameHandler!=null && root.stage)root.stage.removeEventListener(Event.ENTER_FRAME,frameHandler);
            var ui:Object=safeRead(root,"Interface");var field:TextField=safeRead(ui,"status_field") as TextField;
            if(field)field.text=message;
        }
        private function hasSlot(target:Object, name:*):Boolean {
            return target!=null && name!=null && String(name)!="" && String(name) in target;
        }
        private function readSlot(target:Object, name:*, label:String):* {
            diagnostic("readSlot","ANTES",label);
            if(!hasSlot(target,name))throw new Error("simbolo indisponivel: "+label,2010);
            var value:* = target[String(name)];
            diagnostic("readSlot","DEPOIS",label);
            return value;
        }
        private function update(now:int):void {
            if(!Boolean(root["auto_play"])) {
                if(running)release();
                running=false;enabled=false;attempted=false;completed=false;paused=false;failure="";routeMirrorKnown=false;
                status("Bot: desligado",now);return;
            }
            keys=root["Keys"];
            if(serverState!=""){
                var stateMap:Object=safeRead(safeRead(keys,"map_class"),safeRead(keys,"map_instance"));
                if(stateMap===serverStateMap && String(safeRead(root,"current_round_code"))==serverStateRound){
                    status(serverState=="win" ? "Bot: chegada confirmada pelo servidor" : "Bot: morte confirmada pelo servidor | aguardando renascer",now);return;
                }
                serverState="";running=false;attempted=false;wasAlive=false;
            }
            if (!keys || !root["tfm"]) { status("Bot: aguardando jogo",now); return; }
            for each (var symbol:String in ["bot_map_code_object","bot_map_code_value","bot_reverse","bot_map_width","player_physics"]) {
                if (!keys[symbol]) { wait("Bot: simbolo ausente: "+symbol,now); return; }
            }
            var nextMap:Object=keys.map_class ? readSlot(keys.map_class,keys.map_instance,"map_instance") : null;
            var nextPlayer:Object=readSlot(root["tfm"],keys.player,"player");
            if (!nextMap || !nextPlayer) {
                wait("Bot: aguardando mapa/jogador",now);map=null;body=null;wasAlive=false;attempted=false;return;
            }
            var numberObject:Object=readSlot(nextMap,keys.bot_map_code_object,"bot_map_code_object");
            if (!numberObject) { wait("Bot: aguardando codigo do mapa",now);return; }
            var number:Number=Number(readSlot(numberObject,keys.bot_map_code_value,"bot_map_code_value"));
            if (!isFinite(number) || number<=0 || number!=Math.floor(number)) { wait("Bot: mapa sem codigo salvo",now);return; }
            var nextCode:String="@"+number.toFixed(0);
            var nextBody:Object=readSlot(nextPlayer,keys.player_physics,"player_physics");
            var alive:Boolean=Boolean(nextBody) && Boolean(readSlot(nextPlayer,keys.player_clip,"player_clip")) && !readSlot(nextPlayer,keys.is_dead,"is_dead");
            var newRound:Boolean=nextMap!==map || nextCode!=code;
            var respawn:Boolean=alive && (!wasAlive || nextBody!==body || nextPlayer!==player);
            if (newRound || respawn) {
                if (running) release();
                running=false;attempted=false;completed=false;paused=false;failure="";routeMirrorKnown=false;settle=now+250;
            }
            map=nextMap;player=nextPlayer;body=nextBody;code=nextCode;wasAlive=alive;
            root["current_map_code"]=code;root["current_map_code_int"]=int(number);
            // Native loader metadata already records the parsed map width and mirror.
            // bot_reverse names a field on the NEW-MAP PACKET, not necessarily
            // on the sealed map object container. Never blindly read that slot.
            width=hasSlot(root,"map_width") ? Number(root["map_width"]) : NaN;
            if(!isFinite(width) || width<1 || width>100000)
                width=Number(readSlot(keys.map_class,keys.bot_map_width,"bot_map_width"));
            if (!isFinite(width) || width<1 || width>100000) {wait("Bot: aguardando largura do mapa",now);return;}
            if(hasSlot(root,"reverse_map"))mirror=Boolean(root["reverse_map"]);
            else {
                var container:Object=readSlot(map,keys.obj_container,"obj_container");
                mirror=Boolean(readSlot(container,keys.bot_reverse,"bot_reverse"));
            }
            // Keep the inferred orientation local; native packet metadata must
            // remain untouched for recording and other loader features.
            if(routeMirrorKnown)mirror=routeMirror;
            var active:Boolean=Boolean(root["auto_play"]);
            if (!active) {
                if (running) release();
                running=false;enabled=false;attempted=false;completed=false;paused=false;failure="";routeMirrorKnown=false;
                status("Bot: desligado | "+code,now);return;
            }
            if (!enabled) { enabled=true;attempted=false;completed=false;paused=false;failure="";settle=now+250; }
            if (!alive) { wait("Bot: aguardando renascer | "+code,now);return; }
            if (paused) {status(pauseReason,now);return;}
            if (now<settle || !keys.move_class || !keys.move_class[keys.move_free] || (keys.timer_class && keys.timer_class[keys.timer_prop])) {
                if(running) {wait("Bot: aguardando liberacao do jogador",now);attempted=false;}
                else status("Bot: aguardando liberacao do jogador",now);
                return;
            }
            if (failure!="") {status(failure,now);return;}
            if(running && root.stage && root.stage.focus is TextField && TextField(root.stage.focus).type=="input"){
                running=false;paused=true;pauseReason="Bot: pausado para digitar | reative para reiniciar";release();status(pauseReason,now);return;
            }
            if (!attempted) {
                diagnosticFrame=true;
                var saved:Object=keys.maps ? keys.maps[code] : null;
                if (!saved) { status("Bot: sem rota salva para "+code,now);return; }
                attempted=true;
                diagnostic("decodeRoute","ANTES");
                sequence=decodeRoute(String(saved));trajectory=buildTrajectory(sequence);jumpPlan=buildJumpPlan(sequence,Number(trajectory["gravity"]));jumpPlanIndex=0;
                var spawn:Object=observedPosition();
                routeMirror=resolveRouteMirror(sequence,Number(spawn.x),width,mirror);routeMirrorKnown=true;
                diagnostic("direcao","ORIENTACAO","informado="+mirror+" rota="+routeMirror+" inicioX="+spawn.x+" largura="+width);
                mirror=routeMirror;
                diagnostic("decodeRoute","DEPOIS","passos="+sequence.length);
                prepareKeyboard();
                // Deltas are before each command. The clock drives input;
                // position observations never postpone or consume commands.
                index=0;completed=false;routeStartedAt=now;lastAppliedAt=now;lastPosition=null;lastPositionAt=-1;measuredVx=0;measuredVy=0;velocitySampleValid=false;previousWalk=null;lastWalkRecordedAt=0;lastMotionLogAt=-1000;lastFeedbackAt=now;velocityCoasting=false;expectedElapsed=Number(sequence[0][2]);
                due=now+expectedElapsed;running=true;
                diagnostic("iniciarRota","DEPOIS","passos="+sequence.length+" espera gravada="+expectedElapsed+"ms | sem antecipacao");
            }
            if (!running) {status(completed ? "Bot: comandos da rota finalizados | "+code+" | aguardando proxima rodada" : "Bot: aguardando inicio da rota | "+code,now);return;}
            var currentPosition:Object=observedPosition();var previousPosition:Object=lastPosition;
            var sampleMs:int=lastPositionAt>=0 ? now-lastPositionAt : 0;
            var validPositions:Boolean=previousPosition!=null && isFinite(Number(previousPosition.x)) && isFinite(Number(previousPosition.y)) && isFinite(Number(currentPosition.x)) && isFinite(Number(currentPosition.y));
            measuredVx=validPositions && sampleMs>0 && sampleMs<=250 ? (currentPosition.x-previousPosition.x)*1000/sampleMs : 0;
            measuredVy=validPositions && sampleMs>0 && sampleMs<=250 ? (currentPosition.y-previousPosition.y)*1000/sampleMs : 0;
            velocitySampleValid=validPositions && sampleMs>0 && sampleMs<=250;
            lastPosition=currentPosition;lastPositionAt=now;
            advanceJumpPlan(now);
            // Consume dense unchanged samples on the recorded clock, not one
            // frame per sample. Emit at most one timed input transition/frame;
            // explicit zero-delta commands retain their recorded same-frame order.
            var processed:int=0;var timedTransitions:int=0;
            while (running && now>=due && processed<64) {
                var inputChanged:Boolean=changesInput(sequence[index]);
                if(inputChanged && timedTransitions>0 && Number(sequence[index][2])>0)break;
                if(inputChanged)timedTransitions++;
                processed++;
                if(now-due>750){
                    diagnosticFrame=true;diagnostic("relogio","CONTINUAR","atraso="+Math.round(now-due)+"ms; executar um comando e preservar o proximo intervalo");
                }
                diagnosticFrame=true;
                diagnostic("apply","ANTES","passo="+index+" acao="+sequence[index][1]+" atraso="+Math.max(0,now-due)+"ms intervalo="+Number(sequence[index][2])+"ms mantido="+(now-lastAppliedAt)+"ms gravadoTotal="+expectedElapsed+"ms decorrido="+(now-routeStartedAt)+"ms atual="+currentPosition.x.toFixed(1)+","+currentPosition.y.toFixed(1));
                apply(sequence[index]);lastAppliedAt=now;if(inputChanged){lastFeedbackAt=now;velocityCoasting=false;}index++;
                diagnostic("apply","DEPOIS","passos="+index+"/"+sequence.length);
                if (index>=sequence.length) {
                    completed=true;running=false;release();diagnostic("concluirRota","DEPOIS","todos os passos executados");
                } else {
                    var nextInterval:Number=Number(sequence[index][2]);
                    expectedElapsed+=nextInterval;
                    var frameLateness:Number=Math.max(0,now-due);
                    // Keep the recorded phase across normal frame quantization.
                    // Large stalls rebase instead of compressing commands into a burst.
                    var nextChanges:Boolean=changesInput(sequence[index]);
                    var retainPhase:Boolean=nextInterval==0 || !nextChanges || (!inputChanged && timedTransitions==0) || (frameLateness<=50 && frameLateness<=nextInterval/2);
                    // Catching up passive samples must not erase the hold of a
                    // key transition actually emitted in this frame.
                    if(nextChanges && nextInterval>0 && inputChanged && due+nextInterval<=now)retainPhase=false;
                    due=retainPhase ? due+nextInterval : lastAppliedAt+nextInterval;
                    diagnostic("relogio.teclado","AGENDADO","intervalo="+nextInterval+"ms atrasoQuadro="+frameLateness+"ms fasePreservada="+retainPhase+" proximo="+due+"ms");
                }
            }
            if(running){advanceJumpPlan(now);synchronizeMotion(currentPosition,now);}
            status(running ? "Bot: reproduzindo "+code+" | "+index+"/"+sequence.length : "Bot: comandos da rota finalizados | "+code,now);
        }
        private function changesInput(step:Array):Boolean {
            // Completing releases all owned keys and is a real input transition.
            if(sequence!=null && step===sequence[sequence.length-1])return true;
            var action:String=String(step[1]);
            if(action=="walk")return previousWalk==null || Boolean(previousWalk.ml)!=Boolean(step[0].ml) || Boolean(previousWalk.mr)!=Boolean(step[0].mr);
            if(action=="crouch" || action=="duck")return Boolean(heldKeys[40])!=(Number(step[0])!=0);
            return false;
        }
        private function apply(step:Array):void {
            var action:String=String(step[1]);
            if(action=="walk"){
                var point:Object=step[0];var input:Object=routeInput(point);
                if(changesInput(step))movement(Boolean(input.left),Boolean(input.right),Boolean(heldKeys[38]));
                previousWalk=point;lastWalkRecordedAt=expectedElapsed;
            }else if(action=="crouch" || action=="duck")setKey(40,Number(step[0])!=0);
            // Cheese/hole markers consume time only. Real movement and native
            // game processing handle collection and server-confirmed arrival.
        }
    }
}
