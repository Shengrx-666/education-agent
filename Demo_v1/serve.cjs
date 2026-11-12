const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname, 'index.html'));
const server = http.createServer((req, res) => {
  if (req.url !== '/' && req.url !== '/index.html') { res.writeHead(404); res.end('Not found'); return; }
  res.writeHead(200, {'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'});
  res.end(html);
});
server.on('error', error => { console.error(error.code === 'EADDRINUSE' ? 'Port 5174 is already in use. Close the earlier demo window and retry.' : error.message); process.exitCode = 1; });
server.listen(5174, '127.0.0.1', () => console.log('Open http://127.0.0.1:5174 in your browser. Press Ctrl+C to stop.'));
