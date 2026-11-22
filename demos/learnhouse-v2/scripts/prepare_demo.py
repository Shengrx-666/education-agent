"""Initialize only learnhouse_v2_demo. Never drop/reset an existing database."""
import asyncio
import hashlib
import os
import sys
from pathlib import Path
from demo_environment import ROOT, environment

async def prepare():
    env = environment()
    os.environ.update(env)
    sys.path.insert(0, str(ROOT/'upstream/learnhouse/apps/api'))
    os.chdir(ROOT/'upstream/learnhouse/apps/api')
    from sqlalchemy.engine import make_url
    from sqlalchemy import create_engine, text
    connection = make_url(env['LEARNHOUSE_SQL_CONNECTION_STRING']).set(drivername='postgresql+psycopg')
    if connection.database != 'learnhouse_v2_demo':
        raise RuntimeError('Only the dedicated learnhouse_v2_demo database is accepted')
    engine = create_engine(connection, hide_parameters=True)
    with engine.connect() as db:
        schemas = db.execute(text("SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema IN ('public','ea')")).all()
        if schemas:
            raise RuntimeError('Database is not empty. Refusing initialization; use local_demo.py start for an existing Demo')
    from fastapi import FastAPI
    from src.core.events.events import startup_app, shutdown_app
    app = FastAPI()
    await startup_app(app)()
    await shutdown_app(app)()
    sql = ROOT/'deliverables/02-design/schema.sql'
    if hashlib.sha256(sql.read_bytes()).hexdigest() != 'fad3fba28d7f7933fc05b87b57cb5a4f9f0dba4bf37f530bbc600531ce3b4616':
        raise RuntimeError('Schema differs from the reviewed baseline')
    import psycopg
    with psycopg.connect(connection.render_as_string(hide_password=False).replace('postgresql+psycopg:', 'postgresql:', 1)) as db:
        db.execute(sql.read_text())
    os.environ['EDUCATION_DEMO_DATABASE_URL'] = connection.render_as_string(hide_password=False)
    from seed_v2_demo import seed
    seed()
    print('已初始化2门课程、2个班级、5个独立账号。密码仅存本机.runtime。')

if __name__ == '__main__':
    asyncio.run(prepare())
