import ctypes
import importlib.util
import os
from pathlib import Path
import sys
import unittest

CLIENT = Path(__file__).resolve().parents[1] / 'DisneyClient'
sys.path.insert(0, str(CLIENT))
from native_keyboard import INPUT, KEYBDINPUT, KeyboardController, KeyboardError, UnsupportedKeyboard, WindowsKeyboard


class FakeSink:
    def __init__(self):
        self.events = []
        self.focus = (10, 20)
        self.fail_focus = False

    def target(self):
        if self.fail_focus:
            raise KeyboardError('wrong focus')
        return self.focus

    def send(self, key, down):
        self.events.append((key, down))


class NativeKeyboardTests(unittest.TestCase):
    def setUp(self):
        self.now = 0.0
        self.sink = FakeSink()
        self.robot = KeyboardController(self.sink, lambda: self.now, watchdog=False)

    def update(self, seq, keys, pulse=0, owner='test-user', session='test-session'):
        return self.robot.update(owner, session, seq, keys, pulse)

    def tearDown(self):
        self.robot.close()

    def test_presses_and_releases_real_adapter_states(self):
        self.assertEqual(self.update(1, [39, 38])['keys'], [38, 39])
        self.update(2, [])
        self.assertEqual(self.sink.events, [(38, True), (39, True), (38, False), (39, False)])

    def test_repeat_heartbeat_does_not_repeat_key_down(self):
        self.update(1, [39]); self.update(2, [39]); self.update(3, [39])
        self.assertEqual(self.sink.events, [(39, True)])

    def test_reversal_releases_opposite_before_press(self):
        self.update(1, [39]); self.update(2, [37])
        self.assertEqual(self.sink.events, [(39, True), (39, False), (37, True)])

    def test_pulse_rearms_up_without_direction_chatter(self):
        self.update(1, [38, 39], 1); self.update(2, [38, 39], 2)
        self.assertEqual(self.sink.events, [(38, True), (39, True), (38, False), (38, True)])

    def test_old_http_reply_cannot_repress_released_key(self):
        self.update(2, [])
        self.assertTrue(self.update(1, [39])['stale'])
        self.assertEqual(self.sink.events, [])

    def test_focus_change_releases_owned_keys(self):
        self.update(1, [39]); self.sink.focus = (30, 40)
        with self.assertRaises(KeyboardError): self.update(2, [39])
        self.assertEqual(self.sink.events[-1], (39, False))
        self.assertFalse(self.robot.held)

    def test_non_flash_focus_releases_without_sending_new_key(self):
        self.update(1, [39]); self.sink.fail_focus = True
        with self.assertRaises(KeyboardError): self.update(2, [37])
        self.assertEqual(self.sink.events, [(39, True), (39, False)])

    def test_release_does_not_require_flash_focus(self):
        self.update(1, [39]); self.sink.fail_focus = True
        self.update(2, [])
        self.assertFalse(self.robot.held)

    def test_missing_heartbeat_releases_keys(self):
        self.update(1, [38, 39]); self.now = .6; self.robot.expire()
        self.assertFalse(self.robot.held)
        self.assertIn((38, False), self.sink.events)
        self.assertIn((39, False), self.sink.events)

    def test_heartbeat_extends_lease(self):
        self.update(1, [39]); self.now = .3; self.update(2, [39]); self.now = .6; self.robot.expire()
        self.assertEqual(self.robot.held, {39})
        self.now = .9; self.robot.expire(); self.assertFalse(self.robot.held)

    def test_second_session_cannot_steal_active_window(self):
        self.update(1, [39])
        with self.assertRaises(KeyboardError): self.update(2, [37], session='other')
        self.assertEqual(self.sink.events, [(39, True)])

    def test_invalid_keys_and_opposite_directions_are_rejected(self):
        for keys in ([65], [37, 39], [True], [39, 38, 37, 40, 39]):
            with self.subTest(keys=keys), self.assertRaises(ValueError): self.update(1, keys)
        self.assertEqual(self.sink.events, [])

    def test_sequence_and_session_validation(self):
        for seq in (-1, True, 2**31, '1'):
            with self.assertRaises(ValueError): self.update(seq, [])
        with self.assertRaises(ValueError): self.update(1, [], session='')

    def test_close_releases_and_rejects_further_input(self):
        self.update(1, [39]); self.robot.close()
        self.assertFalse(self.robot.held)
        with self.assertRaises(KeyboardError): self.update(2, [39])

    def test_win32_structure_layout(self):
        self.assertEqual(ctypes.sizeof(INPUT), 40 if ctypes.sizeof(ctypes.c_void_p) == 8 else 28)
        self.assertEqual(KEYBDINPUT.dwFlags.offset, 4)
        self.assertEqual(INPUT.value.offset, 8 if ctypes.sizeof(ctypes.c_void_p) == 8 else 4)

    @unittest.skipIf(os.name == 'nt', 'non-Windows rejection check')
    def test_no_synthetic_fallback_on_non_windows(self):
        with self.assertRaises(UnsupportedKeyboard): WindowsKeyboard()

    def test_scan_code_sendinput_adapter(self):
        calls = []
        class User:
            def MapVirtualKeyW(self, key, kind): return {37: 0x4b, 38: 0x48, 39: 0x4d, 40: 0x50}[key]
            def SendInput(self, count, pointer, size):
                value = ctypes.cast(pointer, ctypes.POINTER(INPUT)).contents
                calls.append((count, size, value.type, value.ki.wVk, value.ki.wScan, value.ki.dwFlags))
                return 1
        driver = WindowsKeyboard.__new__(WindowsKeyboard); driver.user = User()
        driver.send(39, True); driver.send(39, False)
        self.assertEqual(calls[0], (1, ctypes.sizeof(INPUT), 1, 0, 0x4d, 0x0009))
        self.assertEqual(calls[1][-1], 0x000b)

    def test_failed_sendinput_is_reported(self):
        class User:
            def MapVirtualKeyW(self, key, kind): return 0x4d
            def SendInput(self, *args): return 0
        driver = WindowsKeyboard.__new__(WindowsKeyboard); driver.user = User()
        with self.assertRaises(KeyboardError): driver.send(39, True)



    def test_watchdog_thread_releases_without_any_more_requests(self):
        import threading
        released = threading.Event()
        class Sink(FakeSink):
            def send(self, key, down):
                super().send(key, down)
                if not down: released.set()
        robot = KeyboardController(Sink(), lease=.01, watchdog=True)
        try:
            robot.update('test-user', 'watchdog', 1, [39])
            self.assertTrue(released.wait(.5))
            with robot.lock:
                self.assertFalse(robot.held)
        finally:
            robot.close()


class NativeKeyboardHTTPTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        import types
        from aiohttp import web
        from aiohttp.test_utils import TestClient, TestServer
        package = types.ModuleType('keyboard_test_api')
        package.__path__ = [str(CLIENT / 'api')]
        sys.modules['keyboard_test_api'] = package
        def load(name, path):
            spec = importlib.util.spec_from_file_location(name, path)
            module = importlib.util.module_from_spec(spec);sys.modules[name] = module;spec.loader.exec_module(module);return module
        load('keyboard_test_api.common', CLIENT / 'api/common.py')
        self.endpoint = load('keyboard_test_api.native_keyboard', CLIENT / 'api/native_keyboard.py')
        class DB:
            async def session(self, token, address, **kwargs):
                return {'user_id': 'test-user'} if token == 'test-token' and kwargs.get('flash') == 'test-flash' else None
        self.sink = FakeSink();self.robot = KeyboardController(self.sink, watchdog=False)
        app = web.Application();app['db'] = DB();app['native_keyboard'] = self.robot
        app.router.add_view('/native_keyboard', self.endpoint.NativeKeyboard)
        self.client = TestClient(TestServer(app));await self.client.start_server()
        self.url = '/native_keyboard?access_token=test-token&flash_token=test-flash'

    async def asyncTearDown(self):
        self.robot.close();await self.client.close()

    def state(self, seq=1, keys=None):
        return {'session': 'test-session', 'seq': seq, 'keys': keys if keys is not None else [39], 'pulse': 0}

    async def test_authenticated_loopback_delivers_key_state(self):
        response = await self.client.post(self.url, json=self.state())
        self.assertEqual(response.status, 200);self.assertEqual((await response.json())['keys'], [39])
        self.assertEqual(self.sink.events, [(39, True)])

    async def test_missing_auth_never_sends_input(self):
        response = await self.client.post('/native_keyboard', json=self.state())
        self.assertEqual(response.status, 401);self.assertEqual(self.sink.events, [])

    async def test_wrong_flash_binding_never_sends_input(self):
        response = await self.client.post('/native_keyboard?access_token=test-token&flash_token=wrong', json=self.state())
        self.assertEqual(response.status, 401);self.assertEqual(self.sink.events, [])

    async def test_invalid_payload_is_rejected(self):
        for body in ({}, dict(self.state(), other=True), self.state(keys=[37, 39]), self.state(keys=[65])):
            response = await self.client.post(self.url, json=body)
            self.assertEqual(response.status, 400)
        response = await self.client.post(self.url, data='{', headers={'Content-Type': 'application/json'})
        self.assertEqual(response.status, 400);self.assertEqual(self.sink.events, [])

    async def test_focus_failure_is_reported_and_releases(self):
        await self.client.post(self.url, json=self.state());self.sink.fail_focus = True
        response = await self.client.post(self.url, json=self.state(2, [37]))
        self.assertEqual(response.status, 409);self.assertFalse((await response.json())['success'])
        self.assertEqual(self.sink.events[-1], (39, False))

    async def test_stale_http_state_cannot_press_after_release(self):
        await self.client.post(self.url, json=self.state(2, []))
        response = await self.client.post(self.url, json=self.state(1, [39]))
        self.assertEqual(response.status, 200);self.assertTrue((await response.json())['stale']);self.assertEqual(self.sink.events, [])

    async def test_remote_request_is_forbidden_before_auth_or_input(self):
        import types
        from aiohttp import web
        view = self.endpoint.NativeKeyboard(types.SimpleNamespace(remote='192.0.2.1'))
        with self.assertRaises(web.HTTPForbidden): await view.post()
        self.assertEqual(self.sink.events, [])

if __name__ == '__main__': unittest.main()
