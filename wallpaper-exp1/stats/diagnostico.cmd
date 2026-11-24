@echo off
rem Testa tudo e copia o relatorio para a area de transferencia.
title GANWALK diagnostico
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0diagnostico.ps1"
pause
