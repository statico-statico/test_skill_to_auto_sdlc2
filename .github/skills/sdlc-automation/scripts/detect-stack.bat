@echo off
REM detect-stack.bat — Detects the project's technology stack (Windows version)
REM Used by the SDLC Automation Agent to adapt test/lint commands
REM This script is READ-ONLY and safe to execute without side effects.

echo === SDLC Stack Detection ===
echo.

set "DETECTED_STACKS="
set "DETECTED_TEST_CMD="
set "DETECTED_LINT_CMD="
set "DETECTED_PACKAGE_MANAGER="

REM --- Node.js / JavaScript / TypeScript ---
if exist "package.json" (
    set "DETECTED_STACKS=%DETECTED_STACKS%nodejs,"
    echo STACK:nodejs

    REM Detect package manager
    if exist "pnpm-lock.yaml" (
        set "DETECTED_PACKAGE_MANAGER=pnpm"
        echo PACKAGE_MANAGER:pnpm
    ) else if exist "yarn.lock" (
        set "DETECTED_PACKAGE_MANAGER=yarn"
        echo PACKAGE_MANAGER:yarn
    ) else if exist "bun.lockb" (
        set "DETECTED_PACKAGE_MANAGER=bun"
        echo PACKAGE_MANAGER:bun
    ) else (
        set "DETECTED_PACKAGE_MANAGER=npm"
        echo PACKAGE_MANAGER:npm
    )

    REM Detect TypeScript
    if exist "tsconfig.json" (
        echo LANG:typescript
    ) else (
        echo LANG:javascript
    )

    REM Detect test framework
    findstr /C:"vitest" package.json >nul 2>&1
    if not errorlevel 1 (
        set "DETECTED_TEST_CMD=npm run test"
        echo TEST_FRAMEWORK:vitest
    ) else (
        findstr /C:"jest" package.json >nul 2>&1
        if not errorlevel 1 (
            set "DETECTED_TEST_CMD=npm run test"
            echo TEST_FRAMEWORK:jest
        ) else (
            findstr /C:"mocha" package.json >nul 2>&1
            if not errorlevel 1 (
                set "DETECTED_TEST_CMD=npm run test"
                echo TEST_FRAMEWORK:mocha
            ) else (
                set "DETECTED_TEST_CMD=npm test"
                echo TEST_FRAMEWORK:unknown
            )
        )
    )

    REM Detect linter
    findstr /C:"eslint" package.json >nul 2>&1
    if not errorlevel 1 (
        set "DETECTED_LINT_CMD=npx eslint ."
        echo LINTER:eslint
    ) else (
        findstr /C:"biome" package.json >nul 2>&1
        if not errorlevel 1 (
            set "DETECTED_LINT_CMD=npx biome check ."
            echo LINTER:biome
        )
    )

    REM Detect framework
    findstr /C:"next" package.json >nul 2>&1
    if not errorlevel 1 echo FRAMEWORK:nextjs
    findstr /C:"react" package.json >nul 2>&1
    if not errorlevel 1 echo FRAMEWORK:react
    findstr /C:"vue" package.json >nul 2>&1
    if not errorlevel 1 echo FRAMEWORK:vue
    findstr /C:"angular" package.json >nul 2>&1
    if not errorlevel 1 echo FRAMEWORK:angular
    findstr /C:"express" package.json >nul 2>&1
    if not errorlevel 1 echo FRAMEWORK:express
)

REM --- Python ---
if exist "pyproject.toml" (
    set "DETECTED_STACKS=%DETECTED_STACKS%python,"
    echo STACK:python
    set "DETECTED_TEST_CMD=python -m pytest"
    echo TEST_CMD:python -m pytest
)
if exist "setup.py" (
    if not defined DETECTED_STACKS (
        set "DETECTED_STACKS=%DETECTED_STACKS%python,"
        echo STACK:python
    )
    set "DETECTED_TEST_CMD=python -m pytest"
)
if exist "requirements.txt" (
    if not defined DETECTED_STACKS (
        set "DETECTED_STACKS=%DETECTED_STACKS%python,"
        echo STACK:python
    )
    set "DETECTED_TEST_CMD=python -m pytest"
)

REM --- .NET / C# ---
if exist "*.csproj" (
    set "DETECTED_STACKS=%DETECTED_STACKS%dotnet,"
    echo STACK:dotnet
    set "DETECTED_TEST_CMD=dotnet test"
    set "DETECTED_LINT_CMD=dotnet format --verify-no-changes"
    echo TEST_CMD:dotnet test
    echo LINT_CMD:dotnet format
)

REM --- Java ---
if exist "pom.xml" (
    set "DETECTED_STACKS=%DETECTED_STACKS%java-maven,"
    echo STACK:java
    echo BUILD_TOOL:maven
    set "DETECTED_TEST_CMD=mvn test"
    echo TEST_CMD:mvn test
)
if exist "build.gradle" (
    set "DETECTED_STACKS=%DETECTED_STACKS%java-gradle,"
    echo STACK:java
    echo BUILD_TOOL:gradle
    set "DETECTED_TEST_CMD=gradlew test"
    echo TEST_CMD:gradlew test
)
if exist "build.gradle.kts" (
    if not defined DETECTED_STACKS (
        set "DETECTED_STACKS=%DETECTED_STACKS%java-gradle,"
        echo STACK:java
        echo BUILD_TOOL:gradle
        set "DETECTED_TEST_CMD=gradlew test"
        echo TEST_CMD:gradlew test
    )
)

REM --- Go ---
if exist "go.mod" (
    set "DETECTED_STACKS=%DETECTED_STACKS%golang,"
    echo STACK:golang
    set "DETECTED_TEST_CMD=go test ./..."
    set "DETECTED_LINT_CMD=golangci-lint run"
    echo TEST_CMD:go test ./...
    echo LINT_CMD:golangci-lint run
)

REM --- Rust ---
if exist "Cargo.toml" (
    set "DETECTED_STACKS=%DETECTED_STACKS%rust,"
    echo STACK:rust
    set "DETECTED_TEST_CMD=cargo test"
    set "DETECTED_LINT_CMD=cargo clippy"
    echo TEST_CMD:cargo test
    echo LINT_CMD:cargo clippy
)

REM --- Summary ---
echo.
echo === Detection Summary ===
if "%DETECTED_STACKS%"=="" (
    echo WARNING: No known stack detected. Manual configuration required.
) else (
    echo DETECTED_STACKS:%DETECTED_STACKS:~0,-1%
)

if not "%DETECTED_TEST_CMD%"=="" (
    echo RECOMMENDED_TEST_CMD:%DETECTED_TEST_CMD%
)

if not "%DETECTED_LINT_CMD%"=="" (
    echo RECOMMENDED_LINT_CMD:%DETECTED_LINT_CMD%
)
