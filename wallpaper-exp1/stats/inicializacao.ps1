# GANWALK, coloca (ou tira) o script de informações do PC na inicialização do Windows.
# Cria um atalho na pasta "Inicializar" do usuário (não precisa de administrador)
# que roda o ganwalk-stats.ps1 escondido, sem janela, sempre que você entra no Windows.
#
# Uso: instalar-inicializacao.cmd (põe) ou remover-inicializacao.cmd (tira).

param([switch]$Remover)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'ganwalk-stats.ps1'
$startup = [Environment]::GetFolderPath('Startup')
$lnkPath = Join-Path $startup 'GANWALK stats.lnk'

if ($Remover) {
    if (Test-Path $lnkPath) {
        Remove-Item $lnkPath -Force
        Write-Host 'Pronto: o script não vai mais iniciar com o Windows.'
    } else {
        Write-Host 'O script já não estava na inicialização.'
    }
    Write-Host 'Para parar a cópia que está rodando agora, reinicie o PC ou encerre o "Windows PowerShell" no Gerenciador de Tarefas.'
    exit 0
}

if (-not (Test-Path $script)) {
    Write-Host "Não encontrei $script. Extraia o zip inteiro antes."
    exit 1
}

$psExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$psArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($lnkPath)
$lnk.TargetPath = $psExe
$lnk.Arguments = $psArgs
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.WindowStyle = 7   # minimizado (o -WindowStyle Hidden esconde de vez)
$lnk.Description = 'GANWALK: informações do PC para o wallpaper'
$lnk.Save()
Write-Host "Pronto: atalho criado em $lnkPath"
Write-Host 'O script vai iniciar sozinho, escondido, sempre que você entrar no Windows.'

# Já inicia agora, se não estiver rodando.
$running = $false
try {
    $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -Uri 'http://localhost:7457/stats'
    $running = $true
} catch {}
if ($running) {
    Write-Host 'O script já está rodando agora (pode fechar a janela do testar.cmd, se estiver aberta; ele volta sozinho no próximo login).'
} else {
    Start-Process -FilePath $psExe -ArgumentList $psArgs -WindowStyle Hidden -WorkingDirectory $PSScriptRoot
    Write-Host 'Script iniciado agora, escondido. Em alguns segundos o painel aparece no wallpaper.'
}
