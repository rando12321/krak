// ActionScript 3 / RgbMarkerButton.as / Flash Player 10.3+ / local startup message after game SWF completion
package disney {
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.utils.getTimer;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.filters.DropShadowFilter;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    public class RgbMarkerButton {
        public static function attach(root:MovieClip):void {
            if (!root || !root.stage) return;
            var stage:Stage = root.stage;
            if (stage.getChildByName("sddsCheatsStartText")) return;
            var message:TextField = new TextField();
            message.name = "sddsCheatsStartText";
            message.defaultTextFormat = new TextFormat("_sans", 18, 0xFF0000, true);
            message.textColor = 0xFF0000;
            message.autoSize = TextFieldAutoSize.LEFT;
            message.text = "Sdds Menu";
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
            message.addEventListener(Event.ENTER_FRAME, function(event:Event):void {
                var hue:Number = (getTimer() % 6000) / 1000;
                var segment:int = int(hue);
                var rising:int = int((hue - segment) * 255);
                var falling:int = 255 - rising;
                var red:int = 0;
                var green:int = 0;
                var blue:int = 0;
                if (segment == 0) { red = 255; green = rising; }
                else if (segment == 1) { red = falling; green = 255; }
                else if (segment == 2) { green = 255; blue = rising; }
                else if (segment == 3) { green = falling; blue = 255; }
                else if (segment == 4) { red = rising; blue = 255; }
                else { red = 255; blue = falling; }
                message.textColor = (red << 16) | (green << 8) | blue;
                var button:Sprite = stage.getChildByName("disneyMenuButton") as Sprite;
                if (button) {
                    var color:uint = message.textColor;
                    button.graphics.clear();
                    button.graphics.lineStyle(1, color, 1);
                    button.graphics.beginFill(0x141B2A, 0.98);
                    button.graphics.drawRoundRect(0, 0, 100, 28, 8, 8);
                    button.graphics.endFill();
                    for (var i:int = 0; i < button.numChildren; i++) {
                        var label:TextField = button.getChildAt(i) as TextField;
                        if (label) label.textColor = color;
                    }
                }
                position();
            });
        }
    }
}
