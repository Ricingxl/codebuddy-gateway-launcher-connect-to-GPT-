'use strict';
// Local HTTP/SSE relay. No dependencies, token storage, or log files.
const http = require('http');
const {StringDecoder} = require('string_decoder');
const [port, backend] = process.argv.slice(2).map(Number);
if (![port, backend].every(p => Number.isInteger(p) && p > 0 && p < 65536) || port === backend) process.exit(2);
const clean = text => String(text).replace(/[\x00-\x08\x0b-\x1f\x7f]/g, '');
const log = (role, text) => { if (text) process.stdout.write('\n[' + role + '] ' + clean(text) + '\n'); };
const server = http.createServer((req, res) => {
  let captured = [], bytes = 0, truncated = false;
  const runRequest = req.method === 'POST' && /^\/api\/v1\/runs\/?(?:\?|$)/.test(req.url);
  const streamRequest = req.method === 'GET' && /^\/api\/v1\/runs\/[^/]+\/stream(?:\?|$)/.test(req.url);
  const upstream = http.request({hostname:'127.0.0.1', port:backend, path:req.url, method:req.method,
    headers:{...req.headers, host:'127.0.0.1:' + backend}}, reply => {
    res.writeHead(reply.statusCode, reply.headers);
    if (runRequest && reply.statusCode >= 400) log('调用失败', 'HTTP ' + reply.statusCode);
    if (streamRequest && reply.statusCode === 200) {
      const decoder = new StringDecoder('utf8');
      let pending = '';
      reply.on('data', chunk => {
        pending += decoder.write(chunk);
        let index;
        while ((index = pending.indexOf('\n')) >= 0) {
          const line = pending.slice(0,index).replace(/\r$/, ''); pending = pending.slice(index+1);
          if (!line.startsWith('data:')) continue;
          try {
            const event = JSON.parse(line.slice(5));
            const text = event.content && (event.content.markdown || event.content.text);
            if (text) log('模型回复 ' + (event.replyTo || '').slice(0,8), text);
            if (event.error) log('模型错误', typeof event.error === 'string' ? event.error : event.error.message || '执行失败');
          } catch (_) { /* Non-JSON events are forwarded unchanged. */ }
        }
        if (pending.length > 1024*1024) pending = '';
      });
    }
    reply.pipe(res);
    reply.on('error', () => res.destroy());
  });
  upstream.on('error', () => { if (!res.headersSent) res.writeHead(502, {'Content-Type':'text/plain; charset=utf-8'}); res.end('Gateway 尚未就绪或已停止，请稍后重试。'); });
  if (runRequest) {
    req.on('data', chunk => {
      bytes += chunk.length;
      if (bytes <= 1024*1024) captured.push(chunk); else { captured=[]; truncated=true; }
    });
    req.on('end', () => {
      if (truncated) return log('提问', '请求超过 1 MiB，略过显示；请求仍正常转发。');
      try {
        const data = JSON.parse(Buffer.concat(captured).toString('utf8'));
        log('提问 ' + String(data.id || '').slice(0,8), data.text || (data.content && data.content.text) || '非文本请求');
      } catch (_) { }
    });
  }
  req.pipe(upstream);
  req.on('aborted', () => upstream.destroy());
  res.on('close', () => { if (!res.writableEnded) upstream.destroy(); });
});
server.on('error', error => { console.error('[转发启动失败] ' + error.code); process.exit(1); });
server.listen(port, '127.0.0.1', () => log('对话显示已开启', 'http://127.0.0.1:' + port + '（通过此入口调用 /api/v1/runs 并读取 /stream 才会显示完整回复）'));
