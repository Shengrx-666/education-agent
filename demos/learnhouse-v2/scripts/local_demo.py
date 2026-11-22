"""Local Demo lifecycle. No credentials leave .runtime; never kill unowned PIDs."""
from pathlib import Path
import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / '.runtime'
STATE = RUNTIME / 'demo-processes.local.json'


def private_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, 'w') as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)


def probe(url):
    try:
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        with opener.open(url, timeout=3) as response:
            return response.status == 200
    except Exception:
        return False


def identity(pid):
    try:
        return Path('/proc') .joinpath(str(pid), 'stat').read_text().split(') ', 1)[1].split()[19]
    except (OSError, IndexError):
        return None


def checks():
    result = {'API Python': (RUNTIME/'api-venv/bin/python').exists(),
              'Node': bool(shutil.which('node')),
              'Next dependencies': (ROOT/'upstream/learnhouse/apps/web/node_modules/next/dist/bin/next').exists(),
              'Database configuration': (RUNTIME/'connections.local.json').exists() or (RUNTIME/'pgdata/PG_VERSION').exists(),
              'Demo accounts initialized': (RUNTIME/'demo-accounts.local.json').exists()}
    for name, ok in result.items():
        print(('OK   ' if ok else 'MISS ') + name)
    return all(result.values())


def private_services():
    """Start only the optional private runtime installed in this workspace."""
    pg = RUNTIME/'sysroot/usr/lib/postgresql/14/bin/pg_ctl'
    if pg.exists() and (RUNTIME/'pgdata/PG_VERSION').exists():
        socket_dir = Path('/tmp/edu-v2-pg-20261120')
        socket_dir.mkdir(exist_ok=True, mode=0o700)
        status = subprocess.run([str(pg), '-D', str(RUNTIME/'pgdata'), 'status'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if status.returncode:
            subprocess.run([str(pg), '-D', str(RUNTIME/'pgdata'), '-l', str(RUNTIME/'postgres.log'), '-w', 'start'], check=True, stdout=subprocess.DEVNULL)
    redis = RUNTIME/'sysroot/usr/bin/redis-server'
    redis_socket = RUNTIME/'redis/server.sock'
    if redis.exists() and not redis_socket.exists():
        redis_socket.parent.mkdir(exist_ok=True, mode=0o700)
        env = dict(os.environ, LD_LIBRARY_PATH=str(RUNTIME/'sysroot/usr/lib/x86_64-linux-gnu'))
        subprocess.run([str(redis), '--port', '0', '--unixsocket', str(redis_socket), '--unixsocketperm', '700',
                        '--daemonize', 'yes', '--pidfile', str(RUNTIME/'redis/redis.pid'), '--dir', str(RUNTIME/'redis'),
                        '--logfile', str(RUNTIME/'redis/redis.log')], env=env, check=True)


def start():
    if not checks():
        print('请先完成本地运行说明中的环境准备与初始化。')
        return 1
    private_services()
    current = json.loads(STATE.read_text()) if STATE.exists() else {}
    services = [('api', 'http://127.0.0.1:8138/api/v1/health', 'run_v2_api.py'),
                ('web', 'http://localhost:3300/education/login', 'foundation_web.py')]
    for name, url, script in services:
        if probe(url):
            print(name + ': already available (existing process retained)')
            continue
        entry = current.get(name, {})
        if entry.get('start') is not None and identity(entry['pid']) == entry['start']:
            print(name + ': process is still running but the health check failed; inspect the private log, then run stop and start.')
            return 1
        with open(RUNTIME/('demo-'+name+'.log'), 'ab', buffering=0) as log:
            proc = subprocess.Popen([sys.executable, str(ROOT/'scripts'/script)], cwd=ROOT, stdout=log,
                                    stderr=subprocess.STDOUT, start_new_session=True)
        current[name] = {'pid': proc.pid, 'start': identity(proc.pid)}
        private_json(STATE, current)
        deadline = time.monotonic() + 150
        while time.monotonic() < deadline:
            if probe(url):
                print(name + ': ready')
                break
            if proc.poll() is not None:
                print(name + ': startup failed; inspect .runtime/demo-'+name+'.log locally')
                return 1
            time.sleep(1)
        else:
            print(name + ': startup timed out; inspect the private log')
            return 1
    print('打开 http://localhost:3300/education/login')
    print('账号与随机密码位于 .runtime/demo-accounts.local.json；请在本机打开，不要上传。')
    return 0


def stop():
    current = json.loads(STATE.read_text()) if STATE.exists() else {}
    for name, entry in current.items():
        pid = entry['pid']
        if entry.get('start') is not None and identity(pid) == entry['start']:
            os.killpg(pid, signal.SIGTERM)
            print(name + ': stop requested')
        else:
            print(name + ': not running or no longer owned')
    private_json(STATE, {})
    print('数据库和Redis保留；不会删除数据或停止其他应用服务。')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['doctor', 'start', 'stop', 'status', 'accounts'])
    args = parser.parse_args()
    if args.command == 'doctor':
        return 0 if checks() else 1
    if args.command == 'start':
        return start()
    if args.command == 'stop':
        stop()
    elif args.command == 'status':
        print('API:', probe('http://127.0.0.1:8138/api/v1/health'))
        print('Web:', probe('http://localhost:3300/education/login'))
    elif args.command == 'accounts':
        file = RUNTIME/'demo-accounts.local.json'
        print(str(file))
        if file.exists():
            for account in json.loads(file.read_text())['accounts']:
                print(account['label'] + ': ' + account['email'])
            print('密码请在本机打开上述私有文件查看；不会输出到日志。')
        else:
            print('尚未初始化。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
