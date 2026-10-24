@echo off
rem ==============================================================================
rem Script: detect-stack.bat
rem Propósito: Detectar automáticamente el stack tecnológico (Python o Java),
rem            gestor de paquetes, comando de pruebas y linter del proyecto (Windows Batch).
rem Salida: Pares clave-valor formateados para fácil consumo por scripts y agentes.
rem ==============================================================================

setlocal EnableDelayedExpansion

set "TARGET_DIR=%~1"
if not "%TARGET_DIR%"=="" (
    cd /d "%TARGET_DIR%" 2>nul
)

set "STACK=unknown"
set "PACKAGE_MANAGER=none"
set "TEST_CMD=echo 'No test command detected'"
set "LINT_CMD=echo 'No lint command detected'"
set "BUILD_CMD=echo 'No build command detected'"
set "RUNTIME_VERSION="

rem ------------------------------------------------------------------------------
rem 1. Detección de Python
rem ------------------------------------------------------------------------------
set "IS_PYTHON=0"
if exist "pyproject.toml" set "IS_PYTHON=1"
if exist "requirements.txt" set "IS_PYTHON=1"
if exist "Pipfile" set "IS_PYTHON=1"
if exist "setup.py" set "IS_PYTHON=1"

if "%IS_PYTHON%"=="1" (
    set "STACK=python"

    if exist "poetry.lock" (
        set "PACKAGE_MANAGER=poetry"
        set "TEST_CMD=poetry run pytest"
        set "LINT_CMD=poetry run ruff check . || poetry run flake8"
        set "BUILD_CMD=poetry build"
    ) else if exist "Pipfile" (
        set "PACKAGE_MANAGER=pipenv"
        set "TEST_CMD=pipenv run pytest"
        set "LINT_CMD=pipenv run flake8"
        set "BUILD_CMD=pipenv lock"
    ) else (
        set "PACKAGE_MANAGER=pip"
        set "TEST_CMD=python -m unittest discover"
        where pytest >nul 2>&1
        if !errorlevel! equ 0 set "TEST_CMD=pytest"
        if exist "pyproject.toml" (
            findstr /i /c:"pytest" pyproject.toml >nul 2>&1
            if !errorlevel! equ 0 set "TEST_CMD=pytest"
        )
        if exist "requirements.txt" (
            findstr /i /c:"pytest" requirements.txt >nul 2>&1
            if !errorlevel! equ 0 set "TEST_CMD=pytest"
        )
        set "LINT_CMD=ruff check . 2>nul || flake8 2>nul || ver >nul"
        set "BUILD_CMD=python -m build 2>nul || ver >nul"
    )

    where python >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('python --version 2^>nul') do set "RUNTIME_VERSION=%%v"
    ) else (
        where python3 >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "tokens=*" %%v in ('python3 --version 2^>nul') do set "RUNTIME_VERSION=%%v"
        )
    )
    goto :EMIT_RESULT
)

rem ------------------------------------------------------------------------------
rem 2. Detección de Java (Maven)
rem ------------------------------------------------------------------------------
if exist "pom.xml" (
    set "STACK=java-maven"
    set "PACKAGE_MANAGER=maven"
    set "TEST_CMD=mvn test"
    set "LINT_CMD=mvn checkstyle:check"
    set "BUILD_CMD=mvn clean compile"
    where java >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('java -version 2^>^&1') do (
            if not defined RUNTIME_VERSION set "RUNTIME_VERSION=%%v"
        )
    )
    goto :EMIT_RESULT
)

rem ------------------------------------------------------------------------------
rem 3. Detección de Java (Gradle)
rem ------------------------------------------------------------------------------
set "IS_GRADLE=0"
if exist "build.gradle" set "IS_GRADLE=1"
if exist "build.gradle.kts" set "IS_GRADLE=1"

if "%IS_GRADLE%"=="1" (
    set "STACK=java-gradle"
    set "PACKAGE_MANAGER=gradle"
    if exist "gradlew.bat" (
        set "TEST_CMD=gradlew.bat test"
        set "BUILD_CMD=gradlew.bat build"
        set "LINT_CMD=gradlew.bat check"
    ) else (
        set "TEST_CMD=gradle test"
        set "BUILD_CMD=gradle build"
        set "LINT_CMD=gradle check"
    )
    where java >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('java -version 2^>^&1') do (
            if not defined RUNTIME_VERSION set "RUNTIME_VERSION=%%v"
        )
    )
    goto :EMIT_RESULT
)

:EMIT_RESULT
echo STACK=%STACK%
echo PACKAGE_MANAGER=%PACKAGE_MANAGER%
echo TEST_CMD=%TEST_CMD%
echo LINT_CMD=%LINT_CMD%
echo BUILD_CMD=%BUILD_CMD%
echo RUNTIME_VERSION=%RUNTIME_VERSION%

endlocal
exit /b 0
