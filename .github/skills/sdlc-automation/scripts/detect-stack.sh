#!/usr/bin/env bash
# ==============================================================================
# Script: detect-stack.sh
# Propósito: Detectar automáticamente el stack tecnológico (Python o Java),
#            gestor de paquetes, comando de pruebas y linter del proyecto.
# Salida: Pares clave-valor formateados para fácil consumo por scripts y agentes.
# ==============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

STACK="unknown"
PACKAGE_MANAGER="none"
TEST_CMD="echo 'No test command detected'"
LINT_CMD="echo 'No lint command detected'"
BUILD_CMD="echo 'No build command detected'"
RUNTIME_VERSION=""

# ------------------------------------------------------------------------------
# 1. Detección de Python
# ------------------------------------------------------------------------------
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ] || [ -f "setup.py" ]; then
    STACK="python"

    if [ -f "poetry.lock" ]; then
        PACKAGE_MANAGER="poetry"
        TEST_CMD="poetry run pytest"
        LINT_CMD="poetry run ruff check . || poetry run flake8"
        BUILD_CMD="poetry build"
    elif [ -f "Pipfile" ]; then
        PACKAGE_MANAGER="pipenv"
        TEST_CMD="pipenv run pytest"
        LINT_CMD="pipenv run flake8"
        BUILD_CMD="pipenv lock"
    else
        PACKAGE_MANAGER="pip"
        if command -v pytest >/dev/null 2>&1 || grep -qi "pytest" pyproject.toml 2>/dev/null || grep -qi "pytest" requirements.txt 2>/dev/null; then
            TEST_CMD="pytest"
        else
            TEST_CMD="python -m unittest discover"
        fi
        LINT_CMD="ruff check . 2>/dev/null || flake8 2>/dev/null || true"
        BUILD_CMD="python -m build 2>/dev/null || true"
    fi

    if command -v python3 >/dev/null 2>&1; then
        RUNTIME_VERSION=$(python3 --version 2>/dev/null || echo "")
    elif command -v python >/dev/null 2>&1; then
        RUNTIME_VERSION=$(python --version 2>/dev/null || echo "")
    fi

# ------------------------------------------------------------------------------
# 2. Detección de Java (Maven)
# ------------------------------------------------------------------------------
elif [ -f "pom.xml" ]; then
    STACK="java-maven"
    PACKAGE_MANAGER="maven"
    TEST_CMD="mvn test"
    LINT_CMD="mvn checkstyle:check"
    BUILD_CMD="mvn clean compile"

    if command -v java >/dev/null 2>&1; then
        RUNTIME_VERSION=$(java -version 2>&1 | head -n 1)
    fi

# ------------------------------------------------------------------------------
# 3. Detección de Java (Gradle)
# ------------------------------------------------------------------------------
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    STACK="java-gradle"
    PACKAGE_MANAGER="gradle"
    if [ -f "./gradlew" ]; then
        TEST_CMD="./gradlew test"
        BUILD_CMD="./gradlew build"
        LINT_CMD="./gradlew check"
    else
        TEST_CMD="gradle test"
        BUILD_CMD="gradle build"
        LINT_CMD="gradle check"
    fi

    if command -v java >/dev/null 2>&1; then
        RUNTIME_VERSION=$(java -version 2>&1 | head -n 1)
    fi
fi

# ------------------------------------------------------------------------------
# Emisión estructurada de resultados
# ------------------------------------------------------------------------------
cat <<EOF
STACK=$STACK
PACKAGE_MANAGER=$PACKAGE_MANAGER
TEST_CMD=$TEST_CMD
LINT_CMD=$LINT_CMD
BUILD_CMD=$BUILD_CMD
RUNTIME_VERSION=$RUNTIME_VERSION
EOF
