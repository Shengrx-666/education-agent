"""Ask locally for database/Redis URLs. Values never appear in shell arguments."""
import getpass
from local_demo import RUNTIME, private_json

if __name__ == '__main__':
    db = getpass.getpass('专用空库连接串（postgresql://.../learnhouse_v2_demo）: ')
    redis = getpass.getpass('专用 Redis 连接串（redis://.../2）: ')
    if not db.startswith(('postgresql://', 'postgresql+psycopg://')) or not redis.startswith(('redis://', 'rediss://', 'unix://')):
        raise ValueError('Unsupported connection scheme')
    private_json(RUNTIME/'connections.local.json', {'database_url': db, 'redis_url': redis})
    print('私有配置已保存；请运行 prepare_demo.py 初始化专用空库。')
