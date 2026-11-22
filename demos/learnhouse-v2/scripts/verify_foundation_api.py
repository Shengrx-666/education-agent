"""Probe only this task's isolated upstream instance; never print credentials."""
from pathlib import Path
import json
import http.cookiejar
import urllib.request
import urllib.parse
import urllib.error

ROOT = Path(__file__).resolve().parents[1]
BASE = 'http://127.0.0.1:8138/api/v1'
jar = http.cookiejar.CookieJar()
client = urllib.request.build_opener(urllib.request.ProxyHandler({}), urllib.request.HTTPCookieProcessor(jar))
checks = []


def request(path, data=None, origin=None, method=None):
    headers = {'Origin': origin} if origin else {}
    if data is not None:
        data = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        response = client.open(req, timeout=15)
        return response.status, response.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def check(name, ok, observed):
    checks.append({'name': name, 'passed': bool(ok), 'observed': observed})


code, body = request('/health')
check('upstream PostgreSQL health', code == 200 and json.loads(body) is True, code)
code, _ = request('/auth/me')
check('anonymous identity rejected', code == 401, code)
private = json.loads((ROOT / '.runtime/foundation.local.json').read_text())
code, _ = request('/auth/login', {
    'username': 'foundation-probe@example.com',
    'password': private['LEARNHOUSE_INITIAL_ADMIN_PASSWORD'], 'org_slug': 'default',
}, 'http://localhost:3300')
check('generated local account can login', code == 200, code)
check('access cookie is HttpOnly', any(c.name == 'LH_access' and c.has_nonstandard_attr('HttpOnly') for c in jar),
      {'cookie_names': [c.name for c in jar]})
code, body = request('/auth/me')
check('cookie session can read own identity', code == 200, code)
code, _ = request('/auth/logout', None, 'https://untrusted.invalid', method='DELETE')
check('foreign origin mutation rejected', code == 403, code)
code, _ = request('/auth/logout', None, 'http://localhost:3300', method='DELETE')
check('valid origin logout succeeds', code in (200, 204), code)
code, _ = request('/auth/me')
check('logged-out client has no session', code == 401, code)
result = {'scope': 'Isolated upstream bootstrap admin; not V2 role/object authorization validation',
          'total': len(checks), 'passed': sum(c['passed'] for c in checks), 'checks': checks}
(ROOT / 'deliverables/01-foundation/api-smoke-results.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
print(json.dumps(result, ensure_ascii=False, indent=2))
if result['passed'] != result['total']:
    raise RuntimeError('Foundation check failed; inspect sanitized report')
