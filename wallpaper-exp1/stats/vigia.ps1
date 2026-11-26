# GANWALK, vigia: só mantém o script de informações rodando enquanto o
# Wallpaper Engine estiver aberto.
#
# Espera o Wallpaper Engine abrir (wallpaper32.exe ou wallpaper64.exe), inicia o
# ganwalk-stats.ps1 escondido e, se o Wallpaper Engine fechar, encerra o script e
# volta a esperar. Consulta a lista de processos a cada 5 s, o que quase não gasta
# nada. É este arquivo que o instalar-inicializacao.cmd coloca para iniciar com o Windows.

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'ganwalk-stats.ps1'
$psExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Test-WallpaperEngine {
    return [bool](Get-Process -Name 'wallpaper32', 'wallpaper64' -ErrorAction SilentlyContinue)
}

# Se outra cópia já responde (por exemplo, o testar.cmd aberto), não sobe mais uma.
function Test-ScriptAnswering {
    try {
        $null = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://localhost:7457/stats'
        return $true
    } catch {
        # 503 = a cópia existente ainda está na primeira leitura: também conta como rodando.
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 503) { return $true }
        return $false
    }
}

$child = $null
while ($true) {
    $we = Test-WallpaperEngine
    $alive = ($null -ne $child) -and (-not $child.HasExited)
    if ($we -and -not $alive -and -not (Test-ScriptAnswering)) {
        # Wallpaper Engine aberto e script parado: inicia (ou reinicia, se ele caiu).
        $child = Start-Process -FilePath $psExe -PassThru -WindowStyle Hidden -WorkingDirectory $PSScriptRoot `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
    } elseif (-not $we -and $alive) {
        # Wallpaper Engine fechou: encerra o script.
        try { Stop-Process -Id $child.Id -Force } catch {}
        $child = $null
    }
    Start-Sleep -Seconds 5
}
