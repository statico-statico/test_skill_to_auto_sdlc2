@echo off
rem ==============================================================================
rem Script: validate-rally-fields.bat
rem Propósito: Validar la integridad de los campos extraídos de Rally WSAPI y
rem            comprobar las reglas de la máquina de estados antes de procesar (Windows Batch).
rem Códigos de salida:
rem   0 - Validación exitosa (Listo para procesar)
rem   1 - Error de campos requeridos faltantes o malformados
rem   2 - Error crítico: Artefacto en estado 'Accepted' (Inmutable, abortar)
rem   3 - Advertencia: Artefacto en estado 'Completed' (Requiere confirmación humana)
rem ==============================================================================

setlocal EnableDelayedExpansion

set "INPUT_FILE=%~1"

if "%INPUT_FILE%"=="" (
    echo ERROR: Debe proporcionar un archivo JSON como parametro. >&2
    echo Uso: %~nx0 ^<rally-payload.json^> >&2
    exit /b 1
)

if not exist "%INPUT_FILE%" (
    echo ERROR: El archivo '%INPUT_FILE%' no existe. >&2
    exit /b 1
)

echo ==^> Validando artefacto Rally...

rem Extraer campos clave utilizando PowerShell de forma nativa en Windows
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "$c = Get-Content -Raw -Path '%INPUT_FILE%' | ConvertFrom-Json; Write-Output $c.FormattedID" 2^>nul`) do (
    set "FORMATTED_ID=%%v"
)

for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "$c = Get-Content -Raw -Path '%INPUT_FILE%' | ConvertFrom-Json; Write-Output $c.Name" 2^>nul`) do (
    set "NAME=%%v"
)

for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "$c = Get-Content -Raw -Path '%INPUT_FILE%' | ConvertFrom-Json; Write-Output $c.ScheduleState" 2^>nul`) do (
    set "SCHEDULE_STATE=%%v"
)

rem 1. Validar presencia de FormattedID y formato
if "%FORMATTED_ID%"=="" (
    echo [ERROR]: El campo 'FormattedID' es obligatorio y no fue encontrado. >&2
    exit /b 1
)

for /f "tokens=*" %%m in ('powershell -NoProfile -Command "if ('%FORMATTED_ID%' -match '^(US|DE)[0-9]+$') { 'VALID' } else { 'INVALID' }"') do (
    if "%%m"=="INVALID" (
        echo [ADVERTENCIA]: 'FormattedID' ^(%FORMATTED_ID%^) no coincide con el formato estandar ^(US12345 o DE12345^). >&2
    )
)

rem 2. Validar presencia de Name / Título
if "%NAME%"=="" (
    echo [ERROR]: El campo 'Name' ^(titulo de la historia^) esta vacio. >&2
    exit /b 1
)

rem 3. Validar ScheduleState
if "%SCHEDULE_STATE%"=="" (
    echo [ADVERTENCIA]: 'ScheduleState' no definido. Se asume 'Defined'. >&2
    set "SCHEDULE_STATE=Defined"
)

echo     - FormattedID:    %FORMATTED_ID%
echo     - Name:           %NAME%
echo     - ScheduleState:  %SCHEDULE_STATE%

if /i "%SCHEDULE_STATE%"=="Accepted" (
    echo [ERROR CRITICO] [Codigo 2]: El artefacto %FORMATTED_ID% ya se encuentra en estado 'Accepted'. >&2
    echo     Las historias aceptadas por el Product Owner son inmutables por politica de auditoria. >&2
    echo     ABORTANDO proceso. >&2
    exit /b 2
)

if /i "%SCHEDULE_STATE%"=="Completed" (
    echo [ADVERTENCIA] [Codigo 3]: El artefacto %FORMATTED_ID% ya figura como 'Completed'. >&2
    echo     Se requiere confirmacion humana explicita para reprocesar o reabrir el desarrollo. >&2
    exit /b 3
)

if /i "%SCHEDULE_STATE%"=="Defined" (
    echo [OK]: Artefacto listo. Transicionara de 'Defined' -^> 'In-Progress'.
    exit /b 0
)

if /i "%SCHEDULE_STATE%"=="In-Progress" (
    echo [OK]: Artefacto en curso ^('In-Progress'^). Continuando desarrollo.
    exit /b 0
)

echo [ADVERTENCIA]: Estado '%SCHEDULE_STATE%' no estandar pero procesable.
exit /b 0
