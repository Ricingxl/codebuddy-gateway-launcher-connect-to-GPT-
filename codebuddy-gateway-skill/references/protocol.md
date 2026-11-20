# 已验证的 Gateway REST/SSE 协议

以下消息结构在 CLI 2.168.0/2.168.2 验证过，后续版本先查本机 `/api/openapi.json`。请求均带两个认证头，Content-Type 为 application/json。

POST `/api/v1/runs` 示例（占位符在调用时替换）：

```json
{
  "id": "<new-message-uuid>",
  "type": "message",
  "text": "<用户授权的任务>",
  "source": {
    "platform": "generic",
    "sender": {"id": "assistant-codebuddy-client", "name": "Assistant"},
    "conversation": {"id": "<stable-conversation-uuid>", "type": "direct"}
  }
}
```

返回通常为 `{"data":{"runId":"...","status":"accepted"}}`。

立即 GET `/api/v1/runs/{runId}/stream`。SSE 可包含：

```text
event: message
data: {"replyTo":"...","status":"completed","content":{"markdown":"..."},"agent":{"sessionId":"..."}}

event: done
data: {}
```

SSE 应按空行分事件，并合并事件内多行 data 后解析 JSON；保留 UTF-8 跨块字符。不要用单次网络块当作完整 JSON。输出可能包含阶段性消息，只有终态确认后才报告任务完成。

GET `/api/v1/runs/{runId}` 可以检查 active 状态，但 `active:false` 本身不能证明成功，也不一定包含回复。stream 404 或连接断开时如实说明无法取得完整结果，不重复执行写文件、发送消息等有副作用的任务。

诊断：401 通常为密码错误/缺失，403 可能缺少安全头或 Origin 被拒绝，404 可能版本或路径不匹配，502 可能转发器已启动而后台尚未就绪。瞬时连接故障可以有限重试只读检查；POST 超时不要自动重发。

模型目录：GET `/internal/agent/models`，返回 `models` 数组，常见字段为 id、name、description 以及 `_meta["codebuddy.ai"].credits`。只提取需要展示的字段，不输出可能包含凭据的整份原始目录。内部接口没有稳定兼容承诺。

若需要请求取消，先检查当前 OpenAPI 对 `/api/v1/runs/{runId}/cancel` 的方法和结构；不能仅凭本参考猜测。会话 history/replay 在某些版本可能只含提问，不能作为完整回复的保证。
