// ActionScript 3 / LegacyOptionsV4.as / Flash Player 10.3+ / adapt the seven legacy menu controls to the current loader
package disney {
 import flash.display.MovieClip;
 import flash.display.Sprite;
 import flash.display.DisplayObject;
 import flash.display.DisplayObjectContainer;
 import flash.events.Event;
 import flash.events.MouseEvent;
 import flash.events.KeyboardEvent;
 import flash.geom.Point;
 import flash.text.TextField;
 import flash.text.TextFieldType;
 import flash.text.TextFormat;
 import flash.utils.Dictionary;
 import flash.utils.getTimer;
 import flash.utils.clearTimeout;
 import flash.utils.setTimeout;
 import flash.net.URLLoader;
 import flash.net.URLRequest;
 import flash.net.URLRequestMethod;
 import flash.net.URLVariables;
 import flash.events.IOErrorEvent;
 import flash.events.SecurityErrorEvent;
 public class LegacyOptionsV4 {
  private static var attached:Dictionary=new Dictionary(true);
  private var root:MovieClip;
  private var teleportPresses:int=0;
  private var diagnosticRequests:Array=[];
  private var host:DisplayObjectContainer;
  private var options:Array=[{id:"teleport",title:"Teleport [F]",enabled:false},{id:"fake",title:"Fake Teleport [V]",enabled:false},{id:"inventory",title:"Block Inventory",enabled:false},{id:"collect",title:"Collect Box",enabled:false},{id:"win",title:"Auto Win",enabled:false},{id:"die",title:"Auto Die",enabled:false}];
  private var rows:Array=[];
  private var delayInput:TextField;
  private var reportField:TextField;
  private var delayText:String="5000";
  private var lastAttempt:int=0;
  private var checked:int=-500;
  private var round:String="";
  private var currentPlayer:Object;
  private var wasAlive:Boolean=false;
  private var held:Object={};
  private var collected:Dictionary=new Dictionary(true);
  private var hidden:Dictionary=new Dictionary(true);
  private var inventoryClass:Class;
  private var inventoryWrapper:Class;
  private var lastCollect:int=-500;
  public function LegacyOptionsV4(target:MovieClip){root=target;}
  public static function attach(target:MovieClip):void{
   if(!target || !target.stage || attached[target])return;
   var port:LegacyOptionsV4=new LegacyOptionsV4(target);attached[target]=port;port.traceTeleport("ready");
   target.stage.addEventListener(Event.ENTER_FRAME,function(e:Event):void{port.update();});
   target.stage.addEventListener(KeyboardEvent.KEY_DOWN,port.keyDown,true,1000);
   target.stage.addEventListener(KeyboardEvent.KEY_UP,port.keyUp,true,1000);
   target.stage.addEventListener(KeyboardEvent.KEY_DOWN,port.keyDown,false,1000);
   target.stage.addEventListener(KeyboardEvent.KEY_UP,port.keyUp,false,1000);
   target.stage.addEventListener(Event.DEACTIVATE,function(e:Event):void{port.held={};});
  }
  private function report(text:String):void{if(reportField)reportField.text=text;
   if(root.stage){var status:TextField=root.stage.getChildByName("sddsConnectionStatus") as TextField;if(status)status.text=text;}
  }
  private function traceTeleport(reason:String,code:int=0,targetX:Number=99999999,targetY:Number=99999999,press:int=-1):void {
   try {
    if(diagnosticRequests.length>=8)return;
    var data:URLVariables=new URLVariables();data.event="teleport";data.channel="client";data.code=code;data.elapsed=getTimer();
    data.build="sdds-legacy-teleport-diag-v4";data.reason=reason;data.press=press<0 ? teleportPresses : press;
    var flags:Array=[];if(option("teleport").enabled)flags.push("teleport");
    for each(var name:String in ["auto_play","recording","change_movement_speed","mass_reduction","insta_death","insta_win","no_delay","macro"])if(root[name])flags.push(name);data.options=flags.join(",");
    var k:Object=root["Keys"];var game:Object=root["tfm"];var p:Object=k && game && k.player ? game[k.player] : null;
    if(p){if(isFinite(Number(p.x)))data.x=Math.round(Number(p.x));if(isFinite(Number(p.y)))data.y=Math.round(Number(p.y));data.alive=!(k.is_dead && p[k.is_dead]) ? "1" : "0";}
    if(isFinite(targetX) && Math.abs(targetX)<=10000000)data.target_x=Math.round(targetX);if(isFinite(targetY) && Math.abs(targetY)<=10000000)data.target_y=Math.round(targetY);
    var request:URLRequest=new URLRequest(root["host_url"]+"client_diagnostics?access_token="+encodeURIComponent(String(root["access_token"]))+"&flash_token="+encodeURIComponent(String(root["tfmdisney"].data.flash_token)));
    request.method=URLRequestMethod.POST;request.data=data;
    var loader:URLLoader=new URLLoader();diagnosticRequests.push(loader);
    var release:Function=function(event:Event):void{var i:int=diagnosticRequests.indexOf(loader);if(i>=0)diagnosticRequests.splice(i,1);};
    loader.addEventListener(Event.COMPLETE,release);loader.addEventListener(IOErrorEvent.IO_ERROR,release);loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,release);loader.load(request);
   }catch(ignored:Error){}
  }
  private function field(text:String,width:Number=500):TextField{
   var f:TextField=new TextField();f.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);f.text=text;f.width=width;f.height=24;f.selectable=false;f.mouseEnabled=false;return f;
  }
  private function paint(option:Object):void{
   var b:Sprite=option.box;if(!b)return;b.graphics.clear();b.graphics.lineStyle(1,0x50747C);b.graphics.beginFill(0x1C3038);b.graphics.drawCircle(5.5,5.5,5.5);b.graphics.endFill();
   if(option.enabled){b.graphics.lineStyle(0,0,0);b.graphics.beginFill(0xD6EDF2);b.graphics.drawCircle(5.5,5.5,3);b.graphics.endFill();}
  }
  private function toggle(option:Object):void{
   option.enabled=!option.enabled;
   if(option.enabled && (option.id=="win" || option.id=="die")){
    for each(var other:Object in options)if(other!==option && (other.id=="win" || other.id=="die")){other.enabled=false;paint(other);}
    root["insta_win"]=false;root["insta_death2"]=false;root["insta_death"]=false;
    clearTimeout(uint(root["insta_win_timeout"]));clearTimeout(uint(root["insta_death_timeout"]));lastAttempt=getTimer();
   }
   if(option.id=="inventory" && !option.enabled)restoreInventory();
   if(option.id=="teleport")traceTeleport(option.enabled ? "enabled" : "disabled");
   paint(option);report(option.title+": "+(option.enabled ? "ligado" : "desligado"));
  }
  private function bindOption(option:Object,y:Number):void{
   var row:Sprite=new Sprite();row.x=0;row.y=y;row.buttonMode=true;row.mouseChildren=false;row.name="sddsLegacy_"+option.id;row.graphics.beginFill(0,0);row.graphics.drawRect(0,0,480,25);row.graphics.endFill();
   var box:Sprite=new Sprite();box.y=5;row.addChild(box);option.box=box;
   var text:TextField=field(option.title);text.x=18;row.addChild(text);
   row.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{toggle(option);e.stopPropagation();});host.addChild(row);rows.push(row);paint(option);
  }
  private function menu():void{
   var ui:Object=root["Interface"];var target:DisplayObjectContainer=ui ? ui["farm_ui"] as DisplayObjectContainer : null;if(!target || target===host)return;
   for each(var old:DisplayObject in rows)if(old.parent)old.parent.removeChild(old);rows=[];host=target;
   var y:Number=Math.ceil(host.height)+12;var title:TextField=field("Funcoes do menu antigo");title.y=y;host.addChild(title);rows.push(title);y+=27;
   for each(var option:Object in options){bindOption(option,y);y+=26;}
   var label:TextField=field("Farm Time (ms):",135);label.y=y;host.addChild(label);rows.push(label);
   delayInput=new TextField();delayInput.name="sddsLegacyFarmTime";delayInput.type=TextFieldType.INPUT;delayInput.defaultTextFormat=new TextFormat("_sans",12,0xD7DEEC);delayInput.background=true;delayInput.backgroundColor=0x101827;delayInput.border=true;delayInput.borderColor=0x35405B;delayInput.x=140;delayInput.y=y;delayInput.width=100;delayInput.height=21;delayInput.maxChars=6;delayInput.text=delayText;host.addChild(delayInput);rows.push(delayInput);
   delayInput.addEventListener(Event.CHANGE,function(e:Event):void{delayText=delayInput.text;});
   delayInput.addEventListener(KeyboardEvent.KEY_DOWN,function(e:KeyboardEvent):void{e.stopPropagation();});delayInput.addEventListener(KeyboardEvent.KEY_UP,function(e:KeyboardEvent):void{e.stopPropagation();});
   reportField=field("Opcoes desligadas | Farm Time: 500 a 600000 ms");reportField.y=y+27;reportField.height=36;reportField.wordWrap=true;host.addChild(reportField);rows.push(reportField);
  }
  private function option(id:String):Object{for each(var o:Object in options)if(o.id==id)return o;return null;}
  public function keyUp(e:KeyboardEvent):void{delete held[e.keyCode];}
  public function keyDown(e:KeyboardEvent):void{
   var o:Object=option(e.keyCode==70 ? "teleport" : e.keyCode==86 ? "fake" : "");if(!o || !o.enabled)return;
   if(root.stage && root.stage.focus is TextField && TextField(root.stage.focus).type==TextFieldType.INPUT){report(o.title+": clique no mapa para sair do campo de texto");if(o.id=="teleport")traceTeleport("focus_field");return;}
   e.stopImmediatePropagation();
   if(held[e.keyCode])return;held[e.keyCode]=true;
   try{
    var k:Object=root["Keys"];var p:DisplayObject=root["tfm"][k.player] as DisplayObject;if(!p || !p.parent){report(o.title+": aguardando jogador no mapa");if(o.id=="teleport")traceTeleport("waiting_player");return;}
    var point:Point=p.parent.globalToLocal(new Point(root.stage.mouseX,root.stage.mouseY));
    if(e.keyCode==70){
     teleportPresses++;var press:int=teleportPresses;traceTeleport("requested",0,point.x,point.y,press);
     teleport(point.x,point.y);traceTeleport("returned",0,point.x,point.y,press);
     setTimeout(function():void{traceTeleport("after_200ms",0,point.x,point.y,press);},200);
    }else{p.x=point.x;p.y=point.y;report("Fake Teleport: apenas posicao visual");}
    e.stopImmediatePropagation();
   }catch(error:Error){report(o.title+": erro #"+error.errorID);if(o.id=="teleport")traceTeleport("error",error.errorID);}
  }
  public function teleport(x:Number,y:Number):void{
   if(!isFinite(x)||!isFinite(y)||Math.abs(x)>32767||Math.abs(y)>32767)throw new Error("Invalid position",2101);
   var statements:Object=root["Statements"];
   if(!statements || !(statements["move_player"] is Function))throw new Error("Movement unavailable",2102);
   statements["move_player"](Math.round(x),Math.round(y));
   report("Teleport: pedido aplicado pela rotina anterior");
  }
  private function collect(world:DisplayObjectContainer,p:DisplayObject):void{
   if(!world || !p || !p.parent){report("Collect Box: aguardando mapa");return;}
   var queue:Array=[world];var visited:int=0;var playerType:Class=Object(p).constructor as Class;
   while(queue.length && visited<3000){var node:DisplayObject=queue.shift() as DisplayObject;visited++;
    if(node===p || (playerType && node is playerType))continue;
    if(node!==world && node.visible && Math.abs(node.width-37)<0.1 && Math.abs(node.height-39)<0.1 && !collected[node]){
     var point:Point=p.parent.globalToLocal(node.localToGlobal(new Point(18.5,19.5)));teleport(point.x,point.y);collected[node]=true;report("Collect Box: posicao da caixa aplicada");return;
    }
    var container:DisplayObjectContainer=node as DisplayObjectContainer;if(container)for(var i:int=0;i<container.numChildren;i++)queue.push(container.getChildAt(i));
   }
   report("Collect Box: nenhuma caixa 37x39 neste mapa");
  }
  private function restoreInventory():void{for(var node:Object in hidden){try{DisplayObject(node).visible=Boolean(hidden[node]);}catch(ignored:Error){}}hidden=new Dictionary(true);}
  private function blockInventory():void{
   // Resolve the native inventory notification class from the current game domain.
   var k:Object=root["Keys"];if(!inventoryClass){if(!k.legacy_inventory_class)throw new Error("Inventory notification mapping unavailable",2103);inventoryClass=k.app_domain.applicationDomain.getDefinition(String(k.legacy_inventory_class)) as Class;inventoryWrapper=k.app_domain.applicationDomain.getDefinition(String(k.legacy_inventory_wrapper)) as Class;}
   var game:DisplayObjectContainer=root.stage;if(!game)return;
   var queue:Array=[game];var visited:int=0;var count:int=0;
   while(queue.length && visited<5000){var node:DisplayObject=queue.shift() as DisplayObject;visited++;
    if(node is inventoryClass && node.parent && node.parent is inventoryWrapper){var popup:DisplayObject=node.parent;if(!(popup in hidden))hidden[popup]=popup.visible;popup.visible=false;count++;continue;}
    var container:DisplayObjectContainer=node as DisplayObjectContainer;if(container)for(var i:int=0;i<container.numChildren;i++)queue.push(container.getChildAt(i));
   }
   report("Block Inventory: ativo | avisos ocultos: "+count);
  }
  public function update(now:int=-1):void{
   if(now<0)now=getTimer();try{menu();}catch(menuError:Error){}
   if(now-checked<100)return;checked=now;
   try{
    if(option("inventory").enabled){try{blockInventory();}catch(invError:Error){option("inventory").enabled=false;paint(option("inventory"));restoreInventory();report("Block Inventory: erro #"+invError.errorID);}}
    var k:Object=root["Keys"];var game:Object=root["tfm"];var p:Object=k && game && k.player ? game[k.player] : null;
    var alive:Boolean=Boolean(p && (!k.is_dead || !p[k.is_dead]));var code:String=String(root["current_map_code"])+":"+String(root["current_round_code"]);
    if(code!==round || p!==currentPlayer || (alive && !wasAlive)){round=code;currentPlayer=p;lastAttempt=now;collected=new Dictionary(true);}wasAlive=alive;
    if(!alive)return;
    if(option("collect").enabled && now-lastCollect>=500){var world:DisplayObjectContainer=k.tfm_obj_container && k.tfm_obj_container in game ? game[k.tfm_obj_container] as DisplayObjectContainer : null;lastCollect=now;collect(world,p as DisplayObject);}
    var action:Object=option("win").enabled ? option("win") : option("die").enabled ? option("die") : null;if(!action)return;
    var delay:Number=Number(delayText);if(!isFinite(delay)||delay<500||delay>600000){report("Farm Time: informe de 500 a 600000 ms");return;}
    if(now-lastAttempt<delay)return;lastAttempt=now;
    var statements:Object=root["Statements"];if(!statements)throw new Error("Statements unavailable",2104);
    try{statements[action.id=="win" ? "player_victory" : "player_death"]();report(action.title+": tentativa enviada");}catch(error:Error){action.enabled=false;paint(action);report(action.title+": erro #"+error.errorID);}
   }catch(error:Error){report("Funcoes antigas: erro #"+error.errorID);}
  }
 }
}
