#!/bin/bash
# detect-stack.sh — Detects the project's technology stack
# Used by the SDLC Automation Agent to adapt test/lint commands
# This script is READ-ONLY and safe to execute without side effects.

set -euo pipefail

echo "=== SDLC Stack Detection ==="
echo ""

DETECTED_STACKS=""
DETECTED_TEST_CMD=""
DETECTED_LINT_CMD=""
DETECTED_PACKAGE_MANAGER=""

# --- Node.js / JavaScript / TypeScript ---
if [ -f "package.json" ]; then
    DETECTED_STACKS="${DETECTED_STACKS}nodejs,"
    echo "STACK:nodejs"

    # Detect package manager
    if [ -f "pnpm-lock.yaml" ]; then
        DETECTED_PACKAGE_MANAGER="pnpm"
        echo "PACKAGE_MANAGER:pnpm"
    elif [ -f "yarn.lock" ]; then
        DETECTED_PACKAGE_MANAGER="yarn"
        echo "PACKAGE_MANAGER:yarn"
    elif [ -f "bun.lockb" ]; then
        DETECTED_PACKAGE_MANAGER="bun"
        echo "PACKAGE_MANAGER:bun"
    else
        DETECTED_PACKAGE_MANAGER="npm"
        echo "PACKAGE_MANAGER:npm"
    fi

    # Detect TypeScript
    if [ -f "tsconfig.json" ]; then
        echo "LANG:typescript"
    else
        echo "LANG:javascript"
    fi

    # Detect test framework
    if grep -q '"vitest"' package.json 2>/dev/null; then
        DETECTED_TEST_CMD="${DETECTED_PACKAGE_MANAGER} run test"
        echo "TEST_FRAMEWORK:vitest"
    elif grep -q '"jest"' package.json 2>/dev/null; then
        DETECTED_TEST_CMD="${DETECTED_PACKAGE_MANAGER} run test"
        echo "TEST_FRAMEWORK:jest"
    elif grep -q '"mocha"' package.json 2>/dev/null; then
        DETECTED_TEST_CMD="${DETECTED_PACKAGE_MANAGER} run test"
        echo "TEST_FRAMEWORK:mocha"
    else
        DETECTED_TEST_CMD="${DETECTED_PACKAGE_MANAGER} test"
        echo "TEST_FRAMEWORK:unknown (defaulting to npm test)"
    fi

    # Detect linter
    if grep -q '"eslint"' package.json 2>/dev/null; then
        DETECTED_LINT_CMD="npx eslint ."
        echo "LINTER:eslint"
    elif grep -q '"biome"' package.json 2>/dev/null; then
        DETECTED_LINT_CMD="npx biome check ."
        echo "LINTER:biome"
    fi

    # Detect framework
    if grep -q '"next"' package.json 2>/dev/null; then
        echo "FRAMEWORK:nextjs"
    elif grep -q '"nuxt"' package.json 2>/dev/null; then
        echo "FRAMEWORK:nuxt"
    elif grep -q '"react"' package.json 2>/dev/null; then
        echo "FRAMEWORK:react"
    elif grep -q '"vue"' package.json 2>/dev/null; then
        echo "FRAMEWORK:vue"
    elif grep -q '"angular"' package.json 2>/dev/null; then
        echo "FRAMEWORK:angular"
    elif grep -q '"express"' package.json 2>/dev/null; then
        echo "FRAMEWORK:express"
    elif grep -q '"fastify"' package.json 2>/dev/null; then
        echo "FRAMEWORK:fastify"
    fi
fi

