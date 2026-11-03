@rem Batch / INICIAR_CLIENT.bat / Windows 10-11 / direct startup with automatic archive extraction
@echo off
setlocal
cd /d "%~dp0"
if exist "DisneyClient\server.py" if exist "DisneyClient\requirements.txt" if exist "DisneyParser\main.py" goto launch
echo Preparando a pasta completa do client...
set "DISNEY_STARTER_DIR=%~dp0"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $base=Join-Path $env:LOCALAPPDATA 'DisneyClientFisica-v1'; $project=Join-Path $base 'DisneyClient-Completo'; if (!(Test-Path (Join-Path $project 'DisneyClient/server.py')) -or !(Test-Path (Join-Path $project 'DisneyParser/main.py'))) { $folders=@($env:DISNEY_STARTER_DIR,(Join-Path $env:USERPROFILE 'Downloads'),(Join-Path $env:USERPROFILE 'Desktop')); $archive=$folders | ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter 'DisneyClient-Completo-Fisica*.zip' -File -ErrorAction SilentlyContinue } | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if (!$archive) { throw 'Baixe DisneyClient-Completo-Fisica.zip e mantenha o nome do arquivo. Extraia o ZIP inteiro e abra INICIAR_CLIENT.bat.' }; New-Item -ItemType Directory -Path $base -Force | Out-Null; Expand-Archive -LiteralPath $archive.FullName -DestinationPath $base -Force }; Start-Process -FilePath (Join-Path $project 'INICIAR_CLIENT.bat') -WorkingDirectory $project"
if errorlevel 1 (
    echo Nao foi possivel preparar o client. Leia a mensagem acima.
    pause
    exit /b 1
)
exit /b 0
:launch
where py >nul 2>nul
if not errorlevel 1 (
    py -3 iniciar_client.py
    goto result
)
where python >nul 2>nul
if not errorlevel 1 (
    python iniciar_client.py
    goto result
)
echo Instale Python 3.11 ou superior: https://www.python.org/downloads/windows/
pause
exit /b 1
:result
if errorlevel 1 (
    echo.
    echo O client nao iniciou. Leia a mensagem acima.
    pause
    exit /b 1
)
exit /b 0
