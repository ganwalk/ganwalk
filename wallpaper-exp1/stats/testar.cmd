@echo off
rem Roda o script COM janela, para ver mensagens de erro. Feche a janela para parar.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ganwalk-stats.ps1"
pause
