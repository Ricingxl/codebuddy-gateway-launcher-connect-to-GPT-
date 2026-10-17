# Windows 安装、登录 CodeBuddy CLI 与获取 Gateway 密码

退出账号：先关闭所有 Gateway/CLI 会话，重新打开启动器选 `5`，输入 YES 确认。成功后可选 `4` 登录其他账号。`0` 只退出程序。手工操作可运行 `codebuddy.cmd`，在交互界面输入 `/logout`。退出账号不等于修改 Gateway 密码，也不删除历史；外部 API Key 需另外处理。

现在可使用安装向导：安装好 Node.js LTS 后，双击启动器，选 `3` 自动安装/更新 CLI 最新版并进入登录。用户在浏览器完成登录后，在 CLI 输入 `/exit` 回到菜单，选 `1` 再选模型启动。已安装且仅需登录时选 `4`，不更新版本。

默认在同一窗口显示经本包入口发起的 REST 对话。调用方使用 http://127.0.0.1:8080 POST `/api/v1/runs` 并读取对应 `/stream`，即可显示提问和模型回复。CLI 打印的随机端口为内部端口，绕过对外入口的请求不会显示。其他独立 CLI 或 ACP 对话不在此显示范围内。更多限制见 README 新版说明。

新版主菜单先显示：`1` 选择模型并启动（回车默认），`2` 修改 Gateway 密码，`0` 退出。改密前先停止所有服务；选择 `2` 后输入 YES 确认，再隐藏输入两次新密码，至少 16 字符且不含空白。也可双击 `Reset-GatewayPassword.cmd` 单独操作。修改后重新启动，使用新密码测试。配置备份含敏感信息，请勿分享。

菜单每行显示两位序号、模型名称、模型 ID、服务器积分倍率和优惠信息状态。输入 `6` 或 `06` 均可选择第 6 项；编号随目录变化，以本次菜单为准。当前接口只提供积分倍率，没有单独的优惠价格，因此显示“优惠信息：未提供”，不把积分倍率当作人民币价格或折扣。

新增模型选择菜单：双击启动后等待获取目录，输入编号选择；直接回车使用 DeepSeek V4.1 Flash，M 手动输入 ID，Q 退出。目录由临时本机 Gateway 提供，约 40 秒仍未获取时进入备用菜单。目录反映当前加载信息，不保证云端即时刷新或所有模型均有调用权限。具体机制见 `README.md`。完成选择后才会显示主服务 Password。

本启动包默认使用 DeepSeek V4.1 Flash（`deepseek-v4.1-flash`），2026-10-17 更新。更换启动包后先关闭旧服务，再双击启动，新会话才会应用该默认模型；既有会话或客户端选择可能覆盖默认值。

适用：Windows 10/11。本文对应此前已成功使用的 CodeBuddy CLI 2.168.0，以及本仓库提供的双击启动包。

## 一、已安装且登录成功的电脑：直接获取密码

1. 将 `CodeBuddy-Gateway-Windows.zip` 完整解压，所有文件保持在同一目录。
2. 双击 `Start-Gateway.cmd`。
3. 等待启动完成，在**启动命令窗口**找到类似以下内容：

```text
Endpoint    http://127.0.0.1:8080
Web UI      http://127.0.0.1:8080/?password=<当前密码>
Password    <当前密码>
Config      C:\Users\你的用户名\.codebuddy\settings.json
```

`Password` 后面的整段内容就是 Gateway 密码。这里的 `<当前密码>` 只是示意，不是可以使用的密码。

在 Windows 命令窗口中，用鼠标选中 Password 后的密码，按 Enter 或使用右键菜单复制。不要复制 `Password` 这个标签、两边空格或整条 Web UI 链接。若选中文字后服务暂时不响应，按 Esc 退出选择状态。

保持启动窗口打开，再双击 `Test-Gateway.cmd`，在提示处粘贴密码并按 Enter。输入不会显示字符或星号，这是正常现象。测试会携带 `x-codebuddy-request: 1` 与 `X-Access-Token`，分别请求 health 和 info。

密码首次生成后通常保存并复用，不是每次启动都变化。始终以当前启动窗口显示的密码为准。如果窗口没有启动成功或没有显示 Password，先处理窗口中的错误；不要反复猜测密码。

**如果密码曾经泄露，需要更换，不应继续使用。** 更换步骤见第六节。

## 二、首次安装 Node.js

已经能运行 `codebuddy --version` 的电脑通常无需重装，可直接跳到第四节。

