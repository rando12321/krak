package disney {
 import flash.display.MovieClip;import flash.display.DisplayObject;import flash.display.DisplayObjectContainer;import flash.display.Sprite;import flash.events.Event;import flash.events.MouseEvent;import flash.geom.Point;import flash.geom.Rectangle;import flash.utils.Dictionary;
 public class WheelScrollFixV2 {
  private static var installed:Dictionary=new Dictionary(true);
  private var root:MovieClip;private var viewport:Sprite;private var content:DisplayObjectContainer;private var ui:Object;private var scroll:Number=0;private var active:Boolean=false;private var prepared:Dictionary=new Dictionary(true);
  public function WheelScrollFixV2(value:MovieClip){root=value;if(root.stage){root.stage.addEventListener(MouseEvent.MOUSE_WHEEL,wheel,true,100000);root.stage.addEventListener(MouseEvent.MOUSE_WHEEL,wheel,false,100000);}}
  public static function attach(value:MovieClip):void{if(!value || !value.stage || installed[value])return;var fix:WheelScrollFixV2=new WheelScrollFixV2(value);installed[value]=fix;value.stage.addEventListener(Event.ENTER_FRAME,function(e:Event):void{fix.update();});}
  private function prepare(node:DisplayObjectContainer,depth:int=0):void{
   if(depth>8 || prepared[node])return;
   var k:Object=root["Keys"];
   try{if(k && k.set_scrollable && k.set_scrollable in node && node[k.set_scrollable] is Function)node[k.set_scrollable](false);}catch(error:Error){}
   node.scrollRect=null;
   for(var i:int=0;i<node.numChildren;i++){
    var child:DisplayObject=node.getChildAt(i);var mask:DisplayObject=child.mask;
    if(mask && mask.parent===node){child.mask=null;mask.visible=false;child.y=0;}
    if(child.x>=500 && child.width<=16 && child.height>=80){child.visible=false;if(child is Sprite){Sprite(child).mouseEnabled=false;Sprite(child).mouseChildren=false;}continue;}
    // Nested native layout wrappers can retain a second clipping rectangle.
    if(child is DisplayObjectContainer)prepare(child as DisplayObjectContainer,depth+1);
   }
   prepared[node]=true;
  }
  private function apply():void{
   if(!viewport || !content || !viewport.scrollRect)return;var rect:Rectangle=viewport.scrollRect;var bottom:Number=0;
   for(var i:int=0;i<content.numChildren;i++){var child:DisplayObject=content.getChildAt(i);if(child.visible)bottom=Math.max(bottom,child.getBounds(viewport).bottom);}
   var maximum:Number=Math.max(0,bottom-rect.height);if(maximum>0)maximum+=8;scroll=Math.max(0,Math.min(maximum,scroll));viewport.scrollRect=new Rectangle(0,scroll,rect.width,rect.height);
  }
  public function wheel(e:MouseEvent):void{
   update();if(!active || !viewport || !viewport.parent)return;
   var rect:Rectangle=viewport.scrollRect;var point:Point=viewport.parent.globalToLocal(new Point(e.stageX,e.stageY));
   var inside:Boolean=point.x>=viewport.x && point.y>=viewport.y && point.x<=viewport.x+rect.width*viewport.scaleX && point.y<=viewport.y+rect.height*viewport.scaleY;
   if(!inside)return;scroll-=e.delta*22;apply();e.preventDefault();e.stopImmediatePropagation();
  }
  public function update():void{
   var next:Object=root["Interface"];var general:DisplayObjectContainer=next ? next["general_ui"] as DisplayObjectContainer : null;var options:DisplayObjectContainer=next ? next["options_ui"] as DisplayObjectContainer : null;var view:Sprite=options && options.parent ? options.parent as Sprite : null;
   if(!general || !view || !view.scrollRect || !view.stage || !view.visible){active=false;return;}
   var panel:DisplayObject=next["menu_ui"] as DisplayObject;if(panel && (!panel.parent || !panel.visible)){active=false;return;}
   var visibleNow:Boolean=view.contains(general) && general.visible;
   if(visibleNow){if(!active || viewport!==view || content!==general || ui!==next)scroll=0;viewport=view;prepare(options);prepare(general);content=general;ui=next;active=true;apply();}else active=false;
  }
 }
}
