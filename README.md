# CodeBuddy Gateway Launcher for Windows

Windows 上的 CodeBuddy CLI 双击启动器：安装、登录、模型选择、密码管理和本机 REST 对话显示。

本项目是独立的第三方辅助工具，与腾讯或 CodeBuddy 官方无隶属关系。仓库仅包含启动器源码，不包含 CodeBuddy CLI、账号凭据或聊天记录。启动器代码采用 [MIT License](LICENSE)，CodeBuddy 及其他依赖遵循各自条款。

## 环境

- Windows 10/11，Windows PowerShell 5.1，.NET Framework 的 Add-Type 功能可用。
- Node.js 当前受支持的 LTS 版本，包含 npm；对话转发使用 Node.js 内置模块，无额外 npm 依赖。
- 安装和账号认证需要网络。CLI 曾在 2.168.0/2.168.2 环境下验证，其他版本需自行验收。

## 快速开始

1. 下载并完整解压本仓库。不要在 ZIP 内直接运行。
2. 双击 `Start-Gateway.cmd`，按菜单操作。
3. 首次使用选 3 安装/更新官方 CLI 最新版，亲自在浏览器完成登录，输入 `/exit` 返回菜单。
4. 选 1，等待读取模型目录，再输入模型编号。直接回车默认 `deepseek-v4.1-flash`。
5. 保持启动窗口打开；关闭窗口会结束 Gateway、转发器及其所属子进程。进行中的任务可能被中断。

| 菜单 | 功能 |
|---|---|
| 1 / 回车 | 选择模型并启动 Gateway |
| 2 | 修改 Gateway 密码 |
| 3 | 安装/更新官方 CLI 最新版，然后进入登录 |
| 4 | 登录已有 CLI |
| 5 | 退出当前 CLI 账号 |
| 0 | 退出启动器，不等于退出账号 |

账号登录需用户完成；程序无法仅凭 CLI 退出码确认认证成功。未安装 Node.js/npm 时，菜单会显示下载指引，不自动安装 Node.js。

## API 与对话显示

对外地址默认为 `http://127.0.0.1:8080`。真实 Gateway 在随机本机端口运行，Node.js 转发器监听 8080。CLI 打印的 Endpoint 是内部端口；调用方应使用上述对外入口。

API 请求携带 `x-codebuddy-request: 1` 和 `X-Access-Token: 当前Gateway密码`。密码由 CLI 管理，默认存于当前用户配置目录，启动时会打印。双击 `Test-Gateway.cmd`，隐藏输入密码即可测试 health/info。health 在部分版本免认证，认证验收应同时检查 info，错误密码应被拒绝。

通过本入口 POST `/api/v1/runs` 的文本提问，以及调用方 GET `/api/v1/runs/{runId}/stream` 时收到的文本回复，会显示在同一窗口。转发器不另外写日志，但终端保留滚动内容，CLI 自身可能保存历史。并发请求可能交错显示。

不显示绕过入口的调用、独立 CLI、ACP 或其他 API 的对话。未读取 stream 的调用无法在窗口显示回复。不保证 WebSocket 客户端兼容。大于 1 MiB 的提问略过显示但继续转发；超大或非标准 SSE 事件可能无法显示。

## 模型与价格

每次启动临时创建辅助 Gateway，读取 `/internal/agent/models` 后关闭辅助服务，按服务器顺序显示编号、名称、ID 和 credits 倍率。临时服务输出被隐藏。

目录反映当前 Gateway 加载的信息，不保证云端即时刷新。积分倍率不是人民币价格或折扣；当前接口未提供单独优惠字段时显示“未提供”，不能据此判断免费或促销。最终计费以官方和账号账单为准。编号可能随目录变化。

该目录接口与账号退出接口是版本相关实现，未来可能变化；读取失败时仍可选择默认模型或手动输入 ID。模型目录不代表账号拥有全部模型权限。

## 密码与账号

修改密码前先停止所有 Gateway。菜单 2 或 `Reset-GatewayPassword.cmd` 要求确认并两次隐藏输入新密码，至少 16 字符且无空白。程序先在配置目录备份原 settings.json，再更新 gateway.password/auth；JSON 会重新排版，写入并非原子操作，意外中断可从备份恢复。备份含旧凭据，不要上传。

手工修改：停服务、备份后，编辑启动窗口 Config 指向的 settings.json 中 gateway.password，保持 auth 为 password。将 password 设为空字符串会让 CLI 在下次启动生成密码。不要删除其他设置。修改后重启、重新登录浏览器并更新调用方令牌。

菜单 5 临时启动辅助 Gateway，调用 `/api/v1/auth/account/logout`，需输入 YES 确认。它不修改 Gateway 密码、不删除历史。环境变量/API Key 等外部凭据需在其来源单独移除。其他进程可能缓存账号状态，应先停止。接口失败可在 CLI 交互界面手工输入 `/logout`。

## 高级启动

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-Gateway.ps1 -Port 8081 -ProjectPath "D:\Projects\Example" -Model deepseek-v4.1-flash
```

`-Model` 跳过菜单；`-NoConversationDisplay` 关闭转发和对话显示，真实 Gateway 直接监听指定端口。默认工作目录是脚本目录，处理项目时请显式指定 ProjectPath。

进程级 ExecutionPolicy Bypass 不修改系统策略，企业策略仍可能阻止脚本。启动器使用 KILL_ON_JOB_CLOSE，并在恢复子进程前将其纳入作业；作业初始化失败时不启动未受管理的服务。已占用端口会报错，不会杀死其他进程。只监听本机，不提供远程访问功能。

## 验证与限制

见 [VALIDATION.md](VALIDATION.md)。安装、退出账号等流程使用模拟验证，不能视为覆盖所有账号与 Windows 环境。核心转发和模型问答已使用真实 Gateway 验证。

安装教程：[CodeBuddy CLI 安装与登录](CodeBuddy-CLI安装与登录教程.md)。发布步骤：[PUBLISH.md](PUBLISH.md)。

## 配套 Agent Skill

本项目提供 `codebuddy-gateway` skill，指导支持技能的 AI 助手通过本机 Gateway 调用 CodeBuddy，完成多轮对话、代码生成和代码任务委托。

### 安装到 Codex

将仓库中的 `skills/codebuddy-gateway` 文件夹复制到：

```text
%USERPROFILE%\.codex\skills\codebuddy-gateway
```

重新打开聊天以加载技能，启动 Gateway 后，可以这样使用：

```text
使用 $codebuddy-gateway，让 CodeBuddy 编写并验证一个 Hello World 程序。
```

Skill 本身不提供模型服务。实际调用仍需安装 CodeBuddy CLI、完成账号登录并启动 Gateway；模型权限和费用由 CodeBuddy 账号决定。
## 官方参考

- https://www.codebuddy.cn/docs/cli/quickstart
- https://www.codebuddy.cn/docs/cli/http-api
- https://www.codebuddy.cn/docs/cli/settings
- https://www.codebuddy.cn/docs/cli/slash-commands
