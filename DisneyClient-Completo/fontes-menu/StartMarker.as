// ActionScript 3 / StartMarker.as / Flash Player 10.3+ / local startup message after game SWF completion
package disney {
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.filters.DropShadowFilter;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    public class StartMarker {
        public static function attach(root:MovieClip):void {
            if (!root || !root.stage) return;
            var stage:Stage = root.stage;
            if (stage.getChildByName("sddsCheatsStartText")) return;
            var message:TextField = new TextField();
            message.name = "sddsCheatsStartText";
            message.defaultTextFormat = new TextFormat("_sans", 18, 0xFFFF00, true);
            message.textColor = 0xFFFF00;
            message.autoSize = TextFieldAutoSize.LEFT;
            message.text = "Sdds CHEATS start";
            message.selectable = false;
            message.mouseEnabled = false;
            message.filters = [new DropShadowFilter(1, 90, 0x000000, 1, 2, 2, 1, 2)];
            var position:Function = function(event:Event=null):void {
                message.x = Math.max(8, (stage.stageWidth - message.width) / 2);
                message.y = 8;
            };
            position();
            stage.addChild(message);
            stage.addEventListener(Event.RESIZE, position);
        }
    }
}
