@echo off
rem Faz o script de informacoes do PC iniciar sozinho com o Windows (sem janela).
title GANWALK - iniciar com o Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0inicializacao.ps1"
pause
