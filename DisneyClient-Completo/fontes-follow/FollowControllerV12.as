// ActionScript 3 / FollowControllerV12.as / Flash Player 10.3+ / room-local nickname following with native movement keys
package disney {
 import flash.utils.ByteArray;import flash.display.MovieClip;import flash.display.DisplayObject;import flash.geom.Point;import flash.events.Event;import flash.events.KeyboardEvent;import flash.text.TextField;import flash.text.TextFieldType;import flash.text.TextFormat;import flash.utils.Dictionary;import flash.utils.getTimer;
 public class FollowControllerV12 {
  private static var instances:Dictionary=new Dictionary(true);
  private var root:MovieClip;private var targetName:String="";private var owner:Object;private var left:Boolean=false;private var right:Boolean=false;private var jumping:Boolean=false;private var hud:TextField;private var state:String="";private var focused:Boolean=true;private var needsSync:Boolean=true;private var bodyOwner:Object;private var roundOwner:Object;private var roundCode:String="";private var retryAt:int=0;
  private var live:Object;private var moveSerial:uint=0;private var appliedSerial:uint=0;

  public function FollowControllerV12(value:MovieClip){root=value;}
  public static function attach(value:MovieClip):void{
   if(!value || !value.stage || instances[value])return;var follow:FollowControllerV12=new FollowControllerV12(value);instances[value]=follow;
   value.stage.addEventListener(KeyboardEvent.KEY_DOWN,follow.keyDown,true,2000);value.stage.addEventListener(KeyboardEvent.KEY_DOWN,follow.keyDown,false,2000);
   value.stage.addEventListener(Event.ENTER_FRAME,function(event:Event):void{follow.update();});
   value.stage.addEventListener(Event.ACTIVATE,function(event:Event):void{follow.focused=true;});
   value.stage.addEventListener(Event.DEACTIVATE,function(event:Event):void{follow.focused=false;follow.live=null;follow.release();follow.notice("Follow: pausado ao perder foco");});
  }
  public static function receive(value:MovieClip,bytes:ByteArray):void {
   var f:FollowControllerV12=instances[value] as FollowControllerV12;if(!f || !bytes)return;
   var cursor:uint=bytes.position;try{bytes.position=0;f.packet(bytes);}catch(e:Error){}finally{bytes.position=cursor;}
  }
  public function packet(bytes:ByteArray,now:int=-1):void {
   if(targetName=="" || !focused || bytes.bytesAvailable<2)return;if(now<0)now=getTimer();
   var c:int=bytes.readUnsignedByte();var cc:int=bytes.readUnsignedByte();
   if(c==5 && cc==2){live=null;release();return;}
   if(c!=4 || cc!=4 || bytes.bytesAvailable<24)return;
   var id:int=bytes.readInt();var k:Object=root["Keys"];var game:Object=root["tfm"];if(!k || !game)return;
   var list:Object=game[k.player_list];var source:Object=list ? list[id] : null;
   if(!source || String(source[k.player_name]).toLowerCase()!=targetName)return;
   bytes.readInt();var r:Boolean=bytes.readBoolean();var l:Boolean=bytes.readBoolean();
   var px:Number=bytes.readInt()/100*30;var py:Number=bytes.readInt()/100*30;bytes.readShort();bytes.readShort();var j:Boolean=bytes.readBoolean();
   moveSerial++;live={serial:moveSerial,player:source,right:r,left:l,jump:j,time:now,x:px,y:py};
   // React during packet delivery; do not wait for the next display frame.
   update(now);
  }
  public function keyDown(event:KeyboardEvent):void{
   var input:TextField=root.stage.focus as TextField;
   if(event.keyCode==13 && input && input.type==TextFieldType.INPUT && /^\s*\/follow(?:\s|$)/i.test(input.text)){
    var requested:String=input.text;input.text="";root.stage.focus=root.stage;command(requested);update();event.preventDefault();event.stopImmediatePropagation();return;
   }
   if(event.keyCode==27 && targetName!="")stop("Follow: parado");
  }
  public function command(text:String):Boolean{
   if(!/^\s*\/follow(?:\s|$)/i.test(text))return false;
   var argument:String=text.replace(/^\s*\/follow\s*/i,"").replace(/\s+$/g,"");
   if(argument=="" || /^(?:off|stop|parar)$/i.test(argument)){stop("Follow: parado");return true;}
   if(!/^[^\s#]+#\d{4}$/.test(argument)){notice("Uso: /follow Nome#0000 | /follow off");return true;}
   var k:Object=root["Keys"];var game:Object=root["tfm"];var local:Object=k && game ? game[k.player] : null;
   if(local && String(local[k.player_name]).toLowerCase()==argument.toLowerCase()){stop("Follow: escolha outro jogador");return true;}
   live=null;release();targetName=argument.toLowerCase();owner=null;root["auto_play"]=false;needsSync=true;retryAt=0;notice("Follow: procurando "+argument+" nesta sala");return true;
  }
  public function stop(message:String="Follow: parado"):void{live=null;release();targetName="";owner=null;notice(message);}
  private function notice(message:String):void{
   state=message;if(!root.stage)return;if(!hud){hud=new TextField();hud.name="sddsFollowStatus";hud.defaultTextFormat=new TextFormat("_sans",12,0xD7F5FF);hud.width=540;hud.height=22;hud.background=true;hud.backgroundColor=0x141B2A;hud.selectable=false;hud.mouseEnabled=false;root.stage.addChild(hud);}hud.x=8;hud.y=Math.max(60,root.stage.stageHeight-48);hud.text=message;
  }
  private function key(code:uint,down:Boolean):void{if(root.stage)root.stage.dispatchEvent(new KeyboardEvent(down ? KeyboardEvent.KEY_DOWN : KeyboardEvent.KEY_UP,true,false,0,code));}
  private function movement(l:Boolean,r:Boolean,j:Boolean):void{
   // Release the previous direction before pressing its opposite.
   if(left && !l){key(37,false);left=false;}if(right && !r){key(39,false);right=false;}
   if(!left && l){key(37,true);left=true;}if(!right && r){key(39,true);right=true;}
   if(jumping!=j){key(38,j);jumping=j;}
  }
  private function release():void{movement(false,false,false);}
  public function update(now:int=-1):void{
   if(targetName=="" || !focused)return;if(now<0)now=getTimer();if(now<retryAt)return;
   try{
    var k:Object=root["Keys"];var game:Object=root["tfm"];var local:Object=k && game ? game[k.player] : null;
    if(local!==owner){live=null;release();owner=local;needsSync=true;}
    if(!local || (k.is_dead && local[k.is_dead])){live=null;needsSync=true;release();notice("Follow: aguardando renascer");return;}
    if(root.stage.focus is TextField && TextField(root.stage.focus).type==TextFieldType.INPUT){live=null;release();notice("Follow: pausado enquanto digita");return;}
    var found:Object=null;var list:Object=game[k.player_list];if(list)for each(var player:Object in list){if(player && String(player[k.player_name]).toLowerCase()==targetName){found=player;break;}}
    if(!found || found===local || (k.is_dead && found[k.is_dead]) || (found.hasOwnProperty("parent") && !found.parent)){release();notice("Follow: aguardando "+targetName+" nesta sala");return;}
    var body:Object=k.player_physics ? local[k.player_physics] : null;
    var round:Object=k.map_class && k.map_instance ? k.map_class[k.map_instance] : null;
    var roundNumber:Object=round && k.bot_map_code_object ? round[k.bot_map_code_object] : null;
    var code:String=roundNumber && k.bot_map_code_value ? String(roundNumber[k.bot_map_code_value]) : "";
    if(body!==bodyOwner || round!==roundOwner || code!=roundCode){live=null;needsSync=true;release();bodyOwner=body;roundOwner=round;roundCode=code;}
    if(!body || (k.player_clip && !local[k.player_clip])){release();notice("Follow: aguardando rato pronto na rodada");return;}
    if(k.move_class && k.move_free && !k.move_class[k.move_free]){release();notice("Follow: aguardando liberacao da rodada");return;}
    var point:Point=new Point(Number(found.x),Number(found.y));
    if(found is DisplayObject && local is DisplayObject){
     var source:DisplayObject=found as DisplayObject;var destination:DisplayObject=local as DisplayObject;
     if(!source.parent || !destination.parent){release();notice("Follow: aguardando mapa");return;}
     point=destination.parent.globalToLocal(source.parent.localToGlobal(point));
    }
    var x:Number=point.x;var y:Number=point.y;
    if(!isFinite(x) || !isFinite(y))throw new Error("Coordenadas indisponiveis");
    var targetJump:Boolean=false;
    if(k.is_jumping && found.hasOwnProperty(String(k.is_jumping)) && found[k.is_jumping] is Boolean)targetJump=Boolean(found[k.is_jumping]);
    if(needsSync){
     
     if(!k.packet_handler_class || !k.packet_handler || !(k.packet_handler_class[k.packet_handler] is Function))throw new Error("Teleport nativo indisponivel",2206);
     k.packet_handler_class[k.packet_handler](LegacyOptionsV5.encodePosition(Math.round(x),Math.round(y)));
    }
    // Initial sync uses the visible position; subsequent moves use wire coordinates.
    needsSync=false;
    var dx:Number=x-Number(local.x);
    var goLeft:Boolean=dx < -4;var goRight:Boolean=dx > 4;
    // Near the target, react to its native direction instead of waiting for a gap to grow.
    if(Math.abs(dx)<=8 && k.player_moving_left && k.player_moving_right){
     var remoteLeft:Boolean=Boolean(found[k.player_moving_left]);var remoteRight:Boolean=Boolean(found[k.player_moving_right]);
     if(remoteLeft!=remoteRight){goLeft=remoteLeft;goRight=remoteRight;}
    }
    if(live && live.player===found && now>=live.time && now-live.time<=250){
     goLeft=live.left;goRight=live.right;targetJump=live.jump;
    }
    // Apply every newly received move exactly once; never replay on display frames.
    if(live && live.player===found && now>=live.time && now-live.time<=250 && live.serial!=appliedSerial){
     var goal:Point=new Point(live.x,live.y);
     if(found is DisplayObject && local is DisplayObject)goal=DisplayObject(local).parent.globalToLocal(DisplayObject(found).parent.localToGlobal(goal));
     if(!isFinite(goal.x) || !isFinite(goal.y))throw new Error("Pacote de posicao invalido");
     appliedSerial=live.serial;
     k.packet_handler_class[k.packet_handler](LegacyOptionsV5.encodePosition(Math.round(goal.x),Math.round(goal.y)));
    }
    movement(goLeft,goRight,targetJump);
    notice("Follow v12: coordenadas por move | "+targetName+(k.is_jumping ? "" : " | pulo do alvo indisponivel"));

   }catch(error:Error){release();retryAt=now+500;notice("Follow: aguardando sincronizacao #"+error.errorID);}
  }
 }
}
