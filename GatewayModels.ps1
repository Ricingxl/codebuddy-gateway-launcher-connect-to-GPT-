function Get-GatewayModelCatalog {
    param([int]$Port)
    $headers = @{'x-codebuddy-request'='1'}
    try {
        $directory = $env:CODEBUDDY_CONFIG_DIR
        if (-not $directory) { $directory = Join-Path $env:USERPROFILE '.codebuddy' }
        $settings = Get-Content -LiteralPath (Join-Path $directory 'settings.json') -Raw | ConvertFrom-Json
        if (-not $settings.gateway.password) { throw 'Gateway password unavailable.' }
        $headers['X-Access-Token'] = [string]$settings.gateway.password
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/internal/agent/models" -Headers $headers -TimeoutSec 3
        $seen = @{}
        foreach ($model in $response.models) {
            $id = [string]$model.id
            if ($id -notmatch '^[A-Za-z0-9][A-Za-z0-9._:/-]{0,127}$' -or $seen.ContainsKey($id)) { continue }
            $meta = $model._meta.'codebuddy.ai'
            if ($model.disabled -eq $true -or $meta.disabled -eq $true) { continue }
            $seen[$id] = $true
            $credits = [string]$meta.credits
            if (-not $credits) { $credits = [string]$model.description }
            $credits = ($credits -replace '[\x00-\x1f\x7f]',' ').Trim()
            if ($credits -notmatch '^[xX×]\s*\d+(?:\.\d+)?\s+credits$') { $credits = '未提供' }
            [pscustomobject]@{
                Id=$id
                Name=([string]$model.name -replace '[\x00-\x1f\x7f]',' ')
                Credits=$credits
                Promotion='未提供'
            }
        }
    } finally { $headers.Clear(); $settings = $null }
}

function Select-GatewayModel {
    param([object[]]$Models = @())
    $default = 'deepseek-v4.1-flash'
    Write-Host ''
    Write-Host '请选择启动模型（回车默认 DeepSeek V4.1 Flash）：'
    Write-Host '按下方序号选择；编号对应本次目录，更新后可能变化。'
    Write-Host '积分倍率为服务器原文，不是人民币价格或折扣；优惠字段未提供时无法判断是否优惠。'
    for ($i=0; $i -lt $Models.Count; $i++) {
        $rate = $Models[$i].Credits
        if (-not $rate) { $rate = '未提供' }
        Write-Host ('[{0:D2}] {1}  ({2}) | 积分倍率: {3} | 优惠信息: 未提供' -f ($i+1),$Models[$i].Name,$Models[$i].Id,$rate)
    }
    Write-Host '[M] 手动输入模型 ID    [Q] 退出'
    while ($true) {
        $choice = (Read-Host '输入编号，或直接回车').Trim()
        if (-not $choice) { return $default }
        if ($choice -eq 'q') { return $null }
        if ($choice -eq 'm') {
            $manual = (Read-Host '输入模型 ID').Trim()
            if ($manual -match '^[A-Za-z0-9][A-Za-z0-9._:/-]{0,127}$') { return $manual }
            Write-Host '模型 ID 格式无效，请重新选择。'
            continue
        }
        $number = 0
        if ([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $Models.Count) { return $Models[$number-1].Id }
        Write-Host '输入无效，请重新选择。'
    }
}
