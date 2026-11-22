"""Start the local Education Demo without exhausting OS file-watch quotas."""
from pathlib import Path
import os
import shutil

ROOT = Path(__file__).resolve().parents[1]
env = dict(os.environ)
env.update({
    'NODE_TLS_REJECT_UNAUTHORIZED': '1',
    'NO_PROXY': 'localhost,127.0.0.1,::1',
    'no_proxy': 'localhost,127.0.0.1,::1',
    'NEXT_TELEMETRY_DISABLED': '1',
    # Watchpack polling covers both Webpack and Next's route-file watcher.
    # Turbopack does not use this setting, so --webpack below is required.
    'WATCHPACK_POLLING': '1000',
    'EA_DEMO_MODE': '1',
    'NEXT_PUBLIC_POSTHOG_KEY': '',
    'NEXT_PUBLIC_LEARNHOUSE_SENTRY_DSN': '',
    'NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL': 'http://127.0.0.1:8138/',
    'LEARNHOUSE_INTERNAL_API_URL': 'http://127.0.0.1:8138',
    'NEXT_PUBLIC_LEARNHOUSE_DOMAIN': 'localhost:3300',
    'NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG': 'default',
    'LEARNHOUSE_DISABLE_EE': '1',
})
os.chdir(ROOT / 'upstream/learnhouse/apps/web')
node = shutil.which('node')
if not node:
    raise RuntimeError('Node 20.9 or newer is required')
os.execve(node, [node, 'node_modules/next/dist/bin/next', 'dev', '--webpack', '--hostname', 'localhost', '--port', '3300'], env)
