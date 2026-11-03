// ActionScript 3 / PerformanceControlsV2.as / Flash Player 10.3+ / real frame counter, native command RTT and frame-rate controls
package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.display.DisplayObject;import flash.display.DisplayObjectContainer;
 import flash.events.Event;import flash.events.MouseEvent;import flash.events.KeyboardEvent;
 import flash.text.TextField;import flash.text.TextFieldType;import flash.text.TextFormat;
 import flash.utils.Dictionary;import flash.utils.getTimer;
 public class PerformanceControlsV2 {
  private static var attached:Dictionary=new Dictionary(true);
  private var root:MovieClip;
  private var ui:Object;
  private var host:DisplayObjectContainer;
  private var controls:Array=[{id:"ping",title:"Mostrar ping (RTT /ping)",on:false},{id:"fps",title:"Mostrar FPS",on:false},{id:"limit",title:"Limitar FPS",on:false},{id:"unlock",title:"Acima de 60 FPS (alvo 120)",on:false}];
  private var input:TextField;private var info:TextField;private var hud:TextField;
  private var originalRate:Number;private var lastTarget:Number=-1;private var limitValue:Number=60;
  private var frameStart:int=-1;private var frames:int=0;private var actualFps:Number=0;private var uiTick:int=-1000;
  private var nextPing:int=0;private var pingSent:int=-1;private var pingValue:int=-1;private var pingState:String="aguardando";
  private var texts:Dictionary=new Dictionary(true);private var nextScan:int=0;
  public function PerformanceControlsV2(target:MovieClip){root=target;root["mass_reduction"]=false;root["change_movement_speed"]=false;originalRate=target.stage ? target.stage.frameRate : 60;}
  public static function attach(target:MovieClip):void {
   if(!target || !target.stage || attached[target])return;
   var control:PerformanceControlsV2=new PerformanceControlsV2(target);attached[target]=control;
   target.stage.addEventListener(Event.ENTER_FRAME,function(e:Event):void{control.update();},false,1000);
   target.stage.addEventListener(Event.RESIZE,function(e:Event):void{control.positionHud();});
  }
  private function option(id:String):Object{for each(var item:Object in controls)if(item.id==id)return item;return null;}
  private function paint(item:Object):void {
   var box:Sprite=item.box as Sprite;if(!box)return;box.graphics.clear();box.graphics.lineStyle(1,0x50747C);box.graphics.beginFill(0x1C3038);box.graphics.drawCircle(5.5,5.5,5.5);box.graphics.endFill();
   if(item.on){box.graphics.lineStyle(0,0,0);box.graphics.beginFill(0xD6EDF2);box.graphics.drawCircle(5.5,5.5,3);box.graphics.endFill();}
  }
  private function label(text:String,width:Number=490):TextField {
   var field:TextField=new TextField();field.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);field.text=text;field.width=width;field.height=24;field.selectable=false;field.mouseEnabled=false;return field;
  }
  private function nativeRow(node:DisplayObject,parent:DisplayObjectContainer):DisplayObject {
   if(!node || !parent)return null;
   // A native section wraps all rows in an internal content Sprite.
   // Never climb to and remove that shared section container.
   var original:DisplayObject=node;var type:Class=root["Keys"] ? root["Keys"].ui_element_class as Class : null;
   node=node.parent;
   while(node && node!==parent){
    if(type && node is type)return node;
    if(!type && node.width>=80 && node.height>0 && node.height<=40)return node;
    node=node.parent;
   }
   return null;
  }

  private function removeRows(parent:DisplayObjectContainer,rows:Array):Number {
   rows.sortOn("y",Array.NUMERIC);var first:Number=NaN;var removed:Number=0;
   for each(var row:DisplayObject in rows){
    if(row.parent!==parent)continue;var y:Number=row.y;var amount:Number=26;
    if(!isFinite(first))first=y;
    // The original native control rows are 24 pixels tall with a two-pixel gap.
    parent.removeChild(row);
    for(var i:int=0;i<parent.numChildren;i++){var child:DisplayObject=parent.getChildAt(i);if(child.y>y)child.y-=amount;}
    removed+=amount;
   }
   return isFinite(first) ? first : Math.ceil(parent.height)+8;
  }
  private function retire(old:Object):Number {
   var general:DisplayObjectContainer=old["general_ui"] as DisplayObjectContainer;var rows:Array=[];
   for each(var name:String in ["mass","movement"]){
    var box:DisplayObject=old[name=="mass" ? "mass_check_box" : "movement_check_box"] as DisplayObject;
    var row:DisplayObject=nativeRow(box,general);if(row && row.parent)removeRows(row.parent,[row]);
    var entry:Object=old["keys"] ? old["keys"][name] : null;
    if(entry){
     var shortcuts:Object=root["KeyboardHandler"] ? root["KeyboardHandler"]["shortcuts"] : null;
     if(shortcuts)for(var key:String in shortcuts)if(shortcuts[key]===entry)delete shortcuts[key];
     var keysHost:DisplayObjectContainer=old["keys_ui"] as DisplayObjectContainer;
     var shortcutRow:DisplayObject=nativeRow(entry.button as DisplayObject,keysHost);
     if(shortcutRow && shortcutRow.parent)removeRows(shortcutRow.parent,[shortcutRow]);
     delete old["keys"][name];
    }
   }
   return Math.ceil(general.getBounds(general).bottom)+8;
  }
  private function bindMenu():void {
   var current:Object=root["Interface"];if(!current || current===ui || !current["general_ui"])return;
   var general:DisplayObjectContainer=current["general_ui"] as DisplayObjectContainer;if(!general)return;
   ui=current;host=general;var start:Number=retire(ui);var added:Number=144;
   for(var index:int=0;index<host.numChildren;index++){var existing:DisplayObject=host.getChildAt(index);if(existing.y>=start)existing.y+=added;}
   for(var n:int=0;n<controls.length;n++)addRow(controls[n],start+n*26);
   info=label("FPS: use um limite de 1 a 120; ping medido pelo servidor.");info.name="sddsPerformanceInfo";info.x=0;info.y=start+106;info.width=510;info.height=36;info.wordWrap=true;host.addChild(info);
  }
  private function addRow(item:Object,y:Number):void {
   var row:Sprite=new Sprite();row.name="sddsPerformance_"+item.id;row.x=0;row.y=y;
   var toggle:Sprite=new Sprite();toggle.buttonMode=true;toggle.mouseChildren=false;toggle.graphics.beginFill(0,0);toggle.graphics.drawRect(0,0,item.id=="limit" ? 150 : 480,25);toggle.graphics.endFill();row.addChild(toggle);
   var box:Sprite=new Sprite();box.y=5;item.box=box;toggle.addChild(box);var text:TextField=label(item.title,item.id=="limit" ? 132 : 470);text.x=18;toggle.addChild(text);paint(item);
   toggle.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void {
    item.on=!item.on;
    if(item.id=="limit" && item.on){option("unlock").on=false;paint(option("unlock"));}
    if(item.id=="unlock" && item.on){option("limit").on=false;paint(option("limit"));}
    if(item.id=="ping"){pingSent=-1;pingValue=-1;nextPing=0;pingState=item.on ? "medindo" : "desligado";texts=new Dictionary(true);}
    paint(item);applyRate();draw();e.stopPropagation();
   });
   if(item.id=="limit"){
    input=new TextField();input.name="sddsPerformanceFpsInput";input.type=TextFieldType.INPUT;input.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);input.background=true;input.backgroundColor=0x101827;input.border=true;input.borderColor=0x35405B;input.x=160;input.y=1;input.width=60;input.height=21;input.maxChars=4;input.restrict="0-9";input.text=String(limitValue);row.addChild(input);
    input.addEventListener(Event.CHANGE,function(e:Event):void{var value:Number=Number(input.text);if(isFinite(value) && value>=1){limitValue=Math.min(120,value);if(value>120)input.text="120";applyRate();}});
    input.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{e.stopPropagation();});input.addEventListener(KeyboardEvent.KEY_UP,function(e:KeyboardEvent):void{e.stopPropagation();});
   }
   host.addChild(row);
  }
  private function applyRate():void {
   if(!root.stage)return;
   if(lastTarget<0 && (option("limit").on || option("unlock").on))originalRate=root.stage.frameRate;
   var target:Number=option("limit").on ? limitValue : option("unlock").on ? 120 : originalRate;
   if(lastTarget<0 && !option("limit").on && !option("unlock").on)return;
   if(target==lastTarget && Math.abs(root.stage.frameRate-target)<0.1)return;
   try{root.stage.frameRate=target;lastTarget=target;}catch(error:Error){if(info)info.text="O Flash recusou a taxa solicitada #"+error.errorID;}
  }
  public static function isPingReply(text:String):Boolean {
   var value:String=text.replace(/^\s+|\s+$/g,"");
   value=value.replace(/^(?:\[?(?:server|servidor|serveur)\]?\s*[:>]\s*)/i,"");
   return /^(?:pong(?:[!.:]|\s+\d+\s*ms)*|ping\s*[:=~]?\s*\d+(?:[.,]\d+)?\s*(?:ms)?|seu ping (?:e|é|eh|está em)\s*:?\s*\d+\s*ms)[\s!.]*$/i.test(value);
  }
  private function textFields():Array {
   var result:Array=[];var queue:Array=[root.stage];var cursor:int=0;
   while(cursor<queue.length && cursor<5000){var node:DisplayObject=queue[cursor++] as DisplayObject;if(!node || (node.name && node.name.indexOf("sdds")==0))continue;
    if(node is TextField){if(TextField(node).type!=TextFieldType.INPUT)result.push(node);continue;}
    var container:DisplayObjectContainer=node as DisplayObjectContainer;if(container)for(var i:int=0;i<container.numChildren;i++)queue.push(container.getChildAt(i));
   }
   return result;
  }
  private function beginPing(now:int):void {
   nextPing=now+10000;
   try{
    var k:Object=root["Keys"];var game:Object=root["tfm"];if(!k || !game || !k.player || !game[k.player]){pingState="aguardando login";return;}
    var connection:Object=k.socket_class ? k.socket_class[k.main_socket_instance] : null;var command:Class=k.command_packet_class as Class;
    if(!connection || !command || !k.data_sender || !(connection[k.data_sender] is Function)){pingState="sem conexao";return;}
    texts=new Dictionary(true);for each(var field:TextField in textFields())texts[field]=field.text;
    pingSent=now;pingState="medindo";connection[k.data_sender](new command("ping"));
   }catch(error:Error){pingSent=-1;pingState="erro #"+error.errorID;}
  }
  private function inspectPing(now:int):void {
   if(pingSent<0)return;
   if(now-pingSent>8000){pingSent=-1;pingState="sem resposta";return;}
   if(now<nextScan)return;nextScan=now+100;
   for each(var field:TextField in textFields()){
    var current:String=field.text;var old:String=texts[field] as String;if(old===current)continue;texts[field]=current;
    var fresh:String=current;
    if(old!=null && current.indexOf(old)==0)fresh=current.substring(old.length);
    else if(old!=null){var rows:Array=current.replace(/\s+$/g,"").split(/\r?\n/);fresh=String(rows[rows.length-1]);if(old.indexOf(fresh)>=0)continue;}
    for each(var line:String in fresh.split(/\r?\n/))if(isPingReply(line)){
     pingValue=Math.max(1,now-pingSent);pingSent=-1;pingState=String(pingValue)+" ms";return;
    }
   }
  }
  private function positionHud():void{if(hud && root.stage){hud.x=Math.max(8,root.stage.stageWidth-hud.width-10);hud.y=36;}}
  private function draw():void {
   if(!root.stage)return;
   if(!hud){hud=new TextField();hud.name="sddsPerformanceHud";hud.defaultTextFormat=new TextFormat("_sans",12,0xE5F3FF,true);hud.background=true;hud.backgroundColor=0x141B2A;hud.width=205;hud.height=42;hud.multiline=true;hud.selectable=false;hud.mouseEnabled=false;root.stage.addChild(hud);positionHud();}
   var lines:Array=[];if(option("fps").on)lines.push("FPS: "+actualFps.toFixed(1)+" | alvo "+root.stage.frameRate);
   if(option("ping").on)lines.push("Ping /ping: "+pingState);
   hud.visible=lines.length>0;hud.text=lines.join("\n");
   if(info)info.text="Taxa solicitada: "+root.stage.frameRate+" FPS"+(option("ping").on ? " | Ping: "+pingState : "")+"\nO FPS efetivo depende do Flash e do computador.";
  }
  public function update(now:int=-1):void {
   if(now<0)now=getTimer();root["mass_reduction"]=false;root["change_movement_speed"]=false;
   try{bindMenu();}catch(error:Error){if(info)info.text="Falha ao montar controles #"+error.errorID;}
   if(frameStart<0){frameStart=now;frames=0;}else{frames++;if(now-frameStart>=1000){actualFps=frames*1000/(now-frameStart);frames=0;frameStart=now;}}
   if(option("ping").on){if(pingSent<0 && now>=nextPing)beginPing(now);inspectPing(now);}
   if(now-uiTick>=200){uiTick=now;applyRate();draw();}
  }
 }
}
