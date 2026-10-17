[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 8080,
      [string]$ProjectPath,
      [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._:/-]{0,127}$')][string]$Model,
      [switch]$NoConversationDisplay)
$ErrorActionPreference = 'Stop'
$owned = $null
$relay = $null
$guard = $null
$locked = $false
$result = 1
try {
    if ([string]::IsNullOrWhiteSpace($ProjectPath)) { $ProjectPath = $PSScriptRoot }
    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
    if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) { throw 'ProjectPath must be a directory.' }
    Add-Type -Path (Join-Path $PSScriptRoot 'GatewayJob.cs')
    . (Join-Path $PSScriptRoot 'GatewaySetup.ps1')
    . (Join-Path $PSScriptRoot 'GatewayLogout.ps1')
    $guard = New-Object Threading.Mutex($false, "Local\CodeBuddyGatewayLauncher-$Port")
    try { $locked = $guard.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked = $true }
    if (-not $locked) { throw "This launcher is already running on port $Port." }
    if (-not $Model) {
        Write-Host '[1] 选择模型并启动 Gateway（直接回车）'
        Write-Host '[2] 修改 Gateway 密码'
        Write-Host '[3] 安装/更新 CodeBuddy CLI 最新版，然后登录'
        Write-Host '[4] 登录已有 CodeBuddy CLI'
        Write-Host '[5] 退出当前 CodeBuddy 账号'
        Write-Host '[0] 退出'
        while ($true) {
            $action=(Read-Host '请选择功能').Trim()
            if (-not $action -or $action -eq '1') { break }
            if ($action -eq '0') { $result=0; return }
            if ($action -eq '5') {
                Invoke-CodeBuddyLogout -WorkingDirectory $ProjectPath -Port $Port
                Write-Host '菜单：1 启动；2 改密；3 安装并登录；4 登录；5 退出账号；0 退出程序。'
                continue
            }
            if ($action -eq '3' -or $action -eq '4') {
                Invoke-CodeBuddySetup -WorkingDirectory $ProjectPath -Install:($action -eq '3')
                Write-Host '菜单：1 启动；2 改密；3 安装并登录；4 登录；5 退出账号；0 退出程序。'
                continue
            }
            if ($action -eq '2') {
                & (Join-Path $PSScriptRoot 'Reset-GatewayPassword.ps1') -Port $Port
                Write-Host '返回功能菜单：1 启动；2 修改密码；0 退出。'
            } else { Write-Host '输入无效。' }
        }
    }
    $cli = Get-Command codebuddy.cmd,codebuddy.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cli) { throw 'CodeBuddy not found. Reopen launcher and choose 3 to install.' }
    if ($cli.Source -match '[%!"\r\n]') { throw 'Unsupported characters in CodeBuddy installation path.' }
    $probe = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,$Port)
    try { $probe.Start() } catch { throw "Port $Port is occupied. Stop its existing owner first; nothing was killed." } finally { $probe.Stop() }
    # Child-only environment; this PowerShell exits when the window closes.
    $env:CODEBUDDY_GATEWAY_AUTH = 'password'
    Remove-Item Env:CODEBUDDY_DISABLE_REQUEST_VALIDATION -ErrorAction SilentlyContinue
    Remove-Item Env:CODEBUDDY_GATEWAY_BASE_PATH -ErrorAction SilentlyContinue
    if (-not $Model) {
        . (Join-Path $PSScriptRoot 'GatewayModels.ps1')
        $catalog = @()
        $temporary = $null
        Write-Host '正在读取 CodeBuddy 当前模型目录，请稍候（最长约 40 秒）...'
        try {
            $reservation = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,0)
            $reservation.Start()
            $temporaryPort = $reservation.LocalEndpoint.Port
            $reservation.Stop()
            $bootstrap = '"{0}" /d /s /c ""{1}" --serve --host 127.0.0.1 --port {2} --auth password >nul 2>&1"' -f $env:ComSpec,$cli.Source,$temporaryPort
            $temporary = New-Object GatewayJob($env:ComSpec,$bootstrap,$ProjectPath)
            $deadline = [DateTime]::UtcNow.AddSeconds(35)
            while ([DateTime]::UtcNow -lt $deadline -and -not $temporary.Exited) {
                try { $catalog = @(Get-GatewayModelCatalog -Port $temporaryPort); if ($catalog.Count) { break } } catch { }
                Start-Sleep -Milliseconds 500
            }
        } catch {
            Write-Host '辅助 Gateway 未能完成目录读取，将使用备用菜单。'
        } finally { if ($temporary) { $temporary.Dispose() } }
        if ($catalog.Count) {
            Write-Host ('已从本机 Gateway 读取 {0} 个模型（当前加载目录，不保证云端即时刷新）。' -f $catalog.Count)
        } else {
            Write-Host '未能读取模型目录。可回车使用默认模型，或手动输入 ID。'
        }
        $selectedModel = Select-GatewayModel -Models $catalog
        if (-not $selectedModel) { $result=0; return }
        $Model = $selectedModel
    }
    $backendPort=$Port
    if (-not $NoConversationDisplay) {
        $node=Get-Command node.exe -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
        if (-not $node) { throw '对话显示需要 Node.js LTS。安装后重试，或用 -NoConversationDisplay 跳过。' }
        $proxyPath=Join-Path $PSScriptRoot 'GatewayConsole.js'
        if ($node.Source -match '[%!"\r\n]' -or $proxyPath -match '[%!"\r\n]') { throw 'Unsupported characters in relay path.' }
        $reservation=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,0)
        $reservation.Start(); $backendPort=$reservation.LocalEndpoint.Port; $reservation.Stop()
        $env:CODEBUDDY_CODE_CORS_ORIGINS=(@($env:CODEBUDDY_CODE_CORS_ORIGINS,"http://127.0.0.1:$Port","http://localhost:$Port")|Where-Object {$_}) -join ','
        $relayCommand='"{0}" /d /s /c ""{1}" "{2}" {3} {4}"' -f $env:ComSpec,$node.Source,$proxyPath,$Port,$backendPort
        $relay=New-Object GatewayJob($env:ComSpec,$relayCommand,$ProjectPath)
    }
    $command = '"{0}" /d /s /c ""{1}" --serve --host 127.0.0.1 --port {2} --auth password --model {3}"' -f $env:ComSpec,$cli.Source,$backendPort,$Model
    Write-Host "Gateway: http://127.0.0.1:$Port"
    Write-Host "Selected model: $Model"
    Write-Host 'Keep this window open. Close it to stop Gateway and its child processes.'
    Write-Host 'Use the password printed by CodeBuddy. This launcher does not save logs.'
    if ($relay) { Write-Host "对话显示入口：http://127.0.0.1:$Port 。CLI 下方打印的是内部端口，请调用此处入口。" }
    $owned = New-Object GatewayJob($env:ComSpec,$command,$ProjectPath)
    while (-not $owned.Exited) { if ($relay -and $relay.Exited) { throw '对话转发进程已停止，Gateway 将一起停止。' }; Start-Sleep -Milliseconds 250 }
    $result = [int]$owned.ExitCode
    if ($result -ne 0) { Write-Host "CodeBuddy exited with code $result. See the error above." }
} catch { Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red }
finally {
    if ($owned) { $owned.Dispose() }
    if ($relay) { $relay.Dispose() }
    if ($locked) { $guard.ReleaseMutex() }
    if ($guard) { $guard.Dispose() }
}
exit $result
