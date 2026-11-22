"""Local-only upstream startup probe. No model provider or email credentials.

Runtime credentials are generated once into a mode-0600 ignored file. This is
not an application login flow or a production deployment script.
"""
from pathlib import Path
import json
import os
import secrets

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / '.runtime'
CONFIG = RUNTIME / 'foundation.local.json'
API = ROOT / 'upstream' / 'learnhouse' / 'apps' / 'api'


def environment():
    if not CONFIG.exists():
        values = {
            'LEARNHOUSE_AUTH_JWT_SECRET_KEY': secrets.token_urlsafe(48),
            'LEARNHOUSE_INITIAL_ADMIN_PASSWORD': secrets.token_urlsafe(24),
        }
        fd = os.open(CONFIG, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w') as f:
            json.dump(values, f)
    values = json.loads(CONFIG.read_text())
    env = dict(os.environ)
    env.update(values)
    env.update({
        'LEARNHOUSE_SQL_CONNECTION_STRING': 'postgresql:///learnhouse_v2_foundation?host=/tmp/edu-v2-pg-20261120&port=55443',
        'LEARNHOUSE_REDIS_CONNECTION_STRING': 'unix://' + str(RUNTIME / 'redis' / 'server.sock') + '?db=0',
        'LEARNHOUSE_INITIAL_ADMIN_EMAIL': 'foundation-probe@example.com',
        'LEARNHOUSE_INITIAL_ORG_NAME': 'Education Foundation Probe',
        'LEARNHOUSE_INITIAL_ORG_SLUG': 'default',
        'LEARNHOUSE_IS_AI_ENABLED': 'false',
        'LEARNHOUSE_AI_API_KEY': '',
        'LEARNHOUSE_GEMINI_API_KEY': '',
        'LEARNHOUSE_SENTRY_DSN': '',
        'LEARNHOUSE_SELF_HOSTED': 'true',
        'LEARNHOUSE_DEVELOPMENT_MODE': 'true',
        'LEARNHOUSE_TENANCY': 'single',
        'LEARNHOUSE_DOMAIN': 'localhost:3300',
        'LEARNHOUSE_FRONTEND_DOMAIN': 'localhost:3300',
        'LEARNHOUSE_SSL': 'false',
        'LEARNHOUSE_PORT': '8138',
        'LEARNHOUSE_COOKIE_DOMAIN': 'localhost',
        'LEARNHOUSE_ALLOWED_ORIGINS': '["http://localhost:3300","http://127.0.0.1:3300"]',
        'LEARNHOUSE_ALLOWED_REGEXP': '^http://(localhost|127\\.0\\.0\\.1):3300$',
        'LEARNHOUSE_DISABLE_EE': '1',
        'LEARNHOUSE_MCP_ENABLED': 'false',
    })
    return env


if __name__ == '__main__':
    env = environment()
    os.chdir(API)
    python = RUNTIME / 'api-venv' / 'bin' / 'python'
    os.execve(str(python), [str(python), '-m', 'uvicorn', 'app:app', '--host', '127.0.0.1', '--port', '8138'], env)
