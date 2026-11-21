@echo off
rem Inicia o script de informacoes do PC para o wallpaper GANWALK, sem janela.
rem Para rodar sempre ao ligar o PC: Win+R, digite shell:startup e coloque um atalho deste arquivo la.
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0ganwalk-stats.ps1"
