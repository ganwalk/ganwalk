# GANWALK, informações do PC para o wallpaper (Wallpaper Engine)
#
# Wallpapers web não conseguem ler disco, memória nem processador. Este script
# lê esses dados e os entrega ao wallpaper por http://localhost:7457/stats,
# só dentro do próprio PC (não aceita conexões de fora).
#
# Privacidade: o endereço responde apenas a páginas locais (o wallpaper, aberto
# como arquivo ou servido pelo próprio PC). Sites da internet abertos no
# navegador são recusados, então nenhum site consegue ler estas informações.
# Não envia o nome do computador, do usuário nem nada além dos números abaixo.
#
# Como funciona: a leitura dos sensores roda numa linha de execução separada,
# a cada 2 s, e guarda o resultado pronto. A parte que atende o wallpaper só
# entrega esse resultado, na hora. Algumas leituras do Windows levam vários
# segundos; assim elas nunca atrasam a resposta.
#
# Tudo o que acontece fica registrado em ganwalk-stats.log, nesta pasta (ou em
# %LOCALAPPDATA%\ganwalk, se esta pasta não aceitar gravação).
#
# Uso: rode iniciar.cmd (ou: powershell -ExecutionPolicy Bypass -File ganwalk-stats.ps1)
# Compatível com o Windows PowerShell 5.1 que já vem no Windows.

param([int]$Port = 7457)

$ErrorActionPreference = 'Stop'

# O log fica ao lado do script; se a pasta não aceitar gravação (por exemplo,
# dentro de C:\Program Files), vai para %LOCALAPPDATA%\ganwalk.
$logFile = Join-Path $PSScriptRoot 'ganwalk-stats.log'
try {
    Add-Content -Path $logFile -Value '' -Encoding UTF8
} catch {
    $dir = Join-Path $env:LOCALAPPDATA 'ganwalk'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $logFile = Join-Path $dir 'ganwalk-stats.log'
}
function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
    Write-Host $line
    try { Add-Content -Path $logFile -Value $line -Encoding UTF8 } catch {}
}
Log "Iniciando (PowerShell $($PSVersionTable.PSVersion), porta $Port)"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try {
    $listener.Start()
} catch {
    Log "Não foi possível abrir a porta ${Port}: $($_.Exception.Message)"
    # Talvez já exista uma cópia rodando (pelo iniciar.cmd). Se sim, mostra o que ela responde.
    try {
        $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri "http://localhost:$Port/stats"
        Log "Já existe uma cópia rodando nessa porta, e ela respondeu: $($r.Content)"
    } catch {
        Log "Nenhuma cópia respondeu nessa porta. Outro programa pode estar usando a porta ${Port}. Rode com -Port e outro número e ajuste a porta no painel do wallpaper."
    }
    exit 1
}
Log "Rodando em http://localhost:$Port/stats (feche a janela ou Ctrl+C para parar)"

# ---------------------------------------------------------------------------
# LEITURA DOS DADOS (linha de execução separada)
# ---------------------------------------------------------------------------
# Resultado compartilhado entre as duas partes: o JSON pronto, quando ficou
# pronto e quanto tempo a última leitura levou.
$shared = [hashtable]::Synchronized(@{ json = $null; at = $null; ms = 0; logFile = $logFile })

