# Python / chatmessage.py / Python 3.11 / DisneyParser
"""Locate chat methods without depending on split debug strings or register numbers."""
from .regex import CALL_PROPVOID, CLASS, PUBLIC_METHOD


class ChatMessage(dict):
    async def fetch(self, dumpscript, chat_class_name2=None):
        candidates = set()
        for index, line in enumerate(dumpscript):
            if 'navigator.appVersion' in line or 'pushstring "Navigateur : "' in line:
                for following in dumpscript[index + 1:index + 14]:
                    match = CALL_PROPVOID.search(following)
                    if match and match.group(2) == '1':
                        candidates.add(match.group(1))
                        break
        if len(candidates) == 1:
            self['chat_message'] = candidates.pop()

        if chat_class_name2 is None:
            from .chatclass import Chat
            chat_class_name2 = (await Chat().fetch(dumpscript)).get('chat_class_name2')
        if not chat_class_name2:
            return self
        inside = False
        candidates = set()
        for line in dumpscript:
            declaration = CLASS.search(line)
            if declaration:
                if inside:
                    break
                inside = declaration.group(1) == chat_class_name2
            if inside and '(2 params, 1 optional)' in line:
                if '<q>[public]::String' in line and '<q>[public]::Boolean' in line:
                    method = PUBLIC_METHOD.search(line)
                    if method and method.group(2) == 'void':
                        candidates.add(method.group(3))
        if len(candidates) == 1:
            self['chat_message2'] = candidates.pop()
        return self
