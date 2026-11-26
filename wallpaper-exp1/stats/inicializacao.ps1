# GANWALK, coloca (ou tira) o script de informações do PC na inicialização do Windows.
# Cria um atalho na pasta "Inicializar" do usuário (não precisa de administrador)
# que roda o vigia.ps1 escondido a cada login. O vigia espera o Wallpaper Engine
# abrir, sobe o ganwalk-stats.ps1 e o encerra quando o Wallpaper Engine fecha.
#
# Uso: instalar-inicializacao.cmd (põe) ou remover-inicializacao.cmd (tira).

param([switch]$Remover)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'ganwalk-stats.ps1'
$vigia = Join-Path $PSScriptRoot 'vigia.ps1'
$startup = [Environment]::GetFolderPath('Startup')
$lnkPath = Join-Path $startup 'GANWALK stats.lnk'

if ($Remover) {
    if (Test-Path $lnkPath) {
        Remove-Item $lnkPath -Force
        Write-Host 'Pronto: o script não vai mais iniciar com o Windows.'
    } else {
        Write-Host 'O script já não estava na inicialização.'
    }
    # Encerra o vigia e o script que estiverem rodando.
    $procs = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" | Where-Object { "$($_.CommandLine)" -like '*vigia.ps1*' -or "$($_.CommandLine)" -like '*ganwalk-stats.ps1*' })
    foreach ($p in $procs) { try { Stop-Process -Id $p.ProcessId -Force } catch {} }
    if ($procs.Count -gt 0) { Write-Host 'O vigia e o script que estavam rodando foram encerrados.' }
    exit 0
}

if (-not (Test-Path $script) -or -not (Test-Path $vigia)) {
    Write-Host "Não encontrei $script. Extraia o zip inteiro antes."
    exit 1
}

$psExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$psArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$vigia`""

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($lnkPath)
$lnk.TargetPath = $psExe
$lnk.Arguments = $psArgs
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.WindowStyle = 7   # minimizado (o -WindowStyle Hidden esconde de vez)
$lnk.Description = 'GANWALK: informações do PC para o wallpaper'
$lnk.Save()
Write-Host "Pronto: atalho criado em $lnkPath"
Write-Host 'A cada login, um vigia escondido espera o Wallpaper Engine abrir e então sobe o script.'
Write-Host 'Se o Wallpaper Engine fechar, o script é encerrado; quando ele abrir de novo, o script volta.'

# Já inicia o vigia agora (ele sobe o script assim que vir o Wallpaper Engine aberto).
$vigiaRodando = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" | Where-Object { "$($_.CommandLine)" -like '*vigia.ps1*' }).Count -gt 0
if ($vigiaRodando) {
    Write-Host 'O vigia já está rodando.'
} else {
    Start-Process -FilePath $psExe -ArgumentList $psArgs -WindowStyle Hidden -WorkingDirectory $PSScriptRoot
    Write-Host 'Vigia iniciado agora. Com o Wallpaper Engine aberto, o painel aparece em alguns segundos.'
    Write-Host '(Se o testar.cmd estiver aberto, pode fechá-lo: o vigia sobe o script sozinho.)'
}