# --- Python ---
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ] || [ -f "requirements.txt" ]; then
    DETECTED_STACKS="${DETECTED_STACKS}python,"
    echo "STACK:python"

    # Detect package manager
    if [ -f "pyproject.toml" ] && grep -q "poetry" pyproject.toml 2>/dev/null; then
        DETECTED_PACKAGE_MANAGER="poetry"
        echo "PACKAGE_MANAGER:poetry"
    elif [ -f "Pipfile" ]; then
        DETECTED_PACKAGE_MANAGER="pipenv"
        echo "PACKAGE_MANAGER:pipenv"
    elif [ -f "pyproject.toml" ] && grep -q "uv" pyproject.toml 2>/dev/null; then
        DETECTED_PACKAGE_MANAGER="uv"
        echo "PACKAGE_MANAGER:uv"
    else
        DETECTED_PACKAGE_MANAGER="pip"
        echo "PACKAGE_MANAGER:pip"
    fi

    # Detect test framework
    if [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
        DETECTED_TEST_CMD="pytest"
        echo "TEST_FRAMEWORK:pytest"
    elif [ -f "setup.cfg" ] && grep -q "pytest" setup.cfg 2>/dev/null; then
        DETECTED_TEST_CMD="pytest"
        echo "TEST_FRAMEWORK:pytest"
    else
        DETECTED_TEST_CMD="python -m pytest"
        echo "TEST_FRAMEWORK:pytest (default)"
    fi

    # Detect linter
    if [ -f "pyproject.toml" ] && grep -q "ruff" pyproject.toml 2>/dev/null; then
        DETECTED_LINT_CMD="ruff check ."
        echo "LINTER:ruff"
    elif [ -f ".flake8" ] || ([ -f "setup.cfg" ] && grep -q "flake8" setup.cfg 2>/dev/null); then
        DETECTED_LINT_CMD="flake8 ."
        echo "LINTER:flake8"
    fi

    # Detect framework
    if [ -f "pyproject.toml" ] && grep -q "django" pyproject.toml 2>/dev/null; then
        echo "FRAMEWORK:django"
    elif [ -f "pyproject.toml" ] && grep -q "fastapi" pyproject.toml 2>/dev/null; then
        echo "FRAMEWORK:fastapi"
    elif [ -f "pyproject.toml" ] && grep -q "flask" pyproject.toml 2>/dev/null; then
        echo "FRAMEWORK:flask"
    fi
fi

# --- .NET / C# ---
if ls *.csproj 1>/dev/null 2>&1 || ls **/*.csproj 1>/dev/null 2>&1; then
    DETECTED_STACKS="${DETECTED_STACKS}dotnet,"
    echo "STACK:dotnet"
    DETECTED_TEST_CMD="dotnet test"
    DETECTED_LINT_CMD="dotnet format --verify-no-changes"
    echo "TEST_CMD:dotnet test"
    echo "LINT_CMD:dotnet format"
fi

# --- Java ---
if [ -f "pom.xml" ]; then
    DETECTED_STACKS="${DETECTED_STACKS}java-maven,"
    echo "STACK:java"
    echo "BUILD_TOOL:maven"
    DETECTED_TEST_CMD="mvn test"
    echo "TEST_CMD:mvn test"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    DETECTED_STACKS="${DETECTED_STACKS}java-gradle,"
    echo "STACK:java"
    echo "BUILD_TOOL:gradle"
    DETECTED_TEST_CMD="./gradlew test"
    echo "TEST_CMD:./gradlew test"
fi

# --- Go ---
if [ -f "go.mod" ]; then
    DETECTED_STACKS="${DETECTED_STACKS}golang,"
    echo "STACK:golang"
    DETECTED_TEST_CMD="go test ./..."
    DETECTED_LINT_CMD="golangci-lint run"
    echo "TEST_CMD:go test ./..."
    echo "LINT_CMD:golangci-lint run"
fi

# --- Rust ---
if [ -f "Cargo.toml" ]; then
    DETECTED_STACKS="${DETECTED_STACKS}rust,"
    echo "STACK:rust"
    DETECTED_TEST_CMD="cargo test"
    DETECTED_LINT_CMD="cargo clippy"
    echo "TEST_CMD:cargo test"
    echo "LINT_CMD:cargo clippy"
fi

# --- Summary ---
echo ""
echo "=== Detection Summary ==="
if [ -z "$DETECTED_STACKS" ]; then
    echo "WARNING: No known stack detected. Manual configuration required."
else
    echo "DETECTED_STACKS:${DETECTED_STACKS%,}"
fi

if [ -n "$DETECTED_TEST_CMD" ]; then
    echo "RECOMMENDED_TEST_CMD:${DETECTED_TEST_CMD}"
fi

if [ -n "$DETECTED_LINT_CMD" ]; then
    echo "RECOMMENDED_LINT_CMD:${DETECTED_LINT_CMD}"
fi
