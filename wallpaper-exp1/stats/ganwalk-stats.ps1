# GANWALK, informações do PC para o wallpaper (Wallpaper Engine)
#
# Wallpapers web não conseguem ler disco, memória nem processador. Este script
# lê esses dados e os entrega ao wallpaper por http://localhost:7457/stats,
# só dentro do próprio PC (não aceita conexões de fora).
#
# Privacidade: o endereço responde apenas a páginas abertas a partir de um
# arquivo local (o wallpaper). Sites abertos no navegador são recusados, então
# nenhum site consegue ler estas informações. Não envia o nome do computador,
# do usuário nem nada além dos números abaixo.
#
# Uso: rode iniciar.cmd (ou: powershell -ExecutionPolicy Bypass -File ganwalk-stats.ps1)
# Compatível com o Windows PowerShell 5.1 que já vem no Windows.

param([int]$Port = 7457)

$ErrorActionPreference = 'Stop'

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try {
    $listener.Start()
} catch {
    Write-Host "Não foi possível abrir a porta $Port. Ela já está em uso? ($($_.Exception.Message))"
    exit 1
}
Write-Host "GANWALK stats rodando em http://localhost:$Port/stats (Ctrl+C para parar)"

$script:cache = $null
$script:cacheAt = [datetime]::MinValue

# Temperaturas. O Windows não expõe a da CPU de forma confiável, então:
#  1. se o LibreHardwareMonitor (ou o OpenHardwareMonitor) estiver aberto, lê os
#     sensores que ele publica no WMI (CPU e GPU de qualquer marca);
#  2. GPU NVIDIA: nvidia-smi, que vem com o driver;
#  3. CPU, último recurso: zona térmica ACPI (costuma exigir administrador e
#     nem sempre reflete a CPU de verdade).
function Get-Temps {
    $cpu = $null; $gpu = $null
    foreach ($ns in 'root/LibreHardwareMonitor', 'root/OpenHardwareMonitor') {
        try {
            $sensors = @(Get-CimInstance -Namespace $ns -ClassName Sensor -ErrorAction Stop | Where-Object { $_.SensorType -eq 'Temperature' })
            if ($sensors.Count -eq 0) { continue }
            $cpuS = @($sensors | Where-Object { $_.Identifier -match '/(amdcpu|intelcpu)/' })
            $pick = $cpuS | Where-Object { $_.Name -match 'Package|Tctl|Tdie' } | Select-Object -First 1
            if (-not $pick) { $pick = $cpuS | Sort-Object -Property Value -Descending | Select-Object -First 1 }
            if ($pick) { $cpu = [math]::Round([double]$pick.Value) }
            $gpuS = @($sensors | Where-Object { $_.Identifier -match '/gpu' })
            $pick = $gpuS | Where-Object { $_.Name -match 'Core' } | Select-Object -First 1
            if (-not $pick) { $pick = $gpuS | Select-Object -First 1 }
            if ($pick) { $gpu = [math]::Round([double]$pick.Value) }
            break
        } catch {}
    }
    if ($null -eq $gpu -and (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
        try {
            $out = & nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null | Select-Object -First 1
            if ($out -match '^\s*(\d+)') { $gpu = [int]$Matches[1] }
        } catch {}
    }
    if ($null -eq $cpu) {
        try {
            $z = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1
            if ($z) { $cpu = [math]::Round($z.CurrentTemperature / 10 - 273.15) }
        } catch {}
    }
    @{ cpu = $cpu; gpu = $gpu }
}

function Get-Stats {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
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
    }
}

function Test-Origin($origin) {
    # Sem Origin, "null" ou file:// = o wallpaper (arquivo local). http(s) = um site: recusa.
    if ([string]::IsNullOrEmpty($origin)) { return $true }
    if ($origin -eq 'null') { return $true }
    if ($origin -like 'http://*' -or $origin -like 'https://*') { return $false }
    return $true
}

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    try {
        $origin = $req.Headers['Origin']
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

        # Recalcula no máximo a cada 2 s (o wallpaper consulta a cada 3 s).
        if ($null -eq $script:cache -or ((Get-Date) - $script:cacheAt).TotalSeconds -ge 2) {
            $script:cache = Get-Stats | ConvertTo-Json -Depth 4 -Compress
            $script:cacheAt = Get-Date
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($script:cache)
        $res.ContentType = 'application/json; charset=utf-8'
        $res.Headers.Add('Cache-Control', 'no-store')
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
    } catch {
        try { $res.StatusCode = 500; $res.Close() } catch {}
    }
}
