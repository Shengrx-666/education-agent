"""Environment for this task's isolated V2 demo; never emit private values."""
from pathlib import Path
import json
import os
import secrets
from foundation_api import environment as foundation_environment

ROOT=Path(__file__).resolve().parents[1]


def environment():
    (ROOT/'.runtime').mkdir(parents=True, exist_ok=True, mode=0o700)
    connections_path=ROOT/'.runtime/connections.local.json'
    connections=json.loads(connections_path.read_text()) if connections_path.exists() else {}
    private=ROOT/'.runtime/v2-server.local.json'
    if not private.exists():
        fd=os.open(private,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
        with os.fdopen(fd,'w') as f:
            json.dump({'LEARNHOUSE_AUTH_JWT_SECRET_KEY':secrets.token_urlsafe(48),
                       'LEARNHOUSE_INITIAL_ADMIN_PASSWORD':secrets.token_urlsafe(24)},f)
    env=foundation_environment()
    env.update(json.loads(private.read_text()))
    env.update({
        'LEARNHOUSE_SQL_CONNECTION_STRING':os.getenv('EDUCATION_DEMO_DATABASE_URL',connections.get('database_url','postgresql:///learnhouse_v2_demo?host=/tmp/edu-v2-pg-20261120&port=55443')),
        'LEARNHOUSE_INITIAL_ADMIN_EMAIL':'bootstrap-v2@example.com',
        'LEARNHOUSE_INITIAL_ORG_NAME':'教育智能体 · 教学实验室',
        'LEARNHOUSE_REDIS_CONNECTION_STRING':connections.get('redis_url','unix://'+str(ROOT/'.runtime/redis/server.sock')+'?db=2'),
        'LEARNHOUSE_RESEND_API_KEY':'','LEARNHOUSE_SMTP_PASSWORD':'',
        'EA_DEMO_MODE':'1','EA_ORG_SLUG':'default',
        'EA_ALLOWED_ORIGINS':'http://localhost:3300,http://127.0.0.1:3300',
        'NODE_TLS_REJECT_UNAUTHORIZED':'1',
    })
    return env
