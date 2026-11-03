// ActionScript 3 / MassDefault.as / Flash Player 10.3+ / start mass reduction disabled once per game load
package disney {
 import flash.display.MovieClip;
 import flash.events.Event;
 import flash.events.MouseEvent;
 public class MassDefault {
  public static function attach(root:MovieClip):void {
   root["mass_reduction"] = false;
   if (!root.stage) return;
   var initialize:Function = function(event:Event=null):void {
    try {
     var ui:Object = root["Interface"];
     var keys:Object = root["Keys"];
     if (!ui || !keys || !keys.is_selected || !keys.check_button_exec) return;
     var checkbox:Object = ui["mass_check_box"];
     if (!checkbox) return;
     if (checkbox[keys.is_selected]) checkbox[keys.check_button_exec](new MouseEvent("mouseDown"));
     root["mass_reduction"] = false;
     root.stage.removeEventListener(Event.ENTER_FRAME, initialize);
    } catch (ignored:Error) {}
   };
   root.stage.addEventListener(Event.ENTER_FRAME, initialize);
   initialize();
  }
 }
}
