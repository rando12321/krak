// ActionScript 3 / PlayerScrollFix.as / Flash Player 10.3+ / one bounded scroll owner for Player panel
package disney {
 import flash.display.MovieClip;import flash.display.DisplayObject;import flash.display.DisplayObjectContainer;import flash.display.Sprite;import flash.events.Event;import flash.events.MouseEvent;import flash.geom.Rectangle;import flash.utils.Dictionary;
 public class PlayerScrollFix {
  private static var installed:Dictionary=new Dictionary(true);private var root:MovieClip;private var viewport:Sprite;private var content:DisplayObjectContainer;private var ui:Object;private var scroll:Number=0;private var active:Boolean=false;private var prepared:Dictionary=new Dictionary(true);
  public function PlayerScrollFix(value:MovieClip){root=value;}
  public static function attach(value:MovieClip):void{if(!value || !value.stage || installed[value])return;var fix:PlayerScrollFix=new PlayerScrollFix(value);installed[value]=fix;value.stage.addEventListener(Event.ENTER_FRAME,function(e:Event):void{fix.update();});}
  private function prepare(node:DisplayObjectContainer):void{
   if(prepared[node])return;var k:Object=root["Keys"];
   if(k && k.set_scrollable && node[k.set_scrollable] is Function)node[k.set_scrollable](false);
   for(var i:int=0;i<node.numChildren;i++){var child:DisplayObject=node.getChildAt(i);var mask:DisplayObject=child.mask;
    if(mask && mask.parent===node){child.mask=null;mask.visible=false;child.y=0;}
    if(child.x>=500 && child.width<=16 && child.height>=80){child.visible=false;if(child is Sprite){Sprite(child).mouseEnabled=false;Sprite(child).mouseChildren=false;}}
   }
   prepared[node]=true;
  }
  private function apply():void{if(!viewport || !content || !viewport.scrollRect)return;var rect:Rectangle=viewport.scrollRect;var bottom:Number=0;for(var i:int=0;i<content.numChildren;i++){var child:DisplayObject=content.getChildAt(i);if(child.visible)bottom=Math.max(bottom,child.getBounds(viewport).bottom);}var maximum:Number=Math.max(0,bottom-rect.height);if(maximum>0)maximum+=8;scroll=Math.max(0,Math.min(maximum,scroll));viewport.scrollRect=new Rectangle(0,scroll,rect.width,rect.height);}
  public function wheel(e:MouseEvent):void{if(!active)return;scroll-=e.delta*22;apply();e.preventDefault();e.stopImmediatePropagation();}
  public function update():void{
   var next:Object=root["Interface"];var general:DisplayObjectContainer=next ? next["general_ui"] as DisplayObjectContainer : null;var options:DisplayObject=next ? next["options_ui"] as DisplayObject : null;var view:Sprite=options && options.parent ? options.parent as Sprite : null;
   if(!general || !view || !view.scrollRect)return;
   if(view!==viewport){if(viewport){viewport.removeEventListener(MouseEvent.MOUSE_WHEEL,wheel,true);viewport.removeEventListener(MouseEvent.MOUSE_WHEEL,wheel,false);}viewport=view;viewport.addEventListener(MouseEvent.MOUSE_WHEEL,wheel,true,2000);viewport.addEventListener(MouseEvent.MOUSE_WHEEL,wheel,false,2000);active=false;}
   var visibleNow:Boolean=viewport.contains(general);if(visibleNow){prepare(general);if(!active || content!==general || ui!==next)scroll=0;content=general;ui=next;active=true;apply();}else active=false;
  }
 }
}
