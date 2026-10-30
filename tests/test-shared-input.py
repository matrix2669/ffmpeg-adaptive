#!/usr/bin/env python3
"""Local-only contracts for shared HTTP MPEG-TS startup and cleanup."""
import concurrent.futures
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import tempfile
import threading
import time
import unittest
from unittest.mock import patch
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('shared_input', ROOT / 'lib/ffsmart-shared-input.py')
shared = importlib.util.module_from_spec(spec)
spec.loader.exec_module(shared)
PACKETS = b''.join(b'\x47' + n.to_bytes(4, 'big') + bytes([n % 251]) * 183 for n in range(5000))


class Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.base = Path(cls.temp.name)
        cls.bin = cls.base / 'bin'
        cls.bin.mkdir()
        tool = '''#!/usr/bin/env python3
import os, sys, urllib.request
from pathlib import Path
if sys.argv[1:] == ['-version']:
    print(Path(sys.argv[0]).name + ' version shared-test'); sys.exit()
if Path(sys.argv[0]).name == 'ffprobe':
    with urllib.request.urlopen(sys.argv[-1], timeout=5) as response:
        data = response.read(int(os.environ.get('TEST_PROBE_BYTES', '940')))
    count = Path(os.environ['TEST_RUN']) / 'count'
    number = int(count.read_text()) + 1 if count.exists() else 1
    count.write_text(str(number))
    (count.parent / ('prefix%d' % number)).write_bytes(data)
    print('index=0|codec_name=h264|codec_type=video|width=320|height=240|pix_fmt=yuv420p|r_frame_rate=25/1|field_order=progressive')
    print('index=1|codec_name=aac|codec_type=audio|sample_rate=48000|channels=' + ('0' if number < 3 else '2'))
else:
    Path(os.environ['TEST_RUN'], 'args').write_text('\\n'.join(sys.argv))
    if os.environ.get('TEST_BLOCK'):
        import time
        time.sleep(100)
    with urllib.request.urlopen(sys.argv[sys.argv.index('-i') + 1], timeout=5) as response:
        while True:
            data = response.read(65536)
            if not data: break
            sys.stdout.buffer.write(data)
'''
        for name in ('ffmpeg', 'ffprobe'):
            p = cls.bin / name
            p.write_text(tool)
            p.chmod(0o755)
        cls.requests = []
        cls.lock = threading.Lock()

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_): pass
            def do_GET(self):
                with cls.lock:
                    cls.requests.append((self.path, dict(self.headers)))
                if self.path.startswith('/loop'):
                    self.send_response(302)
                    self.send_header('Location', '/loop')
                    self.end_headers()
                    return
                if self.path.startswith('/redirect'):
                    self.send_response(302)
                    self.send_header('Location', '/ok')
                    self.end_headers()
                    return
                if self.path.startswith('/cross'):
                    self.send_response(302)
                    self.send_header('Location', 'http://localhost:%d/ok' % cls.server.server_port)
                    self.end_headers()
                    return
                self.send_response(200)
                body = PACKETS
                if self.path.startswith('/bad'): body = b'#EXTM3U\n' * 100
                if self.path.startswith('/early'): body = b'\x47' * 100
                if self.path.startswith('/truncated'):
                    self.send_header('Content-Length', str(len(body) * 2))
                elif not self.path.startswith('/stall'):
                    self.send_header('Content-Length', str(len(body) * (64 if self.path.startswith('/large') else 1)))
                self.end_headers()
                try:
                    if self.path.startswith('/stall'):
                        self.wfile.write(PACKETS[:188 * 5])
                        self.wfile.flush()
                        time.sleep(4)
                    else:
                        for _ in range(64 if self.path.startswith('/large') else 1):
                            for i in range(0, len(body), 4096):
                                self.wfile.write(body[i:i + 4096])
                except (BrokenPipeError, ConnectionResetError): pass
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.server.daemon_threads = True
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = 'http://127.0.0.1:%d' % cls.server.server_port

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.temp.cleanup()

    def setup_run(self, name, real=False):
        run = self.base / name
        run.mkdir()
        state = run / 'state'
        state.mkdir()
        env = dict(os.environ, FFMPEG_SMART_STATE_DIR=str(state), FFMPEG_SMART_REQUIRE_CACHE='true', TEST_RUN=str(run))
        if not real: env['PATH'] = str(self.bin) + ':' + env['PATH']
        subprocess.run(['bash', '-c', 'source "$1/tests/test-helper.sh"; test_write_valid_cache "$1" "$2"', 'test', str(ROOT), str(state)], env=env, check=True, capture_output=True)
        return run, env

    def execute(self, name, route='/ok', extra=(), **updates):
        run, env = self.setup_run(name)
        env.update(updates)
        result = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', self.url + route, *extra], env=env, capture_output=True, timeout=12)
        return run, result

    def test_all_tiers_exact_replay_one_request_and_auth(self):
        run, env = self.setup_run('replay')
        env['FFMPEG_SMART_SHARED_INPUT_BYTES'] = '65536'
        before = len(self.requests)
        url = self.url.replace('http://', 'http://user:secret@') + '/ok?token=hidden'
        p = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', url, '-user_agent', 'SharedTest'], env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stdout, PACKETS)
        self.assertEqual(len(self.requests) - before, 1)
        self.assertEqual(self.requests[-1][1]['User-Agent'], 'SharedTest')
        self.assertEqual(self.requests[-1][1]['Authorization'], 'Basic dXNlcjpzZWNyZXQ=')
        for tier in range(1, 4): self.assertEqual((run / ('prefix%d' % tier)).read_bytes(), PACKETS[:940])
        self.assertIn(b'probe_requests=3', p.stderr)
        self.assertIn(b'peak_retained_bytes=65536', p.stderr)
        for secret in (b'user:secret', b'hidden', b'token=', b'/ok', b'127.0.0.1'):
            self.assertNotIn(secret, p.stderr)
        self.assertIn('-c:v\ncopy', (run / 'args').read_text())

    def test_rejected_options_and_protocol_do_not_open(self):
        before = len(self.requests)
        _, p = self.execute('options', extra=('-ffmpeg-input-option', '-headers', '-ffmpeg-input-option', 'Authorization: secret'))
        self.assertEqual(p.returncode, 64)
        self.assertNotIn(b'secret', p.stderr)
        run, env = self.setup_run('protocol')
        p = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', 'udp://127.0.0.1:1234'], env=env, capture_output=True)
        self.assertEqual(p.returncode, 64)
        self.assertEqual(len(self.requests), before)

    def test_private_broker_bypasses_inherited_proxies_without_initial_no_proxy(self):
        requests = []
        class RecordingProxy(BaseHTTPRequestHandler):
            def log_message(self, *_args): pass
            def do_GET(self):
                requests.append(self.path)
                self.send_error(502)
            def do_CONNECT(self):
                requests.append(self.path)
                self.send_error(502)
        proxy = ThreadingHTTPServer(('127.0.0.1', 0), RecordingProxy)
        threading.Thread(target=proxy.serve_forever, daemon=True).start()
        try:
            run, env = self.setup_run('proxy-isolation')
            for key in list(env):
                if key.lower() == 'no_proxy': del env[key]
            address = 'http://127.0.0.1:%d' % proxy.server_port
            for key in ('http_proxy', 'HTTP_PROXY', 'https_proxy', 'HTTPS_PROXY', 'all_proxy', 'ALL_PROXY', 'ftp_proxy', 'FTP_PROXY', 'socks_proxy', 'SOCKS_PROXY'):
                env[key] = address
            before = len(self.requests)
            p = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', self.url + '/ok?private=source-token'], env=env, capture_output=True, timeout=12)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(p.stdout, PACKETS)
            self.assertEqual(len(self.requests) - before, 1)
            self.assertEqual(requests, [])
            self.assertIn(b'probe_requests=3', p.stderr)
            self.assertIn(b'upstream_opens=1 upstream_requests=1', p.stderr)
            args = (run / 'args').read_text().splitlines()
            broker_token = args[args.index('-i') + 1].split('/')[-2]
            self.assertNotIn(broker_token.encode(), p.stderr)
            self.assertNotIn(b'source-token', p.stderr)
        finally:
            proxy.shutdown()
            proxy.server_close()

    def test_auto_selection_mixed_urls_and_custom_input(self):
        script = '''source "$1/lib/ffsmart-common.sh"
source "$1/lib/ffsmart-cli.sh"
shift
ffsmart_cli_defaults
ffsmart_parse_cli "$@" || exit
ffsmart_validate_cli || exit
printf '%s' "$FFSMART_SHARED_INPUT"
'''
        cases = [
            ('https://user:secret@example.invalid/live.ts?token=hidden', (), 'true'),
            ('https://example.invalid/live?format=mpegts', (), 'true'),
            ('https://example.invalid/live?output=ts', (), 'true'),
            ('https://example.invalid/live.TS', (), 'true'),
            ('https://example.invalid/live.m3u8?format=ts', (), 'false'),
            ('https://example.invalid/opaque', (), 'false'),
            ('https://example.invalid/live?token=.ts', (), 'false'),
            ('rtsp://example.invalid/live.ts', (), 'false'),
            ('pipe:0', (), 'false'),
            ('https://example.invalid/live.ts', ('-ffmpeg-input-option', '-headers', '-ffmpeg-input-option', 'Authorization: hidden'), 'false'),
        ]
        for url, extra, expected in cases:
            with self.subTest(url=url):
                clean_env = {k: v for k, v in os.environ.items() if k.lower() not in ('http_proxy', 'https_proxy', 'all_proxy', 'ftp_proxy', 'socks_proxy')}
                p = subprocess.run(['bash', '-c', script, 'test', str(ROOT), '--shared-input-auto', '-i', url, *extra], env=clean_env, capture_output=True)
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertEqual(p.stdout.decode(), expected)
                self.assertEqual(p.stderr, b'')
        run, env = self.setup_run('auto-hint')
        for key in list(env):
            if key.lower() in ('http_proxy', 'https_proxy', 'all_proxy', 'ftp_proxy', 'socks_proxy'): del env[key]
        env['FFMPEG_SMART_SHARED_INPUT'] = 'auto'
        p = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '-i', self.url + '/ok.ts'], env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stdout, PACKETS)
        self.assertIn(b'upstream_opens=1 upstream_requests=1', p.stderr)

    def test_auto_keeps_legacy_for_any_ambient_proxy(self):
        script = '''source "$1/lib/ffsmart-common.sh"
source "$1/lib/ffsmart-cli.sh"
shift
ffsmart_cli_defaults
ffsmart_parse_cli "$@" || exit
ffsmart_validate_cli || exit
printf '%s' "$FFSMART_SHARED_INPUT"
'''
        for key in ('http_proxy', 'HTTP_PROXY', 'https_proxy', 'HTTPS_PROXY', 'all_proxy', 'ALL_PROXY', 'ftp_proxy', 'SOCKS_PROXY', 'HtTp_PrOxY'):
            with self.subTest(key=key):
                env = {k: v for k, v in os.environ.items() if not k.lower().endswith('_proxy')}
                env.update({key: 'http://private:credential@proxy.invalid:8888', 'NO_PROXY': '*'})
                p = subprocess.run(['bash', '-c', script, 'test', str(ROOT), '--shared-input-auto', '-i', 'https://source.invalid/live.ts'], env=env, capture_output=True)
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertEqual(p.stdout, b'false')
                self.assertEqual(p.stderr, b'')

    def test_required_cache_and_degraded_policy(self):
        run, env = self.setup_run('missing-cache')
        (run / 'state/.capabilities.cache').unlink()
        before = len(self.requests)
        command = [str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '--copy-codecs', 'preferred', '-i', self.url + '/ok']
        p = subprocess.run(command, env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 78, p.stderr)
        self.assertEqual(len(self.requests), before)
        env['FFMPEG_SMART_CACHE_FALLBACK'] = 'proxy'
        p = subprocess.run(command, env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stdout, PACKETS)
        self.assertEqual(len(self.requests) - before, 1)
        self.assertIn(b'probe_requests=0', p.stderr)
        self.assertIn('-c\ncopy', (run / 'args').read_text())
        (run / 'state/.capabilities.cache').write_text('invalid-cache\n')
        env['FFMPEG_SMART_CACHE_FALLBACK'] = 'none'
        before = len(self.requests)
        p = subprocess.run(command, env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 78, p.stderr)
        self.assertEqual(len(self.requests), before)
        env['FFMPEG_SMART_CACHE_FALLBACK'] = 'proxy'
        p = subprocess.run(command, env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stdout, PACKETS)
        self.assertEqual(len(self.requests) - before, 1)

    def test_early_eof_wrong_format_and_read_failure(self):
        for route in ('early', 'bad', 'truncated'):
            _, p = self.execute(route, '/' + route)
            self.assertEqual(p.returncode, 65, p.stderr)
            self.assertIn(b'upstream_opens=1', p.stderr)

    def test_queue_bound_without_consumer(self):
        r = shared.Reservoir(self.url + '/ok', '', 65536, 2)
        thread = threading.Thread(target=r.read, daemon=True)
        thread.start()
        until = time.monotonic() + 2
        while r.peak < r.cap and time.monotonic() < until: time.sleep(.01)
        self.assertEqual(r.peak, r.cap)
        time.sleep(.1)
        self.assertEqual(r.end - r.start, r.cap)
        r.close()
        thread.join(1)
        self.assertFalse(thread.is_alive())

    def test_short_reads_have_bounded_chunk_overhead(self):
        fixture = PACKETS[:188 * 4]
        class Response:
            status = 200
            def __init__(self): self.length = len(fixture)
            def getheader(self, _name, default=None): return default
            def read1(self, _size):
                index = len(fixture) - self.length
                data = fixture[index:index + 1]
                self.length -= len(data)
                return data
        class Connection:
            sock = None
            def __init__(self, *_args, **_kwargs): pass
            def request(self, *_args, **_kwargs): pass
            def getresponse(self): return Response()
            def close(self): pass
        r = shared.Reservoir(self.url + '/unused', '', 65536, 2)
        with patch.object(shared.http.client, 'HTTPConnection', Connection): r.read()
        self.assertIsNone(r.error)
        self.assertEqual(len(r.chunks), 1)
        self.assertEqual(bytes(r.chunks[0][1]), fixture)
        self.assertEqual(r.peak, len(fixture))

    def test_blocked_output_queue_bound_and_cancellation(self):
        run, env = self.setup_run('blocked-output')
        env['FFMPEG_SMART_SHARED_INPUT_BYTES'] = '65536'
        p = subprocess.Popen([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', self.url + '/large'], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # Deliberately leave stdout unread: kernel pipes fill, then the broker
        # writer blocks and the RAM reader must stop at its configured cap.
        time.sleep(1.5)
        p.send_signal(signal.SIGTERM)
        _, error = p.communicate(timeout=3)
        self.assertEqual(p.returncode, 130, error)
        peak = int(re.search(rb'peak_retained_bytes=(\d+)', error)[1])
        self.assertLessEqual(peak, 65536)
        self.assertGreater(peak, 0)

    def test_redirects_retain_one_media_session_and_strip_auth(self):
        _, p = self.execute('redirect', '/redirect')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stdout, PACKETS)
        self.assertIn(b'upstream_opens=1 upstream_requests=2', p.stderr)
        run, env = self.setup_run('cross-origin')
        url = self.url.replace('http://', 'http://user:secret@') + '/cross'
        p = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', url], env=env, capture_output=True, timeout=12)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertNotIn('Authorization', self.requests[-1][1])
        self.assertEqual(p.stdout, PACKETS)
        before = len(self.requests)
        _, p = self.execute('redirect-limit', '/loop')
        self.assertEqual(p.returncode, 65, p.stderr)
        self.assertEqual(len(self.requests) - before, 6)
        self.assertIn(b'upstream_opens=0 upstream_requests=6', p.stderr)

    def test_startup_deadline_and_cancel_cleanup(self):
        _, p = self.execute('deadline', '/stall', FFMPEG_SMART_SHARED_INPUT_DEADLINE='1', FFMPEG_SMART_SHARED_INPUT_IDLE='2', TEST_PROBE_BYTES='1880')
        self.assertEqual(p.returncode, 65, p.stderr)
        self.assertIn(b'startup-deadline', p.stderr)
        for stage in ('probe', 'playback'):
            run, env = self.setup_run('cancel-' + stage)
            env.update(FFMPEG_SMART_SHARED_INPUT_DEADLINE='10', FFMPEG_SMART_SHARED_INPUT_IDLE='30')
            if stage == 'probe': env['TEST_PROBE_BYTES'] = '1880'
            p = subprocess.Popen([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', self.url + '/stall'], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if stage == 'playback':
                until = time.monotonic() + 2
                while not (run / 'args').exists() and time.monotonic() < until: time.sleep(.01)
                self.assertTrue((run / 'args').exists())
            else:
                time.sleep(.4)
            processes = subprocess.check_output(['ps', '-axo', 'pid=,ppid=,pgid=,stat='], text=True)
            groups = {int(fields[2]) for line in processes.splitlines() if len(fields := line.split()) == 4 and int(fields[1]) == p.pid}
            self.assertTrue(groups)
            cancelled_at = time.monotonic()
            p.send_signal(signal.SIGTERM)
            _, error = p.communicate(timeout=3)
            self.assertLess(time.monotonic() - cancelled_at, 3)
            self.assertEqual(p.returncode, 130, error)
            # No owned worker stays alive while the network/startup guards run.
            processes = subprocess.check_output(['ps', '-axo', 'pid=,ppid=,pgid=,stat='], text=True)
            self.assertFalse(any(int(fields[2]) in groups and not fields[3].startswith('Z')
                                 for line in processes.splitlines() if len(fields := line.split()) == 4))

    def test_concurrent_isolation(self):
        before = len(self.requests)
        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            futures = [pool.submit(self.execute, 'concurrent%d' % n) for n in range(2)]
            for f in futures:
                _, p = f.result()
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertEqual(p.stdout, PACKETS)
        self.assertEqual(len(self.requests) - before, 2)

    def test_real_audio_video_decode(self):
        fixture = self.base / 'real.ts'
        subprocess.run(['ffmpeg', '-v', 'error', '-f', 'lavfi', '-i', 'testsrc2=size=160x120:rate=25', '-f', 'lavfi', '-i', 'sine=sample_rate=48000', '-t', '3', '-c:v', 'libx264', '-preset', 'ultrafast', '-c:a', 'aac', '-f', 'mpegts', str(fixture)], check=True)
        # A separate local fixture handler keeps synthetic byte tests independent.
        data = fixture.read_bytes()
        class Fixture(BaseHTTPRequestHandler):
            requests = 0
            def log_message(self, *_): pass
            def do_GET(self):
                Fixture.requests += 1
                self.send_response(200)
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        server = ThreadingHTTPServer(('127.0.0.1', 0), Fixture)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            run, env = self.setup_run('real', real=True)
            p = subprocess.run([str(ROOT / 'ffmpeg-smart.sh'), '--shared-input', '-i', 'http://127.0.0.1:%d/fixture' % server.server_port], env=env, capture_output=True, timeout=15)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(Fixture.requests, 1)
            output = run / 'output.ts'
            output.write_bytes(p.stdout)
            decoded = subprocess.run(['ffmpeg', '-v', 'error', '-xerror', '-i', str(output), '-map', '0:v', '-map', '0:a', '-f', 'null', '-'], capture_output=True)
            self.assertEqual(decoded.returncode, 0, decoded.stderr)
            info = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'stream=codec_type,codec_name', '-of', 'json', str(output)]))
            self.assertEqual({s['codec_type'] for s in info['streams']}, {'video', 'audio'})
        finally:
            server.shutdown()
            server.server_close()


if __name__ == '__main__': unittest.main(verbosity=2)
