"""Foreground-only Win32 scan-code keyboard adapter and leased state protocol."""
import ctypes as c
import ntpath
import os
import threading
import time

ALLOWED = frozenset((37, 38, 39, 40))


class KeyboardError(Exception):
    pass


class UnsupportedKeyboard(KeyboardError):
    pass


class KEYBDINPUT(c.Structure):
    _fields_ = [('wVk', c.c_uint16), ('wScan', c.c_uint16), ('dwFlags', c.c_uint32), ('time', c.c_uint32), ('dwExtraInfo', c.c_size_t)]


class MOUSEINPUT(c.Structure):
    _fields_ = [('dx', c.c_int32), ('dy', c.c_int32), ('mouseData', c.c_uint32), ('dwFlags', c.c_uint32), ('time', c.c_uint32), ('dwExtraInfo', c.c_size_t)]


class HARDWAREINPUT(c.Structure):
    _fields_ = [('uMsg', c.c_uint32), ('wParamL', c.c_uint16), ('wParamH', c.c_uint16)]


class INPUTUNION(c.Union):
    _fields_ = [('ki', KEYBDINPUT), ('mi', MOUSEINPUT), ('hi', HARDWAREINPUT)]


class INPUT(c.Structure):
    _anonymous_ = ('value',)
    _fields_ = [('type', c.c_uint32), ('value', INPUTUNION)]


class WindowsKeyboard:
    def __init__(self):
        if os.name != 'nt':
            raise UnsupportedKeyboard('Teclas reais requerem backend local no Windows e Adobe_10.exe em foco.')
        self.user = c.WinDLL('user32', use_last_error=True)
        self.kernel = c.WinDLL('kernel32', use_last_error=True)
        self.user.GetForegroundWindow.restype = c.c_void_p
        self.user.GetWindowThreadProcessId.argtypes = [c.c_void_p, c.POINTER(c.c_uint32)]
        self.user.MapVirtualKeyW.argtypes = [c.c_uint32, c.c_uint32]
        self.user.MapVirtualKeyW.restype = c.c_uint32
        self.user.SendInput.argtypes = [c.c_uint32, c.POINTER(INPUT), c.c_int]
        self.user.SendInput.restype = c.c_uint32
        self.kernel.OpenProcess.argtypes = [c.c_uint32, c.c_int, c.c_uint32]
        self.kernel.OpenProcess.restype = c.c_void_p
        self.kernel.QueryFullProcessImageNameW.argtypes = [c.c_void_p, c.c_uint32, c.c_wchar_p, c.POINTER(c.c_uint32)]
        self.kernel.CloseHandle.argtypes = [c.c_void_p]

    def target(self):
        hwnd = self.user.GetForegroundWindow()
        pid = c.c_uint32()
        self.user.GetWindowThreadProcessId(hwnd, c.byref(pid))
        handle = self.kernel.OpenProcess(0x1000, False, pid.value)
        if not handle:
            raise KeyboardError('Nao foi possivel identificar a janela em foco.')
        try:
            path = c.create_unicode_buffer(32768)
            size = c.c_uint32(len(path))
            if not self.kernel.QueryFullProcessImageNameW(handle, 0, path, c.byref(size)):
                raise KeyboardError('Nao foi possivel identificar o executavel em foco.')
            if ntpath.basename(path.value).casefold() != 'adobe_10.exe':
                raise KeyboardError('Mantenha a janela Adobe_10.exe do jogo em foco.')
            return int(hwnd), int(pid.value)
        finally:
            self.kernel.CloseHandle(handle)

    def send(self, key, down):
        if key not in ALLOWED:
            raise KeyboardError('Tecla nao permitida.')
        scan = self.user.MapVirtualKeyW(key, 0) & 255
        if not scan:
            raise KeyboardError('Nao foi possivel mapear a seta no teclado.')
        event = INPUT(type=1)
        event.ki = KEYBDINPUT(0, scan, 0x0008 | 0x0001 | (0 if down else 0x0002), 0, 0)
        if self.user.SendInput(1, c.byref(event), c.sizeof(INPUT)) != 1:
            raise KeyboardError('Windows recusou SendInput; confira o nivel de permissao do Flash e do backend.')


