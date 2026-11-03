// ActionScript 3 / RgbMouseV3.as / Flash Player 10.3+ / local mouse tint toggle with restoration
package disney {
 import flash.display.MovieClip;
 import flash.display.Sprite;
 import flash.display.DisplayObject;
 import flash.display.DisplayObjectContainer;
 import flash.events.Event;
 import flash.events.MouseEvent;
 import flash.geom.ColorTransform;
 import flash.text.TextField;
 import flash.text.TextFormat;
 import flash.utils.getTimer;
 import flash.utils.Dictionary;
 public class RgbMouseV3 {
  private static var instances:Dictionary = new Dictionary(true);
  private var root:MovieClip;
  private var enabled:Boolean = false;
  private var clip:DisplayObject;
  private var original:ColorTransform;
  private var row:Sprite;
  private var box:Sprite;
  private var host:DisplayObjectContainer;
  private var caption:TextField;
  private function status(text:String):void {
   if(caption)caption.text="RGB MODE"+(enabled ? " - "+text : "");
   if(enabled && root.stage){var diagnostic:TextField=root.stage.getChildByName("sddsConnectionStatus") as TextField;if(diagnostic)diagnostic.text="RGB MODE: "+text;}
  }
  public function RgbMouseV3(target:MovieClip) { root=target; }
  public static function attach(target:MovieClip):void {
   if (!target || !target.stage || instances[target]) return;
   var mode:RgbMouseV3 = new RgbMouseV3(target); instances[target]=mode;
   target.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void { mode.update(); });
  }
  private function paint():void {
   box.graphics.clear();box.graphics.lineStyle(1,enabled ? 0x39D9E7 : 0x65768C);
   box.graphics.beginFill(enabled ? 0x39D9E7 : 0x1B2938);box.graphics.drawRoundRect(0,0,11,11,4);box.graphics.endFill();
  }
  private function bindMenu():void {
   var ui:Object=root["Interface"];if(!ui)return;
   var container:DisplayObjectContainer=ui["general_ui"] as DisplayObjectContainer;
   if(!container || host===container)return;
   if(row && row.parent)row.parent.removeChild(row);
   host=container;row=new Sprite();row.name="sddsRgbMouseV3Control";row.buttonMode=true;row.mouseChildren=false;
   row.x=0;row.y=Math.ceil(container.height)+10;
   row.graphics.beginFill(0,0);row.graphics.drawRect(0,0,450,24);row.graphics.endFill();
   box=new Sprite();box.y=5;row.addChild(box);
   var label:TextField=new TextField();caption=label;label.defaultTextFormat=new TextFormat("_sans",12,0xD8E2EE);
   label.text="RGB MODE";label.x=18;label.y=1;label.width=420;label.height=23;label.selectable=false;row.addChild(label);
   row.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void {
    enabled=!enabled;paint();if(!enabled)restore();status(enabled ? "aguardando rato" : "");event.stopPropagation();
   });
   paint();container.addChild(row);
  }
  private function restore():void {
   if(clip && original)clip.transform.colorTransform=original;
   clip=null;original=null;
  }
  public function update():void {
   try { bindMenu(); }catch(menuError:Error){}
   try {
    var k:Object=root["Keys"];var game:Object=root["tfm"];
    var player:Object=k && game && k.player ? game[k.player] : null;
    var current:DisplayObject=player as DisplayObject;
    if(!current && player && k.player_bitmap && k.player_bitmap in player)current=player[k.player_bitmap] as DisplayObject;
    if(!enabled){restore();return;}
    if(!current){restore();status(!k ? "sem simbolos" : !game ? "sem jogo" : !player ? "aguardando jogador" : "imagem nao encontrada");return;}
    if(current!==clip){restore();clip=current;original=clip.transform.colorTransform;}
    var hue:Number=(getTimer()%6000)/1000;var segment:int=int(hue);var rising:int=int((hue-segment)*255);var falling:int=255-rising;
    var r:int=0;var g:int=0;var b:int=0;
    if(segment==0){r=255;g=rising;}else if(segment==1){r=falling;g=255;}else if(segment==2){g=255;b=rising;}
    else if(segment==3){g=falling;b=255;}else if(segment==4){r=rising;b=255;}else{r=255;b=falling;}
    clip.transform.colorTransform=new ColorTransform(original.redMultiplier*0.35,original.greenMultiplier*0.35,original.blueMultiplier*0.35,original.alphaMultiplier,original.redOffset+r*0.65,original.greenOffset+g*0.65,original.blueOffset+b*0.65,original.alphaOffset);
    status("ativo");
   }catch(error:Error){restore();status("erro #"+error.errorID);}
  }
 }
}
