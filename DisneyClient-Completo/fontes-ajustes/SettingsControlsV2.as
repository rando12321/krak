// ActionScript 3 / SettingsControlsV2.as / Flash Player 10.3+ / functional alignment, visual preset and timed emoji controls
package disney {
 import flash.display.MovieClip;import flash.display.Sprite;import flash.display.DisplayObject;import flash.display.DisplayObjectContainer;import flash.display.Loader;import flash.events.Event;import flash.events.MouseEvent;import flash.events.KeyboardEvent;import flash.events.IOErrorEvent;import flash.events.SecurityErrorEvent;import flash.text.TextField;import flash.text.TextFieldType;import flash.text.TextFormat;import flash.geom.Rectangle;import flash.net.URLRequest;import flash.utils.Dictionary;import flash.utils.getTimer;import flash.utils.clearInterval;
 public class SettingsControlsV2 {
  private static var installed:Dictionary=new Dictionary(true);private var root:MovieClip;private var ui:Object;private var prepared:Dictionary=new Dictionary(true);private var popup:Sprite;private var menu:Sprite;
  private var skinOn:Boolean=false;private var skin:String="banho";private var loader:Loader;private var loaded:Boolean=false;private var avatar:DisplayObjectContainer;private var hidden:DisplayObject;private var oldVisible:Boolean=true;
  private var macroOn:Boolean=false;private var macroToggle:Sprite;private var macroField:TextField;private var nextMacro:int=0;private var heldUp:Boolean=false;private var heldW:Boolean=false;private var macroPlayer:Object;private var macroFocus:Boolean=true;
  private var emojiOn:Boolean=false;private var emojiId:int=0;private var nextEmoji:int=0;private var emojiField:TextField;private var emojiToggle:Sprite;private var skinToggle:Sprite;private var status:TextField;
  public function SettingsControlsV2(value:MovieClip){root=value;root["macro"]=false;}
  public static function attach(value:MovieClip):void{if(!value || !value.stage || installed[value])return;var fix:SettingsControlsV2=new SettingsControlsV2(value);installed[value]=fix;value.stage.addEventListener(Event.ENTER_FRAME,function(e:Event):void{fix.update();});value.stage.addEventListener(MouseEvent.MOUSE_DOWN,fix.outside,true,2000);value.stage.addEventListener(KeyboardEvent.KEY_DOWN,fix.macroKeyDown,true,3000);value.stage.addEventListener(KeyboardEvent.KEY_UP,fix.macroKeyUp,true,3000);value.stage.addEventListener(Event.DEACTIVATE,function(e:Event):void{fix.macroFocus=false;fix.heldUp=false;fix.heldW=false;fix.releaseMacro();});value.stage.addEventListener(Event.ACTIVATE,function(e:Event):void{fix.macroFocus=true;});}
  private function field(text:String,width:Number=180):TextField{var f:TextField=new TextField();f.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);f.text=text;f.width=width;f.height=23;f.selectable=false;f.mouseEnabled=false;return f;}
  private function button(text:String,width:Number,callback:Function):Sprite{var s:Sprite=new Sprite();s.graphics.lineStyle(1,0x52737D);s.graphics.beginFill(0x304E59);s.graphics.drawRoundRect(0,0,width,21,4);s.graphics.endFill();var f:TextField=field(text,width-6);f.x=3;s.addChild(f);s.buttonMode=true;s.mouseChildren=false;s.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{callback();e.stopImmediatePropagation();});return s;}
  private function circle(toggle:Sprite,on:Boolean):void{toggle.graphics.clear();toggle.graphics.lineStyle(1,0x52737D);toggle.graphics.beginFill(0x1C3038);toggle.graphics.drawCircle(6,11,5.5);toggle.graphics.endFill();if(on){toggle.graphics.beginFill(0xD6EDF2);toggle.graphics.drawCircle(6,11,3);toggle.graphics.endFill();}}
  private function toggle(text:String,callback:Function):Sprite{var s:Sprite=new Sprite();var f:TextField=field(text,140);f.x=18;s.addChild(f);s.buttonMode=true;s.mouseChildren=false;circle(s,false);s.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{callback();e.stopImmediatePropagation();});return s;}
  private function labelIn(parent:DisplayObjectContainer,prefix:String):TextField{for(var i:int=0;i<parent.numChildren;i++){var node:DisplayObject=parent.getChildAt(i);if(node is TextField && TextField(node).text.indexOf(prefix)==0)return node as TextField;if(node is DisplayObjectContainer){var found:TextField=labelIn(node as DisplayObjectContainer,prefix);if(found)return found;}}return null;}
  private function replace(host:DisplayObjectContainer,prefix:String,marker:String):Sprite{
   if(!host)return null;if(!prepared[host])prepared[host]={};if(prepared[host][marker])return null;var label:TextField=labelIn(host,prefix);if(!label)return null;var node:DisplayObject=label;var below:DisplayObject=null;
   while(node.parent && node.parent!==host){below=node;node=node.parent;}
   if(node.parent!==host)return null;var k:Object=root["Keys"];var type:Class=k ? k.ui_element_class as Class : null;var wrapped:Boolean=type ? !(node is type) : node.height>50;var old:DisplayObject=wrapped && below ? below : node;if(!old.parent)return null;
   var row:Sprite=new Sprite();row.name=marker;row.x=old.x;row.y=old.y;old.parent.addChildAt(row,old.parent.getChildIndex(old)+1);old.visible=false;if(old is DisplayObjectContainer)DisplayObjectContainer(old).mouseChildren=false;
   // The native layout still owns the hidden row's position and height.
   prepared[host][marker]=true;return row;
  }
  private function closePopup():void{if(popup && popup.parent)popup.parent.removeChild(popup);popup=null;}
  private function outside(e:MouseEvent):void{if(popup && e.target is DisplayObject && !popup.contains(e.target as DisplayObject))closePopup();}
  private function choose(anchor:Sprite,items:Array,callback:Function):void{
   closePopup();popup=new Sprite();popup.name="sddsFixedDropdown";var width:Number=174;var height:Number=items.length*22+6;popup.graphics.lineStyle(1,0x596581);popup.graphics.beginFill(0x162032);popup.graphics.drawRoundRect(0,0,width,height,5);popup.graphics.endFill();
   for(var i:int=0;i<items.length;i++)addChoice(items[i],i,callback);
   var bounds:Rectangle=anchor.getBounds(root.stage);popup.x=Math.max(0,Math.min(root.stage.stageWidth-width,bounds.x));popup.y=bounds.bottom+2;if(popup.y+height>root.stage.stageHeight)popup.y=Math.max(0,bounds.y-height-2);root.stage.addChild(popup);
  }
  private function addChoice(item:Object,index:int,callback:Function):void{var b:Sprite=button(item.label,168,function():void{callback(item);closePopup();});b.x=3;b.y=3+index*22;popup.addChild(b);}
  private function alignRow(row:Sprite):void{
   row.addChild(field("Alinhamento",155));var values:Array=[{label:"Centro",value:""},{label:"Baixo",value:"B"},{label:"Baixo esquerdo",value:"BL"},{label:"Baixo direito",value:"BR"},{label:"Esquerda",value:"L"},{label:"Direita",value:"R"},{label:"Topo",value:"T"},{label:"Topo esquerdo",value:"TL"},{label:"Topo direito",value:"TR"}];
   var selected:String="Centro";for each(var option:Object in values)if(option.value==root.stage.align)selected=option.label;
   var control:Sprite=button(selected,180,function():void{choose(control,values,function(item:Object):void{root.stage.align=item.value;TextField(control.getChildAt(0)).text=item.label;});});control.x=155;row.addChild(control);
  }
  private function skinRow(row:Sprite):void{
   skinToggle=toggle("L3v3 mode",function():void{skinOn=!skinOn;circle(skinToggle,skinOn);if(skinOn)loadSkin();else restoreSkin();});row.addChild(skinToggle);circle(skinToggle,skinOn);
   var values:Array=[];for each(var name:String in ["abelha","ajeita","banho","grau","apenasl3v3","classico","ftnyrel","femea","roubo","roubofemea","queda","praia","tornado","tortuguita"])values.push({label:name,value:name});
   var control:Sprite=button(skin,115,function():void{choose(control,values,function(item:Object):void{skin=item.value;TextField(control.getChildAt(0)).text=skin;if(skinOn)loadSkin();});});control.x=155;row.addChild(control);
  }
  private function restoreSkin():void{if(loader && loader.parent)loader.parent.removeChild(loader);if(hidden)hidden.visible=oldVisible;hidden=null;avatar=null;}
  private function loadSkin():void{restoreSkin();loaded=false;loader=new Loader();var current:Loader=loader;current.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void{if(current===loader)loaded=true;});current.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void{if(current===loader){skinOn=false;circle(skinToggle,false);message("Nao foi possivel carregar o visual selecionado.");}});current.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,function(e:SecurityErrorEvent):void{if(current===loader){skinOn=false;circle(skinToggle,false);message("Visual bloqueado pelo Flash #"+e.errorID);}});try{current.load(new URLRequest(String(root["host_url"])+"images/l3v3"+skin+".png"));}catch(error:Error){skinOn=false;circle(skinToggle,false);message("Falha no visual #"+error.errorID);}}
  private function renderSkin():void{if(!skinOn || !loaded || !loader)return;var k:Object=root["Keys"];var game:Object=root["tfm"];var current:DisplayObjectContainer=k && game ? game[k.player] as DisplayObjectContainer : null;if(!current)return;
   if(current!==avatar){if(hidden)hidden.visible=oldVisible;if(loader.parent)loader.parent.removeChild(loader);avatar=current;hidden=k.player_bitmap ? current[k.player_bitmap] as DisplayObject : null;if(hidden)oldVisible=hidden.visible;current.addChild(loader);loader.x=-25;loader.y=-30;}
   if(hidden)hidden.visible=false;
  }
  private function message(text:String):void{if(status)status.text=text;}
  private function emojiRow(row:Sprite):void{
   emojiToggle=toggle("Auto emoji",function():void{emojiOn=!emojiOn;circle(emojiToggle,emojiOn);nextEmoji=0;});row.addChild(emojiToggle);circle(emojiToggle,emojiOn);
   emojiField=field(String(emojiId),50);emojiField.name="sddsEmojiId";emojiField.mouseEnabled=true;emojiField.selectable=true;emojiField.type=TextFieldType.INPUT;emojiField.background=true;emojiField.backgroundColor=0x101827;emojiField.border=true;emojiField.borderColor=0x35405B;emojiField.x=155;emojiField.width=50;emojiField.height=21;emojiField.restrict="0-9";emojiField.maxChars=1;row.addChild(emojiField);
   emojiField.addEventListener(Event.CHANGE,function(e:Event):void{if(emojiField.text!="")emojiId=int(emojiField.text);});emojiField.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{e.stopPropagation();});emojiField.addEventListener(KeyboardEvent.KEY_UP,function(e:KeyboardEvent):void{e.stopPropagation();});var tip:TextField=field("ID 0-9 / a cada 3 s",190);tip.x=215;row.addChild(tip);
  }
  private function tickEmoji(now:int):void{var st:Object=root["Statements"];if(st && int(st.emoji_interval)>=0){clearInterval(int(st.emoji_interval));st.emoji_interval=-1;}if(!emojiOn || now<nextEmoji)return;nextEmoji=now+3000;
   var k:Object=root["Keys"];var game:Object=root["tfm"];if(!k || !game || !game[k.player] || (k.is_dead && game[k.player][k.is_dead]))return;
   if(!emojiField || !/^[0-9]$/.test(emojiField.text)){message("Auto emoji: digite um ID de 0 a 9.");return;}
   try{if(!st || !(st.send_emoji_packet is Function))throw new Error("Emote indisponivel");st.selected_emoji=emojiId;st.send_emoji_packet(emojiId);message("Auto emoji "+emojiId+": enviado / intervalo 3 s");}catch(error:Error){emojiOn=false;circle(emojiToggle,false);message("Auto emoji: erro #"+error.errorID);}
  }
  private function macroRow(row:Sprite):void{
   macroToggle=toggle("Macro [CTRL F8]",function():void{macroOn=!macroOn;nextMacro=0;circle(macroToggle,macroOn);if(!macroOn)releaseMacro();});row.addChild(macroToggle);circle(macroToggle,macroOn);
   macroField=field("100",60);macroField.name="sddsMacroInterval";macroField.type=TextFieldType.INPUT;macroField.mouseEnabled=true;macroField.selectable=true;macroField.background=true;macroField.backgroundColor=0x101827;macroField.border=true;macroField.borderColor=0x35405B;macroField.x=155;macroField.width=60;macroField.height=21;macroField.restrict="0-9";macroField.maxChars=4;row.addChild(macroField);
   macroField.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{e.stopPropagation();});macroField.addEventListener(KeyboardEvent.KEY_UP,function(e:KeyboardEvent):void{e.stopPropagation();});var tip:TextField=field("ms (20-2000) | segure seta cima ou W",290);tip.x=225;row.addChild(tip);
  }
  public function macroKeyDown(e:KeyboardEvent):void{
   if(root.stage && root.stage.focus is TextField && TextField(root.stage.focus).type==TextFieldType.INPUT)return;
   if(e.ctrlKey && e.keyCode==119){macroOn=!macroOn;nextMacro=0;if(macroToggle)circle(macroToggle,macroOn);if(!macroOn)releaseMacro();e.preventDefault();e.stopImmediatePropagation();return;}
   if(e.keyCode==38)heldUp=true;if(e.keyCode==87)heldW=true;
  }
  public function macroKeyUp(e:KeyboardEvent):void{if(e.keyCode==38)heldUp=false;if(e.keyCode==87)heldW=false;if(!heldUp && !heldW){releaseMacro();nextMacro=0;}}
  private function releaseMacro():void{if(macroPlayer){try{var k:Object=root["Keys"];macroPlayer[k.jump](false);}catch(ignored:Error){}macroPlayer=null;}}
  private function tickMacro(now:int):void{
   root["macro"]=false; // Prevent the legacy per-frame key-down burst.
   if(!macroOn || !macroFocus || (!heldUp && !heldW)){releaseMacro();return;}
   if(root.stage && root.stage.focus is TextField && TextField(root.stage.focus).type==TextFieldType.INPUT){heldUp=false;heldW=false;releaseMacro();return;}
   if(!macroField || !/^[0-9]+$/.test(macroField.text)){releaseMacro();message("Macro: informe intervalo de 20 a 2000 ms");return;}
   var interval:Number=Number(macroField.text);if(!isFinite(interval) || interval<20 || interval>2000){releaseMacro();message("Macro: intervalo permitido 20-2000 ms");return;}
   var k:Object=root["Keys"];var game:Object=root["tfm"];var p:Object=k && game ? game[k.player] : null;
   if(!p || (k.is_dead && p[k.is_dead])){releaseMacro();return;}
   if(now<nextMacro)return;nextMacro=now+interval;
   try{if(!(p[k.jump] is Function))throw new Error("Pulo indisponivel");if(macroPlayer && macroPlayer!==p)releaseMacro();macroPlayer=p;p[k.jump](false);p[k.jump](true);message("Macro: pulso de pulo / "+interval+" ms");}catch(error:Error){releaseMacro();macroOn=false;if(macroToggle)circle(macroToggle,false);message("Macro: erro #"+error.errorID);}
  }
  public function update(now:int=-1):void{if(now<0)now=getTimer();var next:Object=root["Interface"];if(!next)return;
   if(next!==ui){closePopup();ui=next;var g:DisplayObjectContainer=ui["general_ui"] as DisplayObjectContainer;var settings:DisplayObjectContainer=ui["settings_ui"] as DisplayObjectContainer;var row:Sprite=replace(g,"Alinhamento","sddsAlignment");if(!row)row=replace(g,"Window alignment","sddsAlignment");if(row)alignRow(row);row=replace(settings,"L3v3 mode","sddsSkin");if(row)skinRow(row);row=replace(settings,"Auto emoji","sddsEmoji");if(row)emojiRow(row);row=replace(settings,"Macro","sddsMacro");if(row)macroRow(row);if(settings){status=field("",500);status.name="sddsControlStatus";status.y=144;status.height=44;status.wordWrap=true;settings.addChild(status);}}
   root["l3v3_mode"]=false;menu=ui["menu_ui"] as Sprite;if(popup && (!menu || !menu.parent))closePopup();renderSkin();tickEmoji(now);tickMacro(now);
  }
 }
}
