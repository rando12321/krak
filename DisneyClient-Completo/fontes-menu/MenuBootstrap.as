// ActionScript 3 / MenuBootstrap.as / Flash Player 11+ / DisneyClient loader menu initialization
package disney {
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.filters.DropShadowFilter;
    import flash.geom.Rectangle;
    import flash.text.TextFieldType;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.getDefinitionByName;
    public class MenuBootstrap {
        public static function attach(root:MovieClip):void {
            if (!root || !root.stage || root.stage.getChildByName("disneyMenuButton")) return;
            var button:Sprite = new Sprite();
            button.name = "disneyMenuButton";
            button.graphics.lineStyle(1, 0x6654B5, 1);
            button.graphics.beginFill(0x141B2A, 0.98);
            button.graphics.drawRoundRect(0, 0, 100, 28, 8, 8);
            button.graphics.endFill();
            button.x = 8; button.y = 8; button.buttonMode = true;
            var label:TextField = new TextField();
            label.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF, true);
            label.text = "Menu SDDS"; label.width = 100; label.height = 25;
            label.mouseEnabled = false; label.selectable = false;
            label.x = 8; label.y = 3; button.addChild(label);
            var status:TextField = new TextField();
            status.name = "disneyMenuStatus";
            status.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF);
            status.background = true; status.backgroundColor = 0x25344B;
            status.width = 620; status.height = 38; status.x = 8; status.y = 39;
            status.visible = false; status.selectable = true;
            root.stage.addChild(status); root.stage.addChild(button);
            button.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
                event.stopImmediatePropagation();
                showMenu(root, status, button, true);
            });
            showMenu(root, status, button, false);
        }
        private static function showMenu(root:MovieClip, status:TextField, button:Sprite, toggle:Boolean):void {
            try {
                var keys:Object = root["Keys"];
                var required:Array = ["ui_element_class", "prep_ui_class", "set_prep_ui", "add_ui_element", "prep_ui1_instance", "prep_ui4_instance", "ui_items_list_class", "select_item"];
                var missing:Array = [];
                for each (var name:String in required) if (!keys[name]) missing.push(name);
                if (missing.length) {
                    status.text = "Menu indisponivel: simbolos ausentes: " + missing.join(", ");
                    status.visible = true;
                    return;
                }
                var instance:Object = root["Interface"];
                if (instance && toggle && instance["menu_ui"] && instance["menu_ui"].parent) {
                    instance["menu_ui"].parent.removeChild(instance["menu_ui"]);
                    return;
                }
                if (!instance) {
                    var MenuClass:Class = getDefinitionByName("ChargeurTransformice_fla.Interface") as Class;
                    instance = new MenuClass();
                    root["Interface"] = instance;
                }
                var menu:DisplayObject = buildModernMenu(root, instance);
                if (!menu) throw new Error("Missing menu display object");
                root.stage.addChild(menu);
                menu.visible = true;
                instance["menu_x"] = menu.x; instance["menu_y"] = menu.y;
                styleControls(instance["options_ui"] as DisplayObject);
                status.visible = false;
                root.stage.addChild(button);
            } catch (error:Error) {
                status.text = "Falha ao construir o menu. Codigo Flash: " + error.errorID;
                status.visible = false;
            }
        }
        private static function label(text:String, size:Number, color:uint, bold:Boolean=false):TextField {
            var field:TextField = new TextField();
            field.defaultTextFormat = new TextFormat("_sans", size, color, bold);
            field.text = text; field.selectable = false; field.mouseEnabled = false;
            field.width = 520; field.height = size + 10;
            return field;
        }
        private static function styleControls(node:DisplayObject):void {
            if (!node) return;
            if (node is TextField) {
                var field:TextField = node as TextField;
                var format:TextFormat = field.getTextFormat();
                format.font = "_sans"; format.color = 0xD7DEEC;
                field.defaultTextFormat = format; field.setTextFormat(format);
                if (field.type == TextFieldType.INPUT) {
                    field.background = true; field.backgroundColor = 0x101827;
                    field.border = true; field.borderColor = 0x35405B;
                }
            }
            if (node is DisplayObjectContainer) {
                var container:DisplayObjectContainer = node as DisplayObjectContainer;
                for (var i:int=0; i<container.numChildren; i++) styleControls(container.getChildAt(i));
            }
        }
        private static function navButton(title:String, active:Boolean):Sprite {
            var button:Sprite = new Sprite();
            button.buttonMode = true; button.mouseChildren = false;
            paintNav(button, active, false);
            var text:TextField = label(title, 13, active ? 0xFFFFFF : 0x9EAAC3, active);
            text.x = 15; text.y = 10; text.width = 125;
            button.addChild(text);
            return button;
        }
        private static function paintNav(button:Sprite, active:Boolean, hover:Boolean):void {
            button.graphics.clear();
            button.graphics.beginFill(active ? 0x29234A : (hover ? 0x1B2435 : 0x121A28));
            button.graphics.drawRoundRect(0, 0, 142, 40, 10, 10);
            button.graphics.endFill();
            if (active) {
                button.graphics.beginFill(0xA58AFF);
                button.graphics.drawRoundRect(0, 10, 3, 20, 3, 3);
                button.graphics.endFill();
            }
        }
        private static function buildModernMenu(root:MovieClip, instance:Object):DisplayObject {
            var existing:DisplayObject = instance["menu_ui"] as DisplayObject;
            if (existing && existing.name == "disneyModernPanel") return existing;
            var options:DisplayObject = instance["options_ui"] as DisplayObject;
            if (!options) throw new Error("Missing options UI");
            var panel:Sprite = new Sprite(); panel.name = "disneyModernPanel";
            panel.graphics.lineStyle(1, 0x293349);
            panel.graphics.beginFill(0x0E1420, 0.99);
            panel.graphics.drawRoundRect(0, 0, 760, 430, 18, 18);
            panel.graphics.endFill();
            panel.filters = [new DropShadowFilter(8, 90, 0x000000, 0.45, 22, 22, 1, 2)];
            panel.graphics.lineStyle(1, 0x273146);
            panel.graphics.moveTo(0, 62); panel.graphics.lineTo(760, 62);
            panel.graphics.moveTo(173, 62); panel.graphics.lineTo(173, 398);
            panel.graphics.moveTo(18, 398); panel.graphics.lineTo(742, 398);
            panel.graphics.lineStyle();
            panel.graphics.beginFill(0xA58AFF); panel.graphics.drawRoundRect(20, 21, 5, 20, 4, 4); panel.graphics.endFill();
            var brand:TextField = label("DISNEY", 20, 0xF1F4FF, true);
            brand.x = 36; brand.y = 14; panel.addChild(brand);
            var edition:TextField = label("CLIENT / CONTROLE", 10, 0x8390AB, true);
            edition.x = 145; edition.y = 23; panel.addChild(edition);
            var modules:TextField = label("MODULOS", 10, 0x667792, true);
            modules.x = 22; modules.y = 78; panel.addChild(modules);
            var section:TextField = label("Jogador", 18, 0xEEF2FF, true);
            section.x = 193; section.y = 76; panel.addChild(section);
            var hint:TextField = label("Controles da sessao", 11, 0x8190AB);
            hint.x = 193; hint.y = 105; panel.addChild(hint);
            panel.graphics.beginFill(0x151E2E); panel.graphics.drawRoundRect(187, 137, 555, 250, 12, 12); panel.graphics.endFill();
            var viewport:Sprite = new Sprite(); viewport.x = 194; viewport.y = 144;
            viewport.scrollRect = new Rectangle(0, 0, 535, 232); panel.addChild(viewport);
            if (options.parent) options.parent.removeChild(options);
            options.x = 0; options.y = 0; viewport.addChild(options);
            var scroll:Number = 0;
            var maxScroll:Number = 0;
            var tabs:Array = [{id:"general", title:"Jogador", hint:"Movimento e atributos", field:"general_ui"}];
            if (instance["farm_ui"]) tabs.push({id:"farm",title:"Farm",hint:"Rotinas e reproducao",field:"farm_ui"});
            if (instance["bot_ui"]) tabs.push({id:"bot",title:"Bot",hint:"Controles de automacao",field:"bot_ui"});
            tabs.push({id:"keyboard",title:"Atalhos",hint:"Teclas e comandos",field:"keys_ui"});
            tabs.push({id:"settings",title:"Ajustes",hint:"Preferencias do client",field:"settings_ui"});
            var buttons:Object = {};
            var selected:String = String(instance["last_tab"] || "general");
            var validSelection:Boolean = false;
            for each (var available:Object in tabs) if (available.id == selected) validSelection = true;
            if (!validSelection) selected = "general";
            var selectTab:Function = function(id:String):void {
                instance["change_menu_tab"](id);
                selected = id; scroll = 0; viewport.scrollRect = new Rectangle(0, 0, 535, 232);
                for each (var data:Object in tabs) {
                    var nav:Sprite = buttons[data.id] as Sprite;
                    if (nav) {
                        paintNav(nav, data.id == selected, false);
                        var text:TextField = nav.getChildAt(0) as TextField;
                        text.textColor = data.id == selected ? 0xFFFFFF : 0x9EAAC3;
                    }
                    if (data.id == selected) {
                        section.text = data.title; hint.text = data.hint;
                        var content:DisplayObject = instance[data.field] as DisplayObject;
                        maxScroll = content ? Math.max(0, content.height - 215) : 0;
                    }
                }
                styleControls(options);
            };
            for (var index:int=0; index<tabs.length; index++) {
                var tab:Object = tabs[index];
                var nav:Sprite = navButton(tab.title, tab.id == selected);
                nav.x = 16; nav.y = 105 + index * 49; panel.addChild(nav); buttons[tab.id] = nav;
                bindNav(nav, tab.id, selectTab, function():String { return selected; });
            }
            viewport.addEventListener(MouseEvent.MOUSE_WHEEL, function(event:MouseEvent):void {
                maxScroll = Math.max(0, options.height - 225);
                scroll = Math.max(0, Math.min(maxScroll, scroll - event.delta * 22));
                viewport.scrollRect = new Rectangle(0, scroll, 535, 232);
                event.stopPropagation();
            });
            var footer:TextField = label("ROLE PARA VER MAIS", 10, 0x6F7E99);
            footer.x = 194; footer.y = 407; panel.addChild(footer);
            var dragHint:TextField = label("ARRASTE O TOPO", 10, 0x6F7E99);
            dragHint.x = 609; dragHint.y = 407; dragHint.width = 145; panel.addChild(dragHint);
            var drag:Sprite = new Sprite(); drag.graphics.beginFill(0x000000,0);
            drag.graphics.drawRect(0,0,692,60); drag.graphics.endFill(); panel.addChild(drag);
            drag.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                panel.startDrag(false, new Rectangle(8,44,Math.max(0,root.stage.stageWidth-panel.width-16),Math.max(0,root.stage.stageHeight-panel.height-52)));
                event.stopPropagation();
            });
            root.stage.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                panel.stopDrag(); instance["menu_x"] = panel.x; instance["menu_y"] = panel.y;
            });
            var close:Sprite = new Sprite();close.buttonMode = true;close.mouseChildren = false;
            close.graphics.beginFill(0x202A3C);close.graphics.drawRoundRect(0,0,30,30,8,8);close.graphics.endFill();
            var cross:TextField = label("x",15,0xC4CDE1,true);cross.x=10;cross.y=4;cross.width=22;close.addChild(cross);
            close.x=710;close.y=16;panel.addChild(close);
            close.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void {
                if(panel.parent)panel.parent.removeChild(panel);event.stopImmediatePropagation();
            });
            var factor:Number = Math.min(1, Math.max(0.45, (root.stage.stageWidth-24)/760), Math.max(0.45,(root.stage.stageHeight-72)/430));
            panel.scaleX = factor; panel.scaleY = factor;
            panel.x = Math.max(8,(root.stage.stageWidth-760*factor)/2); panel.y=52;
            instance["menu_ui"] = panel;
            selectTab(selected);
            return panel;
        }
        private static function bindNav(button:Sprite, id:String, select:Function, current:Function):void {
            button.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void { select(id);event.stopImmediatePropagation(); });
            button.addEventListener(MouseEvent.MOUSE_OVER,function(event:MouseEvent):void { paintNav(button,current()==id,true); });
            button.addEventListener(MouseEvent.MOUSE_OUT,function(event:MouseEvent):void { paintNav(button,current()==id,false); });
        }

    }
}
