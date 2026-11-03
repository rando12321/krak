// ActionScript 3 / VisualNamesV2.as / Flash Player 10.3+ / independent local nickname and title overlays
package disney {
 import flash.display.MovieClip;
 import flash.display.Sprite;
 import flash.display.DisplayObject;
 import flash.display.DisplayObjectContainer;
 import flash.events.Event;
 import flash.events.MouseEvent;
 import flash.geom.Rectangle;
 import flash.text.TextField;
 import flash.text.TextFieldType;
 import flash.text.TextFormat;
 import flash.text.TextFieldAutoSize;
 import flash.utils.Dictionary;
 public class VisualNamesV2 {
  private static var attached:Dictionary=new Dictionary(true);
  private var root:MovieClip;
  private var host:DisplayObjectContainer;
  private var rows:Array=[];
  private var options:Array=[{title:"Nick",enabled:false,value:"",row:null,box:null,input:null,overlay:null},{title:"Titulo",enabled:false,value:"",row:null,box:null,input:null,overlay:null}];
  private var player:DisplayObjectContainer;
  public function VisualNamesV2(target:MovieClip){root=target;}
  public static function attach(target:MovieClip):void {
   if(!target || !target.stage || attached[target])return;
   var names:VisualNamesV2=new VisualNamesV2(target);attached[target]=names;
   target.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void{names.update();});
  }
  private function paint(option:Object):void {
   var box:Sprite=option.box;box.graphics.clear();box.graphics.lineStyle(1,0x50747C);box.graphics.beginFill(0x1C3038);box.graphics.drawCircle(5.5,5.5,5.5);box.graphics.endFill();
   if(option.enabled){box.graphics.lineStyle(0,0,0);box.graphics.beginFill(0xD6EDF2);box.graphics.drawCircle(5.5,5.5,3);box.graphics.endFill();}
  }
  private function makeRow(option:Object,y:Number):void {
   var row:Sprite=new Sprite();row.name="sddsVisual"+option.title;row.x=0;row.y=y;
   var toggle:Sprite=new Sprite();toggle.buttonMode=true;toggle.mouseChildren=false;toggle.graphics.beginFill(0,0);toggle.graphics.drawRect(0,0,132,25);toggle.graphics.endFill();row.addChild(toggle);
   var box:Sprite=new Sprite();box.y=6;toggle.addChild(box);option.box=box;
   var label:TextField=new TextField();label.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);label.text=option.title+" (visual)";label.x=18;label.y=1;label.width=112;label.height=24;label.selectable=false;toggle.addChild(label);
   var input:TextField=new TextField();input.type=TextFieldType.INPUT;input.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);input.background=true;input.backgroundColor=0x101827;input.border=true;input.borderColor=0x35405B;input.x=140;input.y=2;input.width=240;input.height=21;input.maxChars=40;input.multiline=false;input.text=option.value;row.addChild(input);option.input=input;option.row=row;
   input.addEventListener(Event.CHANGE,function(event:Event):void{option.value=input.text;});
   input.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void{event.stopPropagation();});
   toggle.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void{option.enabled=!option.enabled;paint(option);render();event.stopPropagation();});
   paint(option);host.addChild(row);rows.push(row);
  }
  private function menu():void {
   var ui:Object=root["Interface"];var container:DisplayObjectContainer=ui ? ui["general_ui"] as DisplayObjectContainer : null;
   if(!container || container===host)return;
   for each(var old:Sprite in rows)if(old.parent)old.parent.removeChild(old);rows=[];host=container;
   var y:Number=Math.ceil(container.height)+8;
   for each(var option:Object in options){makeRow(option,y);y+=28;}
  }
  private function clear():void {
   for each(var option:Object in options){var overlay:Sprite=option.overlay as Sprite;if(overlay && overlay.parent)overlay.parent.removeChild(overlay);option.overlay=null;}
   player=null;
  }
  private function render():void {
   if(!player)return;
   var k:Object=root["Keys"];var avatar:DisplayObject=k.player_bitmap && k.player_bitmap in player ? player[k.player_bitmap] as DisplayObject : null;
   var top:Number=avatar ? avatar.getBounds(player).top-16 : -48;
   var width:Number=80;
   var center:Number=0;var nearest:Number=-100000;
   // Native nameplates are often bitmaps, so cover only each selected line.
   for(var i:int=0;i<player.numChildren;i++){
    var child:DisplayObject=player.getChildAt(i);if(child.name.indexOf("sddsVisualOverlay")==0 || child===avatar)continue;
    var bounds:Rectangle=child.getBounds(player);
    if(bounds.width>=20 && bounds.width<=400 && bounds.height>=8 && bounds.height<=40 && bounds.bottom<=-15){if(bounds.bottom>nearest){nearest=bounds.bottom;top=bounds.top+1;center=bounds.x+bounds.width/2;width=bounds.width;}}
   }
   for(var index:int=0;index<options.length;index++){
    var option:Object=options[index];var overlay:Sprite=option.overlay as Sprite;
    if(!overlay){overlay=new Sprite();overlay.name="sddsVisualOverlay"+index;overlay.mouseEnabled=false;overlay.mouseChildren=false;option.overlay=overlay;player.addChild(overlay);
     var text:TextField=new TextField();text.name="value";text.defaultTextFormat=new TextFormat("_sans",index==0 ? 12 : 10,index==0 ? 0xFFFFFF : 0xF3D9A5);text.autoSize=TextFieldAutoSize.LEFT;text.selectable=false;text.mouseEnabled=false;overlay.addChild(text);
    }
    overlay.visible=Boolean(option.enabled && String(option.value).length);
    if(!overlay.visible)continue;
    var field:TextField=overlay.getChildAt(0) as TextField;field.text=String(option.value);field.x=-field.width/2;field.y=-2;
    var coverWidth:Number=Math.max(width,field.width+10);overlay.graphics.clear();overlay.graphics.beginFill(0x3E424D,1);overlay.graphics.drawRoundRect(-coverWidth/2,-1,coverWidth,15,5,5);overlay.graphics.endFill();
    overlay.x=center;overlay.y=top+index*14;player.setChildIndex(overlay,player.numChildren-1);
   }
  }
  public function update():void {
   try{menu();var k:Object=root["Keys"];var game:Object=root["tfm"];var current:DisplayObjectContainer=k && game && k.player ? game[k.player] as DisplayObjectContainer : null;
    if(current!==player){clear();player=current;}render();
   }catch(error:Error){if(root.stage){var status:TextField=root.stage.getChildByName("sddsConnectionStatus") as TextField;if(status)status.text="Nick/Titulo visual: erro #"+error.errorID;}}
  }
 }
}
