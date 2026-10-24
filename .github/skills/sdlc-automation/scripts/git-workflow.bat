@echo off
rem ==============================================================================
rem Script: git-workflow.bat
rem Propósito: Automatizar el flujo completo de Git y GitLab CLI en Windows:
rem            Creación de rama, commit semántico, push remoto y generación de MR Draft.
rem Parámetros:
rem   %1 - Rally FormattedID (ej. US10293)
rem   %2 - Título del requerimiento (ej. "Implement Session Timeout Warning")
rem   %3 - Rama destino (opcional, por defecto: main)
rem   %4 - Archivo de descripción del MR (opcional, por defecto: .docs\report.md)
rem ==============================================================================

setlocal EnableDelayedExpansion

set "FORMATTED_ID=%~1"
set "TITLE=%~2"
set "TARGET_BRANCH=%~3"
if "%TARGET_BRANCH%"=="" set "TARGET_BRANCH=main"
set "DESC_FILE=%~4"
if "%DESC_FILE%"=="" set "DESC_FILE=.docs\report.md"

if "%FORMATTED_ID%"=="" (
    echo ERROR: Parametros obligatorios faltantes. >&2
    echo Uso: %~nx0 ^<FormattedID^> ^<Title^> [TargetBranch] [DescriptionFile] >&2
    exit /b 1
)

if "%TITLE%"=="" (
    echo ERROR: Parametros obligatorios faltantes. >&2
    echo Uso: %~nx0 ^<FormattedID^> ^<Title^> [TargetBranch] [DescriptionFile] >&2
    exit /b 1
)

rem 1. Validar que git está inicializado
git rev-parse --is-inside-work-tree >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: El directorio actual no es un repositorio Git valido. >&2
    exit /b 1
)

rem 2. Validar archivo de descripción
if not exist "%DESC_FILE%" (
    if exist ".docs\mr-description.md" (
        set "DESC_FILE=.docs\mr-description.md"
    ) else (
        echo ADVERTENCIA: Archivo de reporte %DESC_FILE% no encontrado. Se creara descripcion minima. >&2
        if not exist ".docs" mkdir ".docs"
        (
            echo # feat^(%FORMATTED_ID%^): %TITLE%
            echo.
            echo Automatizacion SDLC completada por Copilot Agent.
            echo Rally ID: %FORMATTED_ID%
        ) > ".docs\temp-mr-desc.md"
        set "DESC_FILE=.docs\temp-mr-desc.md"
    )
)

rem 3. Generar slug normalizado para la rama
for /f "usebackq delims=" %%s in (`powershell -NoProfile -Command "$t = '%TITLE%'.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-+|-+$', ''; if ($t.Length -gt 40) { $t = $t.Substring(0, 40) }; $t"`) do (
    set "CLEAN_TITLE=%%s"
)
if "%CLEAN_TITLE%"=="" set "CLEAN_TITLE=update"
set "BRANCH_NAME=feature/%FORMATTED_ID%-%CLEAN_TITLE%"

echo ==^> Creando rama de trabajo: %BRANCH_NAME%
git checkout -B "%BRANCH_NAME%"

rem 4. Preparar y crear commit semántico
echo ==^> Registrando cambios locales...
git add .

git diff-index --quiet HEAD -- 2>nul
if !errorlevel! equ 0 (
    echo AVISO: No se detectaron modificaciones nuevas en el arbol de trabajo para commitear.
) else (
    set "COMMIT_MSG=feat(%FORMATTED_ID%): %TITLE%"
    (
        echo feat^(%FORMATTED_ID%^): %TITLE%
        echo.
        echo - Implementa requerimientos aprobados de Rally %FORMATTED_ID%
        echo - Especificaciones: .docs/requerimientos.md
        echo - Diseno tecnico: .docs/diseno.md
        echo - Trazabilidad cruzada bidireccional
        echo.
        echo Rally-Issue: %FORMATTED_ID%
    ) > "%TEMP%\sdlc_commit_msg.txt"

    git commit -F "%TEMP%\sdlc_commit_msg.txt"
    del "%TEMP%\sdlc_commit_msg.txt" 2>nul
    echo ==^> Commit generado con exito.
)

rem 5. Publicar rama en remoto
echo ==^> Publicando rama en origen...
git remote | findstr /c:"origin" >nul 2>&1
if !errorlevel! equ 0 (
    git push -u origin HEAD
) else (
    echo AVISO: No se detecto un remote 'origin'. Omitiendo 'git push'. >&2
)

rem 6. Crear Merge Request en GitLab vía glab CLI
echo ==^> Creando Merge Request en GitLab con glab CLI...
where glab >nul 2>&1
if !errorlevel! equ 0 (
    for /f "usebackq delims=" %%o in (`glab mr create --title "feat(%FORMATTED_ID%): %TITLE%" --description-file "%DESC_FILE%" --target-branch "%TARGET_BRANCH%" --source-branch "%BRANCH_NAME%" --draft --assignee @me --label "bot-generated,%FORMATTED_ID%" --yes 2^>^&1`) do (
        echo %%o
        for /f "tokens=*" %%u in ('powershell -NoProfile -Command "if ('%%o' -match 'https?://[^\s]+/merge_requests/(\d+)') { $matches[0] }"') do (
            set "MR_URL=%%u"
        )
        for /f "tokens=*" %%i in ('powershell -NoProfile -Command "if ('%%o' -match '/merge_requests/(\d+)') { $matches[1] }"') do (
            set "MR_IID=%%i"
        )
    )

    if defined MR_IID (
        echo ==^> Anadiendo nota tecnica automatizada al MR #!MR_IID!...
        glab mr note create "!MR_IID!" -m "## 🤖 Reporte de Validación Automatizada`n- **Rally Story:** %FORMATTED_ID%`n- **Documentación de Especificación:** \`.docs/requerimientos.md\` y \`.docs/diseno.md\`\`n- **Reporte Post-Tarea:** \`.docs/report.md\`\`n`nMerge Request generado en modo borrador (**Draft**) a la espera de aprobación humana." >nul 2>&1
    )

    echo.
    echo ================================================================================
    echo RESULTADO DEL FLUJO GIT:
    echo BRANCH_NAME=%BRANCH_NAME%
    if defined MR_URL (
        echo MR_URL=!MR_URL!
    ) else (
        echo MR_URL=No disponible / Pendiente de verificacion
    )
    if defined MR_IID (
        echo MR_IID=!MR_IID!
    ) else (
        echo MR_IID=N/A
    )
    echo ================================================================================
) else (
    echo ADVERTENCIA: El binario 'glab' no esta disponible en el entorno. >&2
    echo La rama '%BRANCH_NAME%' fue creada localmente. >&2
)

endlocal
exit /b 0
