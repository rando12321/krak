// ActionScript 3 / NativeControls.as / Flash Player 10.3+ + local Windows backend / local welcome message and WJ Fly menu control
package disney {
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    public class NativeControls {
        private static var attached:Dictionary=new Dictionary(true);
        private var root:MovieClip;
        private var panels:Dictionary=new Dictionary(true);
        private var welcome:Boolean=false;
        private var checked:int=-2000;
        private var enabled:Boolean=false;
        private var pending:Boolean=false;
        private var message:String="WJ Fly desligado | Adobe_10.exe x86";
        private var rows:Array=[];
        private var requests:Array=[];
        public static function attach(target:MovieClip):void {
            if(!target || !target.stage || attached[target])return;
            var controls:NativeControls=new NativeControls(target);attached[target]=controls;
            target.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void{controls.tick();});
        }
        public function NativeControls(target:MovieClip){root=target;}
        private function text(value:String,size:int,color:uint):TextField {
            var field:TextField=new TextField();field.defaultTextFormat=new TextFormat("_sans",size,color);
            field.text=value;field.width=510;field.height=24;field.selectable=false;field.mouseEnabled=false;return field;
        }
        public function tick(now:int=-1):void {
            if(now<0)now=getTimer();
            if(now-checked<500)return;checked=now;
            try {
                var keys:Object=root["Keys"];
                if(!welcome && keys && root["tfm"] && root["tfm"][keys.player] && keys.chat_class2 && keys.chat_message2) {
                    keys.chat_class2[keys.chat_message2]("<BL>BEM VINDO AO SDDS CHEATS</BL>");welcome=true;
                }
            }catch(ignored:Error){}
            try {
                var ui:Object=root["Interface"];
                var panel:DisplayObjectContainer=ui ? ui["general_ui"] as DisplayObjectContainer : null;
                if(panel && !panels[panel]) {
                    panels[panel]=true;
                    var row:Sprite=new Sprite();row.name="sddsWjFly";row.y=panel.height+10;
                    row.buttonMode=true;row.mouseChildren=false;
                    var title:TextField=text("WJ Fly [AoB]",13,0xECF1FF);title.x=29;title.y=5;row.addChild(title);
                    var status:TextField=text(message,10,0x9EAAC3);status.x=8;status.y=29;status.wordWrap=true;status.height=42;row.addChild(status);
                    panel.addChild(row);rows.push({row:row,status:status});
                    row.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void{event.stopImmediatePropagation();toggle();});
                    draw();
                }
            }catch(ignored:Error){}
        }
        private function draw():void {
            for each(var entry:Object in rows) {
                var row:Sprite=entry.row;
                row.graphics.clear();row.graphics.beginFill(0x111B2A);row.graphics.drawRoundRect(0,0,525,76,8,8);row.graphics.endFill();
                row.graphics.lineStyle(1,enabled ? 0x6DD8B4 : 0x65718C);row.graphics.beginFill(enabled ? 0x6DD8B4 : 0x1A2638);
                row.graphics.drawRoundRect(8,10,12,12,4,4);row.graphics.endFill();
                entry.status.text=message;row.alpha=pending ? 0.6 : 1;
            }
        }
        private function toggle():void {
            if(pending)return;
            pending=true;message=enabled ? "Restaurando bytes originais..." : "Buscando assinatura WJ Fly no Flash...";draw();
            var loader:URLLoader=new URLLoader();requests.push(loader);
            var release:Function=function():void{var at:int=requests.indexOf(loader);if(at>=0)requests.splice(at,1);pending=false;draw();};
            loader.addEventListener(Event.COMPLETE,function(event:Event):void {
                try {
                    var result:Object=com.adobe.serialization.json.JSON.decode(String(loader.data));
                    if(result.enabled is Boolean)enabled=Boolean(result.enabled);
                    message=String(result.message || "Resposta desconhecida do backend");
                }catch(error:Error){message="Resposta invalida do componente WJ Fly";}
                release();
            });
            loader.addEventListener(IOErrorEvent.IO_ERROR,function(event:IOErrorEvent):void {
                try {var result:Object=com.adobe.serialization.json.JSON.decode(String(loader.data));message=String(result.message || "Falha no componente WJ Fly");}
                catch(ignored:Error){message="Falha no componente WJ Fly; confira o backend.log";}
                release();
            });
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,function(event:SecurityErrorEvent):void{message="Flash bloqueou o acesso ao backend local";release();});
            try {
                var data:URLVariables=new URLVariables();data.feature="wj_fly";data.enabled=enabled ? "0" : "1";
                var request:URLRequest=new URLRequest(root["host_url"]+"native_patch?access_token="+encodeURIComponent(String(root["access_token"]))+"&flash_token="+encodeURIComponent(String(root["tfmdisney"].data.flash_token)));
                request.method=URLRequestMethod.POST;request.data=data;loader.load(request);
            }catch(error:Error){message="Falha local ao iniciar WJ Fly #"+error.errorID;release();}
        }
    }
}
