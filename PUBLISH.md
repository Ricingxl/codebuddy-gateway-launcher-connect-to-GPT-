# 发布到 GitHub

## 网页上传（无需安装 Git）

1. 解压源码包，确认 README.md、LICENSE 和 Start-Gateway.cmd 直接位于源码目录内。
2. 登录 GitHub，打开 https://github.com/new 。
3. 仓库名建议 `codebuddy-gateway-launcher`，说明可写“Windows 上的 CodeBuddy CLI 双击启动与模型选择工具”。选择 Public。
4. 创建时不额外生成 README、.gitignore 或 License，因为本包已包含这些文件。
5. 创建仓库后，点 `uploading an existing file`；已有文件的仓库可用 `Add file` → `Upload files`。
6. 打开解压后的源码目录，选择其中全部文件（包含 .gitignore 和 .gitattributes），拖入上传区域。不要只上传 ZIP，也不要上传整个聊天输出目录。浏览器手工上传不会按 .gitignore 自动过滤，必须只选本源码目录中的文件。
7. 确认上传清单没有 settings.json、配置备份、work、聊天记录等文件。输入提交说明 `Initial release`，点击 `Commit changes`。
8. 检查仓库首页是否正确显示 README 和 MIT License，以及启动脚本是否位于仓库根目录。

仅上传本源码包的内容，不要附带实际运行后生成的文件。此包未包含任何现成 Git 历史，因此不会带入此前聊天的提交历史。

## 可选：发布版本

在仓库 Releases 中创建一个版本，例如 `v0.1.0`，说明功能和已知限制。GitHub 会自动提供源码 ZIP；若另行上传可运行 ZIP，也只能使用清理后的源码内容。

## 后续维护

通过 Issues 接收问题时，让用户隐藏密码、Web UI 带密码链接、账号信息和配置内容。提交修复前重新运行适当验证。MIT 许可证只适用于本仓库代码，不涵盖腾讯 CodeBuddy CLI 或其服务。

官方上传帮助：https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
