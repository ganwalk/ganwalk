@echo off
rem Tira o script de informacoes do PC da inicializacao do Windows.
title GANWALK - nao iniciar com o Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0inicializacao.ps1" -Remover
pause
