// ActionScript 3 / WelcomeOnly.as / Flash Player 10.3+ + local Windows backend / local welcome message and WJ Fly menu control
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
    public class WelcomeOnly {
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
            var controls:WelcomeOnly=new WelcomeOnly(target);attached[target]=controls;
            target.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void{controls.tick();});
        }
        public function WelcomeOnly(target:MovieClip){root=target;}
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
        }
    }
}
