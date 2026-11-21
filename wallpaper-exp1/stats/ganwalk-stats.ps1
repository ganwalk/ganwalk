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

function Get-Stats {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    if ($null -eq $cpu) { $cpu = 0 }

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