class KeyboardController:
    def __init__(self, sink=None, clock=time.monotonic, lease=.5, watchdog=True):
        self.sink = sink
        self.clock = clock
        self.lease = lease
        self.held = set()
        self.owner = None
        self.target_window = None
        self.deadline = 0
        self.sequences = {}
        self.pulse = 0
        self.lock = threading.RLock()
        self.closed = threading.Event()
        self.thread = None
        self.watchdog = watchdog

    def _release(self):
        failed = []
        for key in sorted(self.held):
            try:
                self.sink.send(key, False)
            except (KeyboardError, OSError):
                failed.append(key)
        self.held = set(failed)
        self.owner = None
        self.target_window = None
        if failed:
            raise KeyboardError('Nao foi possivel confirmar a soltura de todas as setas.')

    def expire(self):
        with self.lock:
            if (self.owner is not None and self.clock() >= self.deadline) or (self.owner is None and self.held):
                self._release()

    def _watch(self):
        while not self.closed.wait(.05):
            try:
                self.expire()
            except (KeyboardError, OSError):
                # Retry release while retaining the keys whose release failed.
                with self.lock:
                    try:
                        self._release()
                    except (KeyboardError, OSError):
                        pass

    def update(self, owner, session, seq, keys, pulse=0):
        if not isinstance(session, str) or not 1 <= len(session) <= 64:
            raise ValueError('invalid keyboard session')
        if type(seq) is not int or not 0 <= seq <= 2147483647 or type(pulse) is not int or not 0 <= pulse <= 2147483647:
            raise ValueError('invalid keyboard sequence')
        if not isinstance(keys, list) or len(keys) > 4 or any(type(k) is not int or k not in ALLOWED for k in keys):
            raise ValueError('invalid keyboard keys')
        desired = set(keys)
        if {37, 39} <= desired:
            raise ValueError('opposite directions')
        identity = owner, session
        with self.lock:
            self.expire()
            if self.closed.is_set():
                raise KeyboardError('Ponte de teclado encerrada.')
            if self.sink is None:
                self.sink = WindowsKeyboard()
            if self.owner is not None and self.owner != identity:
                raise KeyboardError('Outra sessao local esta usando o teclado do robo.')
            if identity not in self.sequences and len(self.sequences) >= 256:
                raise KeyboardError('Limite de sessoes locais; reinicie o backend para uma nova sessao.')
            if seq <= self.sequences.get(identity, -1):
                return {'success': True, 'stale': True, 'seq': self.sequences[identity], 'keys': sorted(self.held)}
            if self.owner is not None and self.owner != identity:
                raise KeyboardError('Outra sessao local esta usando o teclado do robo.')
            # A release must work even after focus moves away from Flash.
            if desired:
                try:
                    target = self.sink.target()
                except (KeyboardError, OSError):
                    self._release()
                    raise
                if self.target_window is not None and self.target_window != target:
                    self._release()
                    raise KeyboardError('A janela em foco mudou; teclado liberado.')
            else:
                target = self.target_window
            self.sequences[identity] = seq
            try:
                for key in sorted(self.held - desired):
                    self.sink.send(key, False)
                    self.held.remove(key)
                if self.owner == identity and pulse > self.pulse and 38 in self.held and 38 in desired:
                    self.sink.send(38, False)
                    self.held.remove(38)
                for key in sorted(desired - self.held):
                    self.sink.send(key, True)
                    self.held.add(key)
            except (KeyboardError, OSError):
                self._release()
                raise
            self.owner = identity
            self.target_window = target
            self.pulse = pulse
            self.deadline = self.clock() + self.lease
            if self.watchdog and self.thread is None:
                self.thread = threading.Thread(target=self._watch, daemon=True, name='robot-keyboard-lease')
                self.thread.start()
            return {'success': True, 'stale': False, 'seq': seq, 'keys': sorted(self.held), 'lease_ms': int(self.lease * 1000)}

    def close(self):
        self.closed.set()
        with self.lock:
            self._release()
        if self.thread is not None and self.thread is not threading.current_thread():
            self.thread.join(timeout=1)