$collector = {
    $ErrorActionPreference = 'Stop'
    function Log($msg) {
        $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
        try { Add-Content -Path $shared.logFile -Value $line -Encoding UTF8 } catch {}
    }

    # Temperaturas. O Windows não expõe a da CPU de forma confiável, então o
    # script tenta, nesta ordem, e informa de onde veio cada uma (cpuTempFrom,
    # gpuTempFrom):
    #  1. LibreHardwareMonitor (ou OpenHardwareMonitor) aberto: sensores no WMI;
    #  2. LibreHardwareMonitor com o servidor web ligado (Options > Remote Web
    #     Server > Run, porta 8085): lê http://localhost:8085/data.json;
    #  3. GPU NVIDIA: nvidia-smi, que vem com o driver;
    #  4. CPU: contador térmico do Windows (sem administrador). É a zona térmica
    #     da placa-mãe, uma aproximação da CPU;
    #  5. CPU, último recurso: zona térmica ACPI (costuma exigir administrador).
    function ConvertTo-Celsius($text) {
        if ("$text" -match '(-?\d+(?:[.,]\d+)?)') { return [math]::Round([double]($Matches[1] -replace ',', '.')) }
        return $null
    }

    # Percorre a árvore do data.json do LibreHardwareMonitor.
    function Find-LhmTemps($node, $kind, $out) {
        $img = "$($node.ImageURL)"
        $k = $kind
        if ($img -match 'cpu') { $k = 'cpu' }
        elseif ($img -match 'nvidia|ati|amd|gpu') { $k = 'gpu' }
        if ($k -and "$($node.Value)" -match '°C') {
            [void]$out.Add([pscustomobject]@{ kind = $k; name = "$($node.Text)"; value = (ConvertTo-Celsius $node.Value) })
        }
        foreach ($c in @($node.Children)) { if ($c) { $null = Find-LhmTemps $c $k $out } }
    }

    function Get-Temps {
        $cpu = $null; $gpu = $null; $cpuFrom = $null; $gpuFrom = $null

        # 1. WMI do LibreHardwareMonitor / OpenHardwareMonitor
        foreach ($ns in 'root/LibreHardwareMonitor', 'root/OpenHardwareMonitor') {
            try {
                $sensors = @(Get-CimInstance -OperationTimeoutSec 5 -Namespace $ns -ClassName Sensor -ErrorAction Stop | Where-Object { $_.SensorType -eq 'Temperature' })
                if ($sensors.Count -eq 0) { continue }
                $cpuS = @($sensors | Where-Object { $_.Identifier -match '/(amdcpu|intelcpu)/' })
                $pick = $cpuS | Where-Object { $_.Name -match 'Package|Tctl|Tdie' } | Select-Object -First 1
                if (-not $pick) { $pick = $cpuS | Sort-Object -Property Value -Descending | Select-Object -First 1 }
                if ($pick) { $cpu = [math]::Round([double]$pick.Value); $cpuFrom = "$ns ($($pick.Name))" }
                $gpuS = @($sensors | Where-Object { $_.Identifier -match '/gpu' })
                $pick = $gpuS | Where-Object { $_.Name -match 'Core' } | Select-Object -First 1
                if (-not $pick) { $pick = $gpuS | Select-Object -First 1 }
                if ($pick) { $gpu = [math]::Round([double]$pick.Value); $gpuFrom = "$ns ($($pick.Name))" }
                break
            } catch {}
        }

        # 2. Servidor web do LibreHardwareMonitor
        if ($null -eq $cpu -or $null -eq $gpu) {
            try {
                $tree = Invoke-RestMethod -Uri 'http://localhost:8085/data.json' -TimeoutSec 2
                $found = New-Object System.Collections.ArrayList
                $null = Find-LhmTemps $tree $null $found
                if ($null -eq $cpu) {
                    $c = @($found | Where-Object { $_.kind -eq 'cpu' -and $null -ne $_.value })
                    $pick = $c | Where-Object { $_.name -match 'Package|Tctl|Tdie' } | Select-Object -First 1
                    if (-not $pick) { $pick = $c | Sort-Object -Property value -Descending | Select-Object -First 1 }
                    if ($pick) { $cpu = $pick.value; $cpuFrom = "LibreHardwareMonitor web ($($pick.name))" }
                }
                if ($null -eq $gpu) {
                    $g = @($found | Where-Object { $_.kind -eq 'gpu' -and $null -ne $_.value })
                    $pick = $g | Where-Object { $_.name -match 'Core' } | Select-Object -First 1
                    if (-not $pick) { $pick = $g | Select-Object -First 1 }
                    if ($pick) { $gpu = $pick.value; $gpuFrom = "LibreHardwareMonitor web ($($pick.name))" }
                }
            } catch {}
        }

        # 3. nvidia-smi
        if ($null -eq $gpu -and (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
            try {
                $out = & nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null | Select-Object -First 1
                if ($out -match '^\s*(\d+)') { $gpu = [int]$Matches[1]; $gpuFrom = 'nvidia-smi' }
            } catch {}
        }

        # 4. Contador térmico do Windows (não precisa de administrador)
        if ($null -eq $cpu) {
            try {
                $zones = @(Get-CimInstance -OperationTimeoutSec 5 -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction Stop)
                $best = $null
                foreach ($z in $zones) {
                    # HighPrecisionTemperature vem em décimos de kelvin; Temperature, em kelvin.
                    $k = if ($z.HighPrecisionTemperature) { $z.HighPrecisionTemperature / 10 } else { $z.Temperature }
                    if ($k -gt 200) {
                        $c = [math]::Round($k - 273.15)
                        if ($null -eq $best -or $c -gt $best) { $best = $c }
                    }
                }
                if ($null -ne $best) { $cpu = $best; $cpuFrom = 'zona térmica do Windows (aproximada)' }
            } catch {}
        }

        # 5. Zona térmica ACPI
        if ($null -eq $cpu) {
            try {
                $z = Get-CimInstance -OperationTimeoutSec 5 -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1
                if ($z) { $cpu = [math]::Round($z.CurrentTemperature / 10 - 273.15); $cpuFrom = 'ACPI (aproximada)' }
            } catch {}
        }

        @{ cpu = $cpu; gpu = $gpu; cpuFrom = $cpuFrom; gpuFrom = $gpuFrom }
    }

    function Get-Stats {
        $os = Get-CimInstance -OperationTimeoutSec 5 -ClassName Win32_OperatingSystem
        $cpu = (Get-CimInstance -OperationTimeoutSec 5 -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        if ($null -eq $cpu) { $cpu = 0 }
        $temps = Get-Temps

        $disks = @()
        foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
            if ($d.IsReady -and $d.DriveType -eq [System.IO.DriveType]::Fixed) {
                $disks += [ordered]@{
                    name    = $d.Name.TrimEnd('\')
                    totalGB = [math]::Round($d.TotalSize / 1GB, 1)
                    freeGB  = [math]::Round($d.AvailableFreeSpace / 1GB, 1)
                }
            }
        }

        [ordered]@{
            cpu        = [int][math]::Round($cpu)
            # Win32_OperatingSystem informa a memória em KB.
            ramTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            ramFreeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
            uptimeSec  = [int]((Get-Date) - $os.LastBootUpTime).TotalSeconds
            disks      = $disks
            cpuTemp    = $temps.cpu
            gpuTemp    = $temps.gpu
            cpuTempFrom = $temps.cpuFrom
            gpuTempFrom = $temps.gpuFrom
        }
    }

    $first = $true
    while ($true) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $stats = Get-Stats
            $shared.json = $stats | ConvertTo-Json -Depth 4 -Compress
            $shared.at = Get-Date
            $shared.ms = $sw.ElapsedMilliseconds
            if ($first) {
                Log "Primeira leitura em $($sw.ElapsedMilliseconds) ms: $($shared.json)"
                $first = $false
            }
        } catch {
            Log "Erro ao ler os dados: $($_.Exception.Message)"
        }
        Start-Sleep -Milliseconds 2000
    }
}

