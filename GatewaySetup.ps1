function Invoke-CodeBuddySetup {
    param([string]$WorkingDirectory,[switch]$Install)
    if ($Install) {
        $npm=Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
        if (-not $npm) {
            Write-Host '未找到 npm。请先安装 Node.js LTS：https://nodejs.org/ ，然后重新打开启动器。'
            return
        }
        if ($npm.Source -match '[%!"\r\n]') { throw 'npm 安装路径包含不支持的字符。' }
        Write-Host '正在安装/更新官方 CodeBuddy CLI 最新版，请等待安装结果...'
        $command='"{0}" /d /s /c ""{1}" install -g @tencent-ai/codebuddy-code@latest"' -f $env:ComSpec,$npm.Source
        $setupJob=$null
        try {
            $setupJob=New-Object GatewayJob($env:ComSpec,$command,$WorkingDirectory)
            while (-not $setupJob.Exited) { Start-Sleep -Milliseconds 250 }
            if ($setupJob.ExitCode -ne 0) { Write-Host '安装失败，请查看上方错误。返回主菜单。'; return }
        } finally { if ($setupJob) { $setupJob.Dispose() } }
        # npm's usual per-user bin directory may not have been in the launcher PATH.
        $npmBin=Join-Path $env:APPDATA 'npm'
        if (Test-Path -LiteralPath $npmBin) { $env:PATH=$env:PATH+';'+$npmBin }
    }
    $cli=Get-Command codebuddy.cmd,codebuddy.exe -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
    if (-not $cli) { Write-Host '未找到 CLI，请先选择安装。'; return }
    if ($cli.Source -match '[%!"\r\n]') { throw 'CLI 安装路径包含不支持的字符。' }
    Write-Host '即将打开 CodeBuddy。请按提示在浏览器登录。已登录时会进入交互界面。'
    Write-Host '完成后请在 CodeBuddy 输入 /exit 返回启动菜单，再选择 1 开启 Gateway。'
    $login=$null
    try {
        $command='"{0}" /d /s /c ""{1}""' -f $env:ComSpec,$cli.Source
        $login=New-Object GatewayJob($env:ComSpec,$command,$WorkingDirectory)
        while (-not $login.Exited) { Start-Sleep -Milliseconds 250 }
        Write-Host '已返回主菜单。请确认登录成功后选择 1 启动 Gateway。'
    } finally { if ($login) { $login.Dispose() } }
}