1. 打开 [Node.js 官网](https://nodejs.org/)。
2. 下载适合 Windows 的当前受支持 LTS 安装包。
3. 安装时保留默认选项，确保添加到 PATH。
4. 安装完成后，关闭已有 PowerShell，再从开始菜单重新打开 Windows PowerShell。
5. 逐行执行：

```powershell
node --version
npm.cmd --version
```

两条命令都显示版本号即可。CLI 官方最低要求 Node.js 18.20；新安装建议使用仍受维护的 LTS 版本。

若提示“无法识别”，先重开终端；仍失败时，检查 Node.js 是否安装成功以及 PATH 选项是否启用。普通用户权限即可，不必默认以管理员身份运行。

## 三、安装 CodeBuddy CLI

为了复现此前成功环境，在 Windows PowerShell 执行：

```powershell
npm.cmd install -g @tencent-ai/codebuddy-code@2.168.0
codebuddy.cmd --version
```

第二条应显示 2.168.0。安装过程需要网络访问 npm 软件包源。

如果希望安装当前最新版本，可改为：

```powershell
npm.cmd install -g @tencent-ai/codebuddy-code@latest
codebuddy.cmd --version
```

选择一种安装方式执行即可。最新版本可能改变 Gateway 的行为，升级后应重新验证接口认证与关闭窗口后的停止行为。

这里显式使用 `.cmd`，可避免 npm 生成的同名 `.ps1` 文件因 PowerShell 执行策略而被拦截。

## 四、首次登录 CodeBuddy 账号

1. 在 PowerShell 中执行：

```powershell
codebuddy.cmd
```

2. 首次运行若显示登录方式列表，使用方向键选择并按 Enter：
   - 国内站：使用国内站账号。
   - 国际站：使用国际站账号。
   - 企业域名：按公司提供的信息填写服务地址。
   - iOA：仅适用于符合条件的腾讯内部用户。
3. 按终端提示在浏览器完成登录和授权；只在你信任的官方或公司指定页面操作。
4. 回到 PowerShell，确认认证成功并进入 CodeBuddy 交互界面。
5. 按界面提示退出交互会话，再启动 Gateway。如果界面没有明确退出入口，可用 Ctrl+C 退出；必要时再次按下。

如果已经有有效登录状态，运行后可能直接进入交互界面，无需重新登录。若浏览器没有自动打开，按 CLI 显示的地址和说明完成认证。

**账号登录凭据与 Gateway 密码用途不同：**账号登录让 CLI 使用你的模型服务；Gateway 密码保护本机 HTTP 接口。不要把账号密码或模型 API Key 填进本包的 Gateway 测试提示。

## 五、启动 Gateway 并检查

### 推荐：双击启动

1. 完整解压启动包。
2. 双击 `Start-Gateway.cmd`。
3. 等待 Endpoint 和 Password 出现。
4. 按第一节复制密码，双击 `Test-Gateway.cmd` 验证。
5. 使用结束后关闭启动命令窗口。最小化不会停止；关闭浏览器或测试窗口也不会停止。

网页入口是 http://127.0.0.1:8080 。可以输入启动窗口显示的密码登录。若使用窗口打印的带密码链接，请勿分享链接或截图。

### 手动启动（用于排查）

在 PowerShell 执行：

```powershell
codebuddy.cmd --serve --host 127.0.0.1 --port 8080 --auth password --model deepseek-v4.1-flash
```

先确认环境变量 `CODEBUDDY_GATEWAY_AUTH` 没有被设置为 `none`；该环境变量优先级高于命令参数。本包的双击启动器会为自己的子进程强制设置为 password。

手动启动的停止方式为 Ctrl+C；本包提供的进程树清理机制仅适用于通过 `Start-Gateway.cmd` 启动的服务。

### 如何判断验证成功

测试窗口中 health 和 info 都应显示 PASS 以及 JSON。health 在部分版本中属于免认证路径，因此不能只凭它判断密码正确。可再次执行测试并故意输入错误密码，确认 info 返回 401；随后重新使用正确密码。

## 六、更换 Gateway 密码

1. 先关闭所有 Gateway 启动窗口，停止服务。
2. 找到此前启动窗口 `Config` 一行对应的配置文件。默认路径通常是：

```text
%USERPROFILE%\.codebuddy\settings.json
```

可把这条路径输入资源管理器地址栏。如果设置过 `CODEBUDDY_CONFIG_DIR`，应以启动窗口的实际 Config 路径为准。

3. 在本地备份配置文件，备份不要上传或分享。
4. 用记事本等编辑器打开文件，在已有 `gateway` 对象中，只把 `password` 的值改为 `""`，或删除该属性。保留其他设置，注意 JSON 逗号格式。确保认证模式为 password。
5. 保存，再双击 `Start-Gateway.cmd`。
6. 查看新打印的 Password，确认与旧密码不同。用新密码测试 info 成功，再用旧密码测试 info 应返回 401。
7. 更新调用方保存的令牌，并在浏览器重新登录。不要把旧密码写进教程、脚本或命令历史。

如果新密码没有生成，先检查是否修改了错误的配置目录，或是否有旧实例仍在运行。

## 七、常见问题

| 现象 | 处理方式 |
|---|---|
| 找不到 codebuddy.cmd | 重开 PowerShell，运行 `Get-Command codebuddy.cmd`；检查安装输出及 npm 全局目录是否在 PATH 中。 |
| npm 安装失败 | 查看安装错误，确认 Node.js、网络和软件包源可用；不要因为失败就直接关闭系统安全策略。 |
| 运行的版本不是刚安装的版本 | 用 `Get-Command codebuddy*` 检查是否存在多个安装路径。 |
| 密码输入时看不见内容 | 属于隐藏输入的正常行为；粘贴后按 Enter。 |
| AUTH_REQUIRED / 401 | 使用当前启动窗口的 Gateway 密码，确认测试连接的端口正确。 |
| Missing required header | 请求缺少 `x-codebuddy-request: 1`；使用包内测试脚本会自动携带。 |
| 8080 被占用 | 先关闭原有 Gateway 窗口；不要直接终止未知进程。也可按启动包说明使用其他端口。 |
| 启动后马上报错 | 阅读启动窗口中的错误；安装、登录成功不代表端口或配置一定正确。 |
| 关闭浏览器后服务还在 | 浏览器与服务独立，需关闭启动命令窗口。 |

## 官方资料

- [快速入门：安装要求、安装命令与登录方式](https://www.codebuddy.cn/docs/cli/quickstart)
- [HTTP API：认证与请求头](https://www.codebuddy.cn/docs/cli/http-api)
- [配置说明：Gateway 密码](https://www.codebuddy.cn/docs/cli/settings)

本教程依据本次会话核对过的官方文档及此前 2.168.0 成功记录整理。新电脑安装与真实账号登录仍需在使用时完成。
