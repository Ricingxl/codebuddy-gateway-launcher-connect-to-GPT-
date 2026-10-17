function Invoke-CodeBuddyLogout {
    param([string]$WorkingDirectory,[int]$Port=8080)
    $logoutJob=$null
    $headers=@{'x-codebuddy-request'='1'}
    try {
        $probe=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,$Port)
        try { $probe.Start() } catch { throw '请先关闭正在运行的 Gateway 窗口。' } finally { $probe.Stop() }
        Write-Host '此操作退出当前 CLI 账号，不修改 Gateway 密码，不删除历史记录。'
        Write-Host '请先停止所有其他端口的 Gateway/CLI 会话，避免它们继续使用旧登录状态。'
        if ((Read-Host '输入 YES 退出当前账号，其他输入取消') -cne 'YES') { Write-Host '已取消。'; return }
        $cli=Get-Command codebuddy.cmd,codebuddy.exe -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
        if (-not $cli) { throw '未安装 CodeBuddy CLI，请先安装。' }
        if ($cli.Source -match '[%!"\r\n]') { throw 'CLI 路径包含不支持的字符。' }
        $reservation=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,0)
        $reservation.Start();$temporaryPort=$reservation.LocalEndpoint.Port;$reservation.Stop()
        $env:CODEBUDDY_GATEWAY_AUTH='password'
        Remove-Item Env:CODEBUDDY_DISABLE_REQUEST_VALIDATION -ErrorAction SilentlyContinue
        Remove-Item Env:CODEBUDDY_GATEWAY_BASE_PATH -ErrorAction SilentlyContinue
        $command='"{0}" /d /s /c ""{1}" --serve --host 127.0.0.1 --port {2} --auth password >nul 2>&1"' -f $env:ComSpec,$cli.Source,$temporaryPort
        Write-Host '正在准备退出登录，请稍候...'
        $logoutJob=New-Object GatewayJob($env:ComSpec,$command,$WorkingDirectory)
        $directory=$env:CODEBUDDY_CONFIG_DIR
        if (-not $directory) { $directory=Join-Path $env:USERPROFILE '.codebuddy' }
        $ready=$false
        $deadline=[DateTime]::UtcNow.AddSeconds(35)
        while ([DateTime]::UtcNow -lt $deadline -and -not $logoutJob.Exited) {
            try {
                $settings=Get-Content -LiteralPath (Join-Path $directory 'settings.json') -Raw|ConvertFrom-Json
                if (-not $settings.gateway.password) { throw 'Password unavailable' }
                $headers['X-Access-Token']=[string]$settings.gateway.password
                $null=Invoke-RestMethod "http://127.0.0.1:$temporaryPort/api/v1/info" -Headers $headers -TimeoutSec 3
                $ready=$true;break
            } catch { Start-Sleep -Milliseconds 500 }
        }
        if (-not $ready) { throw '辅助服务未就绪。可手工运行 codebuddy.cmd，在交互界面输入 /logout。' }
        # Account logout, distinct from deleting the Gateway browser cookie.
        $reply=Invoke-RestMethod "http://127.0.0.1:$temporaryPort/api/v1/auth/account/logout" -Method Post -ContentType 'application/json' -Body '{}' -Headers $headers -TimeoutSec 15
        if ($reply.success -eq $true -or $reply.data.success -eq $true) {
            Write-Host 'CodeBuddy 已确认退出当前账号。需要重新使用时选 4 登录。'
            Write-Host '若使用 CODEBUDDY_API_KEY 等外部凭据，它们仍需在原配置处单独移除。'
        } else { throw '接口未确认退出成功。可在 CLI 交互界面输入 /logout。' }
    } catch { Write-Host ('退出账号失败：'+$_.Exception.Message) -ForegroundColor Red }
    finally { $headers.Clear();$settings=$null;if($logoutJob){$logoutJob.Dispose()} }
}
