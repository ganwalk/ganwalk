# GANWALK, diagnóstico das informações do PC.
# Testa tudo de uma vez e copia o relatório para a área de transferência.

$ErrorActionPreference = 'Continue'
$report = New-Object System.Collections.Generic.List[string]
function Say($msg) { Write-Host $msg; $report.Add("$msg") }

Say '=== GANWALK, diagnóstico ==='
Say "Pasta: $PSScriptRoot"
Say "PowerShell: $($PSVersionTable.PSVersion)"
Say ''

Say '--- O script está rodando? ---'
try {
    $procs = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" | Where-Object { "$($_.CommandLine)" -like '*ganwalk-stats.ps1*' })
    if ($procs.Count -gt 0) { foreach ($p in $procs) { Say "sim, processo $($p.ProcessId)" } }
    else { Say 'NÃO: nenhum ganwalk-stats.ps1 rodando' }
} catch { Say "não consegui verificar: $($_.Exception.Message)" }
Say ''

Say '--- Resposta de http://localhost:7457/stats ---'
try {
    $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 6 -Uri 'http://localhost:7457/stats'
    Say "HTTP $($r.StatusCode): $($r.Content)"
} catch {
    Say "falhou: $($_.Exception.Message)"
}
Say ''

Say '--- Tempo de cada leitura ---'
function Measure-Step($name, [scriptblock]$block) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $v = (& $block | Out-String).Trim()
        Say ('{0,-34} {1,6} ms  {2}' -f $name, $sw.ElapsedMilliseconds, $v)
    } catch {
        Say ('{0,-34} {1,6} ms  ERRO: {2}' -f $name, $sw.ElapsedMilliseconds, $_.Exception.Message)
    }
}
Measure-Step 'Sistema (Win32_OperatingSystem)' { (Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 15 -ErrorAction Stop).Caption }
Measure-Step 'Uso da CPU (Win32_Processor)' { (Get-CimInstance -ClassName Win32_Processor -OperationTimeoutSec 15 -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average).Average }
Measure-Step 'Discos' { ([System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and $_.DriveType -eq 'Fixed' } | ForEach-Object { $_.Name }) -join ' ' }
Measure-Step 'LibreHardwareMonitor (WMI)' { @(Get-CimInstance -Namespace root/LibreHardwareMonitor -ClassName Sensor -OperationTimeoutSec 15 -ErrorAction Stop | Where-Object { $_.SensorType -eq 'Temperature' }).Count }
Measure-Step 'LibreHardwareMonitor (web 8085)' { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -Uri 'http://localhost:8085/data.json').StatusCode }
Measure-Step 'nvidia-smi' { & nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null }
Measure-Step 'Zona térmica (contador)' { (Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -OperationTimeoutSec 15 -ErrorAction Stop | ForEach-Object { $_.HighPrecisionTemperature }) -join ' ' }
Measure-Step 'Zona térmica (ACPI)' { (Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -OperationTimeoutSec 15 -ErrorAction Stop | ForEach-Object { $_.CurrentTemperature }) -join ' ' }
Say ''

Say '--- Últimas linhas do log ---'
$logs = @((Join-Path $PSScriptRoot 'ganwalk-stats.log'), (Join-Path $env:LOCALAPPDATA 'ganwalk\ganwalk-stats.log'))
$any = $false
foreach ($log in $logs) {
    if (Test-Path $log) {
        $any = $true
        Say "($log)"
        foreach ($l in (Get-Content -Path $log -Tail 30 -Encoding UTF8)) { Say $l }
    }
}
if (-not $any) { Say 'nenhum log encontrado (o script nunca conseguiu rodar)' }
Say ''

try {
    ($report -join "`r`n") | Set-Clipboard
    Write-Host '>>> Relatório copiado para a área de transferência. É só colar na conversa.'
} catch {
    Write-Host '>>> Não consegui copiar; selecione o texto da janela e copie.'
}
