@echo off
rem Roda o script COM janela, para ver o que acontece. Feche a janela para parar.
title GANWALK stats (teste)
echo Pasta: %~dp0
if not exist "%~dp0ganwalk-stats.ps1" (
  echo.
  echo Nao encontrei o ganwalk-stats.ps1 nesta pasta.
  echo Extraia o zip inteiro antes de rodar ^(botao direito no zip, Extrair tudo^).
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ganwalk-stats.ps1"
echo.
echo O script terminou. O registro completo esta em %~dp0ganwalk-stats.log
pause
