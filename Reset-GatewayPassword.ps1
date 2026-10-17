[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port=8080)
$ErrorActionPreference='Stop'
$first=$null
$second=$null
$pointer=[IntPtr]::Zero
$pointer2=[IntPtr]::Zero
try {
    $probe=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,$Port)
    try { $probe.Start() } catch { throw "端口 $Port 正被占用，请关闭旧 Gateway 窗口后再修改。" } finally { $probe.Stop() }
    Write-Host '请确认所有 Gateway 实例均已停止，包括其他端口的实例。'
    if ((Read-Host '确认均已停止？输入 YES 继续，其他输入取消') -cne 'YES') { return }
    $directory=$env:CODEBUDDY_CONFIG_DIR
    if (-not $directory) { $directory=Join-Path $env:USERPROFILE '.codebuddy' }
    $path=Join-Path $directory 'settings.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw '未找到 settings.json，请先完成安装和首次启动。' }
    $original=[IO.File]::ReadAllText($path)
    $settings=$original|ConvertFrom-Json
    Write-Host ('正在修改配置：'+$path)
    Write-Host '输入至少 16 个字符的新密码；不会显示或写入启动脚本。'
    $first=Read-Host '新密码' -AsSecureString
    $second=Read-Host '再次输入新密码' -AsSecureString
    $pointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($first)
    $pointer2=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($second)
    $plain=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    $repeat=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer2)
    if ($plain.Length -lt 16 -or $plain -match '[\s\x00-\x1f\x7f]') { throw '密码至少 16 个字符，且不能包含空白或控制字符。' }
    if ($plain -cne $repeat) { throw '两次密码不一致，未修改配置。' }
    if ($settings.gateway.password -ceq $plain) { throw '新密码与原密码相同，未修改配置。' }
    if (-not $settings.gateway) { $settings|Add-Member -MemberType NoteProperty -Name gateway -Value ([pscustomobject]@{}) -Force }
    $settings.gateway|Add-Member -MemberType NoteProperty -Name auth -Value 'password' -Force
    $settings.gateway|Add-Member -MemberType NoteProperty -Name password -Value $plain -Force
    $json=$settings|ConvertTo-Json -Depth 100
    $null=$json|ConvertFrom-Json
    if ([IO.File]::ReadAllText($path) -cne $original) { throw '配置被其他程序修改，请重新操作。' }
    # Keep a recoverable original before writing the replacement.
    $backup=$path+'.before-password-change.'+[DateTime]::Now.ToString('yyyyMMdd-HHmmss')+'.'+[guid]::NewGuid().ToString('N')+'.bak'
    Copy-Item -LiteralPath $path -Destination $backup -ErrorAction Stop
    try { [IO.File]::WriteAllText($path,$json,(New-Object Text.UTF8Encoding($false))) }
    catch {
        try { [IO.File]::WriteAllText($path,$original,(New-Object Text.UTF8Encoding($false))) } catch { Write-Host ('请从备份恢复配置：'+$backup) }
        throw
    }
    Write-Host '密码已修改。请重新启动 Gateway，再用新密码运行 Test-Gateway.cmd。'
    Write-Host ('原配置备份：'+$backup)
    Write-Host '备份含旧密码及其他配置，请勿分享；确认新配置正常后可自行删除备份。'
} catch { Write-Host ('修改失败：'+$_.Exception.Message+'（行 '+$_.InvocationInfo.ScriptLineNumber+'）') -ForegroundColor Red }
finally {
    if ($pointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    if ($pointer2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer2) }
    if ($first) { $first.Dispose() }; if ($second) { $second.Dispose() }
    $plain=$null;$repeat=$null;$json=$null;$settings=$null;$original=$null
}
