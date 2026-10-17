[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 8080)
$ErrorActionPreference = 'Stop'
$secret = Read-Host 'Gateway password (hidden)' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
$headers = $null
$failed = $false
try {
    $headers = @{ 'x-codebuddy-request' = '1'; 'X-Access-Token' = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    foreach ($route in @('health','info')) {
        try {
            $reply = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/v1/$route" -Headers $headers -TimeoutSec 10
            Write-Host "PASS /api/v1/$route"
            $reply | ConvertTo-Json -Depth 12
        } catch {
            $failed = $true
            $status = 'connection/timeout error'
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            Write-Host "FAIL /api/v1/$route : $status (see README.md)" -ForegroundColor Red
        }
    }
} finally {
    if ($headers) { $headers.Clear() }
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    $secret.Dispose()
}
if ($failed) { exit 1 }
