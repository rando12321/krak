// ActionScript 3 / ConnectionGuard.as / Flash Player 10.3+ / preserve native networking and report local client faults
package disney {
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.Socket;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.describeType;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    public class ConnectionGuard {
        public static function attach(root:MovieClip):void {
            if (!root || !root.stage || root.stage.getChildByName("sddsConnectionStatus")) return;
            var status:TextField = new TextField(); status.name="sddsConnectionStatus";
            status.defaultTextFormat=new TextFormat("_sans",11,0xD5E2F4);
            status.background=true; status.backgroundColor=0x182235;
            status.height=24;status.selectable=true;status.mouseEnabled=false;
            status.text="Conexao original | diagnostico ativo";
            var layout:Function=function(event:Event=null):void { status.x=8;status.y=Math.max(40,root.stage.stageHeight-28);status.width=Math.max(240,root.stage.stageWidth-16); };
            layout();root.stage.addChild(status);root.stage.addEventListener(Event.RESIZE,layout);
            var seen:Dictionary=new Dictionary(true);var pending:Array=[];var errors:int=0;var lastDisplay:int=-1000;var reports:Object={};var lastCheck:int=-2000;
            var activeOptions:Function=function():String {
                var result:Array=[];
                for each(var name:String in ["auto_play","recording","change_jump_delay","change_jump_height","change_jump_speed","change_movement_speed","mass_reduction","insta_death","insta_win","no_delay","no_bulle","soft_mode","macro"]) if(root[name])result.push(name);
                return result.join(",");
            };
            var report:Function=function(kind:String,code:int,channel:String):void {
                try {
                    var data:URLVariables=new URLVariables();data.event=kind;data.code=code;data.channel=channel;
                    data.elapsed=getTimer();data.options=activeOptions();
                    var request:URLRequest=new URLRequest(root["host_url"]+"client_diagnostics?access_token="+encodeURIComponent(String(root["access_token"]))+"&flash_token="+encodeURIComponent(String(root["tfmdisney"].data.flash_token)));
                    request.method=URLRequestMethod.POST;request.data=data;
                    var loader:URLLoader=new URLLoader();pending.push(loader);
                    var release:Function=function(event:Event):void { var at:int=pending.indexOf(loader);if(at>=0)pending.splice(at,1); };
                    loader.addEventListener(Event.COMPLETE,release);loader.addEventListener(IOErrorEvent.IO_ERROR,release);loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,release);
                    loader.load(request);
                }catch(ignored:Error){}
            };
            var observe:Function=function(instance:Object,channel:String):void {
                if(!instance)return;
                var candidates:Array=[];
                if(instance is Socket)candidates.push(instance);
                try {
                    var description:XML=describeType(instance);
                    for each(var variable:XML in description.variable) {
                        var value:Object=instance[String(variable.@name)];
                        if(value is Socket)candidates.push(value);
                    }
                    for each(var accessor:XML in description.accessor) {
                        if(String(accessor.@access)=="writeonly")continue;
                        var item:Object=instance[String(accessor.@name)];
                        if(item is Socket)candidates.push(item);
                    }
                }catch(ignored:Error){}
                for each(var socket:Socket in candidates) {
                    if(seen[socket])continue;
                    seen[socket]=true;
                    socket.addEventListener(Event.CLOSE,function(event:Event):void {
                        status.text="Socket "+channel+" encerrado | consulte logs-client/flash-diagnostics.jsonl";
                        report("socket_close",0,channel);
                    });
                    socket.addEventListener(IOErrorEvent.IO_ERROR,function(event:IOErrorEvent):void {
                        status.text="Erro de rede "+channel+" #"+event.errorID;report("io_error",event.errorID,channel);
                    });
                    socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,function(event:SecurityErrorEvent):void {
                        status.text="Erro de seguranca de rede "+channel+" #"+event.errorID;report("security_error",event.errorID,channel);
                    });
                }
            };
            root.stage.removeEventListener(Event.ENTER_FRAME,root["loop_game"]);
            root.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void {
                try {root["loop_game"](event);}catch(error:Error) {
                    errors++;
                    var now:int=getTimer();
                    if(now-lastDisplay>=1000) {lastDisplay=now;status.text="Falha do client #"+error.errorID+" ("+errors+") | rede original preservada";}
                    var previous:Object=reports[String(error.errorID)];
                    if(previous==null || now-Number(previous)>30000) {reports[String(error.errorID)]=now;report("frame_error",error.errorID,"client");}
                }
                if(getTimer()-lastCheck>1000) {
                    lastCheck=getTimer();
                    try {
                        var keys:Object=root["Keys"];var cls:Object=keys.socket_class;
                        if(cls) {observe(cls[keys.main_socket_instance],"main");observe(cls[keys.bulle_socket_instance],"bulle");}
                    }catch(ignored:Error){}
                }
            });
            report("guard_ready",0,"client");
        }
    }
}