$rs = [runspacefactory]::CreateRunspace()
$rs.Open()
$rs.SessionStateProxy.SetVariable('shared', $shared)
$worker = [powershell]::Create()
$worker.Runspace = $rs
[void]$worker.AddScript($collector.ToString())
$workerHandle = $worker.BeginInvoke()
Log "Lendo os dados em segundo plano. Teste no navegador: http://localhost:$Port/stats"

# ---------------------------------------------------------------------------
# ATENDIMENTO DO WALLPAPER
# ---------------------------------------------------------------------------
function Test-Origin($origin) {
    # Aceita o que é local: sem Origin, "null", file://, esquemas internos do
    # Wallpaper Engine e páginas servidas pelo próprio PC (localhost/127.0.0.1).
    # Recusa sites da internet (http/https com qualquer outro endereço).
    if ([string]::IsNullOrEmpty($origin)) { return $true }
    if ($origin -eq 'null') { return $true }
    if ($origin -match '^https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?/?$') { return $true }
    if ($origin -like 'http://*' -or $origin -like 'https://*') { return $false }
    return $true
}

$seen = @{}
$waitLogged = $false
while ($listener.IsListening) {
    $task = $listener.GetContextAsync()
    while (-not $task.AsyncWaitHandle.WaitOne(1000)) {
        # Se a leitura em segundo plano morrer, registra o motivo.
        if ($workerHandle.IsCompleted -and -not $script:workerDeadLogged) {
            $script:workerDeadLogged = $true
            $errs = ($worker.Streams.Error | ForEach-Object { $_.ToString() }) -join ' | '
            Log "A leitura em segundo plano parou: $errs"
        }
    }
    $ctx = $task.GetAwaiter().GetResult()
    $req = $ctx.Request
    $res = $ctx.Response
    try {
        $origin = $req.Headers['Origin']
        if (-not $seen.ContainsKey("$origin")) {
            $seen["$origin"] = $true
            Log "Primeiro pedido vindo de: '$origin' ($(if (Test-Origin $origin) { 'aceito' } else { 'recusado' }))"
        }
        if (-not (Test-Origin $origin)) {
            $res.StatusCode = 403
            $res.Close()
            continue
        }
        $res.Headers.Add('Access-Control-Allow-Origin', '*')
        $res.Headers.Add('Access-Control-Allow-Methods', 'GET, OPTIONS')
        $res.Headers.Add('Access-Control-Allow-Headers', '*')
        # Exigido pelo Chromium para páginas locais chamarem localhost.
        $res.Headers.Add('Access-Control-Allow-Private-Network', 'true')
        $res.Headers.Add('Cache-Control', 'no-store')

        if ($req.HttpMethod -eq 'OPTIONS') {
            $res.StatusCode = 204
            $res.Close()
            continue
        }
        if ($req.Url.AbsolutePath -ne '/stats') {
            $res.StatusCode = 404
            $res.Close()
            continue
        }

        $json = $shared.json
        if ($null -eq $json) {
            # Primeira leitura ainda em andamento.
            if (-not $waitLogged) { Log 'Pedido recebido antes da primeira leitura ficar pronta (respondendo 503).'; $waitLogged = $true }
            $res.StatusCode = 503
            $res.Close()
            continue
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = 'application/json; charset=utf-8'
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
    } catch {
        Log "Erro ao responder: $($_.Exception.Message)"
        try { $res.StatusCode = 500; $res.Close() } catch {}
    }
}
