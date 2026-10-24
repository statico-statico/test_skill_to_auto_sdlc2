---
name: sdlc-automation
description: >
  End-to-end SDLC automation skill that transforms Rally issues into
  GitLab Merge Requests for Python and Java projects. Generates spec-driven documentation
  (requerimientos.md, diseño.md), implements code changes, executes tests (pytest/mvn/gradle),
  manages git workflows with glab CLI, and maintains bidirectional traceability between Rally and GitLab.
  Activate when user mentions Rally IDs like US12345, DE6789, or asks to
  "automate SDLC", "issue to PR", "rally to merge request".
license: proprietary
compatibility: >
  Requires glab CLI authenticated, Rally MCP server configured in
  .vscode/mcp.json, git initialized repository, Python 3.10+ or Java 17+.
allowed-tools: terminal codebase editFiles fetch mcp:rally-mcp
metadata:
  author: engineering-team
  version: "1.0.0"
  methodology: spec-driven-development
  supported-stacks: "Python, Java"
---

# SDLC Automation Skill — Procedimientos Operativos Estandarizados (SOP)

Este skill define la secuencia de operaciones autónomas que el orquestador ejecuta para transformar una historia de usuario o defecto de Broadcom Rally en un Merge Request verificado en GitLab para proyectos **Python** y **Java**, garantizando compuertas humanas en cada transición de fase.

---

## 0. Condiciones de Activación (Trigger Conditions)

Activar este skill cuando ocurra cualquiera de las siguientes condiciones:
1. El usuario mencione un identificador con formato de Rally: `US\d+` (Historia de Usuario) o `DE\d+` (Defecto).
2. El usuario solicite: *"automatiza este issue"*, *"de issue a PR"*, *"crea el MR para US..."*, o *"desarrolla la historia US..."*.
3. El agente orquestador `@sdlc-orchestrator` sea invocado con un identificador de tarea ágil.

---

## Fase 0: Descubrimiento de Contexto y Detección de Stack (Python / Java)

Antes de realizar cambios, el agente debe analizar el repositorio local para identificar el ecosistema tecnológico:

### Paso 0.1 — Detección Automática de Stack Tecnológico
Ejecutar el script utilitario `.github/skills/sdlc-automation/scripts/detect-stack.sh` (o `detect-stack.bat` en Windows) o evaluar la existencia de archivos indicadores:
- `pyproject.toml` / `requirements.txt` / `Pipfile` / `setup.py` → Ecosistema **Python**
  - Gestores soportados: Poetry, Pipenv, pip / venv.
  - Test runner: `pytest` / `poetry run pytest` / `python -m unittest discover`.
  - Linter / formateo: `ruff`, `black`, `flake8`.
- `pom.xml` → Ecosistema **Java (Maven)**
  - Gestor: Maven (`mvn`).
  - Test runner: `mvn test` (JUnit 5, TestNG).
  - Linter: `mvn checkstyle:check`, Spotless.
- `build.gradle` / `build.gradle.kts` → Ecosistema **Java (Gradle)**
  - Gestor: Gradle (`./gradlew` o `gradle`).
  - Test runner: `./gradlew test` (o `gradle test`).
  - Linter: `./gradlew check`.

### Paso 0.2 — Inspección de Convenciones del Repositorio
Mediante `#codebase`, identificar:
- Estructura de carpetas (`src/`, `tests/` o `src/main/java`, `src/test/java`).
- Estilo de tipado y formateo (type hints en Python, checkstyle en Java).
- Modelos de datos y capas de persistencia (SQLAlchemy, SQL / JPA / Hibernate).
- Patrones arquitectónicos predominantes (Clean Architecture, Hexagonal, MVC / Service Layer).

---

## Fase 1: Ingesta y Validación de Contexto desde Broadcom Rally

### Paso 1.1 — Consulta a Rally mediante Rally MCP
Utilizar las herramientas provistas por el servidor MCP `rally-mcp`:
1. Localizar la operación WSAPI mediante `rally_openapi_search_tools` para `HierarchicalRequirement` o `Defect`.
2. Invocar la herramienta con una consulta superficial (*Shallow Fetch*):
   ```text
   GET hierarchicalrequirement
     query: (FormattedID = "{ID}")
     fetch: FormattedID,ObjectID,Name,Description,AcceptanceCriteria,Notes,ScheduleState,Owner,Iteration,Project,Tags
   ```

### Paso 1.2 — Validación de Máquina de Estados (`ScheduleState`)
Evaluar el campo devuelto según las reglas de `references/rally-fields-map.md`:
- Si `ScheduleState == "Accepted"`:
  🛑 **ABORTAR INMEDIATAMENTE**: Informar al usuario que el requerimiento ya fue aceptado formalmente y es inmutable.
- Si `ScheduleState == "Completed"`:
  ⚠️ **ADVERTIR AL USUARIO**: Informar que la historia ya figuraba como completada y solicitar confirmación para reprocesarla.
- Si `ScheduleState == "Defined"`:
  ✅ **PROMOVER ESTADO**: Invocar `rally_openapi_invoke_tool` para actualizar `ScheduleState` a `"In-Progress"`.
- Si `ScheduleState == "In-Progress"`:
  ✅ **CONTINUAR**: Mantener el estado actual y proceder.

### Paso 1.3 — Depuración y Normalización de Textos
- Limpiar el contenido HTML de `Description` y `AcceptanceCriteria` aplicando las reglas de `references/rally-fields-map.md`.
- Desglosar los criterios de aceptación en afirmaciones verificables atómicas.

### 🚪 COMPUERTA HUMANA 1 (Gate 1: Contexto Rally)
Presentar al usuario el resumen del ticket para validación:
> *"He extraído y validado los datos de Rally para {FormattedID}:*  
> *- **Título:** {Name}*  
> *- **Criterios de Aceptación detectados:** {N} elementos*  
> *- **Transición de Estado:** {Estado_Anterior} ➔ In-Progress*  
> *¿Confirmas que el alcance es correcto para proceder a la fase de especificación?"*

**DETENERSE** y esperar aprobación explícita del usuario.

---

## Fase 2: Generación de Especificaciones Técnicas (Spec-Driven)

### Paso 2.1 — Generación de `.docs/requerimientos.md`
Utilizar la plantilla `.github/skills/sdlc-automation/templates/requerimientos.md`:
1. Formular la Historia de Usuario en formato ágil (`Como... Quiero... Para...`).
2. Traducir cada criterio de aceptación a **Notación EARS** obligatoria (consultar `references/ears-notation.md`):
   - Requisitos de Evento: `CUANDO..., EL SISTEMA DEBERÁ...`
   - Requisitos de Estado: `MIENTRAS..., EL SISTEMA DEBERÁ...`
   - Requisitos de Error / Negativos: `SI..., EL SISTEMA DEBERÁ...`
   - Requisitos Opcionales: `DONDE..., EL SISTEMA DEBERÁ...`
   - Requisitos Ubicuos: `EL SISTEMA DEBERÁ...`
3. Documentar Requisitos No Funcionales (Rendimiento, Seguridad, Disponibilidad).
4. Delimitar explícitamente lo que queda Fuera de Alcance (*Out of Scope*).

### Paso 2.2 — Generación de `.docs/diseño.md`
Analizar el `#codebase` y utilizar la plantilla `.github/skills/sdlc-automation/templates/diseño.md`:
1. Elaborar diagrama de arquitectura de componentes en sintaxis Mermaid.
2. **Arquitectura Obligatoria para Java (Hexagonal / Ports & Adapters):**
   - `domain/model/`: Entidades y Value Objects puros (POJOs/Records sin anotaciones Spring/JPA).
   - `domain/exception/`: Excepciones de reglas de negocio independientes del protocolo HTTP.
   - `application/port/in/`: Puertos primarios/driving (casos de uso) y comandos/resultados.
   - `application/port/out/`: Puertos secundarios/driven (interfaces para caché, base de datos SQL, clientes remotos).
   - `application/service/`: Servicios de aplicación que implementan los casos de uso orquestando el dominio y los puertos.
   - `infrastructure/adapter/in/web/`: Adaptadores HTTP/REST (controllers, DTOs, mappers, exception handlers).
   - `infrastructure/adapter/out/persistence/`: Adaptadores JPA/SQL que implementan los puertos de salida.
   - `infrastructure/adapter/out/cache/`: Adaptadores Redis u otros sistemas de almacenamiento volátil.
   - `infrastructure/config/`: Clases de configuración Spring para cableado e inyección de dependencias.
3. **Heurística Arquitectónica para Python (NO forzar Hexagonal):**
   - **Usar Hexagonal si:**
     - El proyecto tiene un dominio de negocio complejo y frecuentemente cambiante.
     - Se necesita implementar el núcleo de dominio (*core domain*) de la aplicación aislado de dependencias.
   - **NO usar Hexagonal si:**
     - El proyecto o módulo tiene complejidad de tipo CRUD — en dicho escenario no hay beneficios de la arquitectura hexagonal y resultará en sobreingeniería (*overengineering*).
     - En servicios estándar o tipo CRUD en Python, preferir la arquitectura modular por capas (`routers/`, `services/`, `models/schemas`, `repositories/db`).
4. Definir la lista precisa de archivos Python o Java a modificar y archivos nuevos a crear.
5. Especificar esquemas de datos, DTOs (Pydantic / POJOs), entidades SQL y contratos de interfaces/funciones.
6. Documentar decisiones de arquitectura clave (ADRs) con alternativas descartadas.
7. Diseñar la estrategia de pruebas (unitarias, integración, casos límite con pytest o JUnit 5).
8. Evaluar vectores de seguridad conforme a `references/quality-checklist.md`.
9. Diseñar el diagrama de secuencia Mermaid para el flujo principal.

### 🚪 COMPUERTA HUMANA 2 (Gate 2: Aprobación de Especificaciones)
Presentar ambos documentos al desarrollador:
> *"He generado las especificaciones técnicas en el directorio `.docs/`:*  
> *- `.docs/requerimientos.md` ({N} requisitos EARS formulados).*  
> *- `.docs/diseño.md` (Diagramas Mermaid, {M} archivos impactados).*  
> *Por favor, revisa y aprueba el diseño técnico antes de iniciar la escritura de código."*

**Opciones del usuario:**
- ✅ **Aprobado:** Continuar a la Fase 3.
- ⚠️ **Ajustes:** Modificar las secciones señaladas por el usuario y volver a presentar.
- ❌ **Rechazado:** Detener el flujo.

---

## Fase 3: Implementación de Código y Ciclo de Auto-Sanación

### Paso 3.1 — Escritura de Código Modular (Python / Java)
1. Modificar y crear los archivos definidos en `.docs/diseño.md`.
2. En Java, garantizar el aislamiento estricto de la capa de dominio: las clases en `domain/` y `application/` no deben acoplarse ni importar frameworks (`org.springframework.*`, `jakarta.persistence.*`).
3. Incluir en la cabecera de cada archivo afectado el comentario de trazabilidad:
   - En Python:
     ```python
     # Rally: {FormattedID} — Requisito EARS: {ID_REQUISITO}
     ```
   - En Java:
     ```java
     // Rally: {FormattedID} — Requisito EARS: {ID_REQUISITO}
     ```
4. Seguir estrictamente los principios SOLID y las directrices de `references/quality-checklist.md`.
5. Respetar el estilo y patrones existentes en el repositorio sin introducir dependencias redundantes.

### Paso 3.2 — Ejecución de Pruebas y Bucle de Auto-Sanación (Self-Healing Loop)
Ejecutar el comando de test correspondiente al stack detectado vía `#terminal`:
- **Python:** `pytest` (o `poetry run pytest` / `python -m unittest discover`).
- **Java:** `mvn test` (o `./gradlew test` / `gradle test`).

```text
iteracion = 0
MAX_ITERACIONES = 3

MIENTRAS los tests fallen Y iteracion < MAX_ITERACIONES:
  1. Capturar el volcado de error (traceback / stack trace) de la consola.
  2. Diagnosticar la causa raíz comparando con diseño.md y el código actual.
  3. Aplicar una corrección quirúrgica (NUNCA reescribir archivos enteros sin necesidad).
  4. Reejecutar la suite de pruebas.
  5. iteracion++

SI iteracion == MAX_ITERACIONES Y los tests aún fallan:
  🛑 DETENERSE y emitir un reporte detallado al usuario solicitando asistencia humana.
```

### Paso 3.3 — Verificación Estática de Calidad y OWASP
Comprobar contra `references/quality-checklist.md`:
- Ningún secreto ni credencial expuesta en archivos `.py`, `.java` ni ficheros de configuración (`application.yml`, `.env`).
- Entradas sanitizadas y tipadas (OWASP A03 Injection).
- Consultas SQL parametrizadas o mediante ORM seguro (SQLAlchemy, JPA).
- Control de acceso validado en lógica de negocio (OWASP A01).
- Cobertura de tests ≥ 80%.

### 🚪 COMPUERTA HUMANA 3 (Gate 3: Revisión de Implementación)
Presentar el balance técnico de los cambios:
> *"Implementación finalizada para {FormattedID}:*  
> *- Archivos modificados: {N} | Archivos nuevos: {M}*  
> *- Pruebas automatizadas: ✅ {PASS_COUNT}/{TOTAL_COUNT} en verde.*  
> *- Cobertura estimada: {COVERAGE}%.*  
> *¿Autorizas la creación de la rama Git y el Merge Request en GitLab?"*

**DETENERSE** y esperar confirmación del desarrollador.

---

## Fase 4: Control de Versiones y Merge Request en GitLab

### Paso 4.1 — Creación de Rama y Commit Convencional
Ejecutar mediante `#terminal`:
```bash
# Sanitizar título y crear rama descriptiva
BRANCH_SLUG=$(echo "{Title}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c 1-40)
BRANCH_NAME="feature/{FormattedID}-${BRANCH_SLUG}"
git checkout -b "$BRANCH_NAME"

# Añadir cambios y crear commit con formato semántico
git add .
git commit -m "feat({FormattedID}): {Title}

- Implementa requerimientos aprobados de Rally {FormattedID}
- Especificaciones: .docs/requerimientos.md
- Diseno tecnico: .docs/diseno.md
- Trazabilidad bidireccional Rally-GitLab

Rally-Issue: {FormattedID}"

# Publicar rama remota
git push -u origin HEAD
```

### Paso 4.2 — Generación del Reporte Final (`.docs/report.md`)
Generar `.docs/report.md` utilizando la plantilla `templates/report.md`:
- Resumen ejecutivo del trabajo realizado.
- Matriz de trazabilidad (Archivo ↔ Requisito EARS).
- Checklist SOLID y evaluación de seguridad OWASP.
- Resumen métrico de pruebas (`pytest` o JUnit) y registro de deuda técnica.

### Paso 4.3 — Creación del Merge Request en Modo Borrador (`glab mr create`)
Ejecutar el comando no interactivo conforme a `references/glab-commands.md`:
```bash
glab mr create \
  --title "feat({FormattedID}): {Title}" \
  --description-file .docs/report.md \
  --target-branch main \
  --source-branch "$BRANCH_NAME" \
  --draft \
  --assignee @me \
  --label "bot-generated,{FormattedID}" \
  --yes
```
Capturar de la salida estándar:
- La URL completa del Merge Request (`MR_URL`).
- El identificador numérico interno del MR (`MR_IID`).

### Paso 4.4 — Inserción de Nota Técnica en el MR
```bash
glab mr note create {MR_IID} -m "## 🤖 Reporte de Validación Automatizada
- **Rally Story:** {FormattedID}
- **Tests ejecutados:** {PASS_COUNT}/{TOTAL_COUNT} en verde
- **Documentos generados:** \`.docs/requerimientos.md\`, \`.docs/diseno.md\`, \`.docs/report.md\`

Merge Request generado como borrador (**Draft**) a la espera de inspección humana."
```

### 🚪 COMPUERTA HUMANA 4 (Gate 4: Verificación de MR)
Presentar al usuario los datos del MR creado:
> *"Merge Request creado satisfactoriamente:*  
> *- **URL:** {MR_URL}*  
> *- **Rama:** {BRANCH_NAME} ➔ main*  
> *- **Modo:** Draft (Borrador protegido)*  
> *¿Deseas que proceda al cierre y actualización de Rally con el enlace del MR?"*

---

## Fase 5: Cierre de Trazabilidad y Sincronización en Rally

### Paso 5.1 — Actualización de Estado en Rally a "Completed"
Invocar `rally_openapi_invoke_tool` para actualizar la historia o defecto:
```json
POST hierarchicalrequirement/{ObjectID}
{
  "ScheduleState": "Completed"
}
```

### Paso 5.2 — Publicación de Comentario de Discusión en Rally
Registrar en la conversación del ítem en Rally:
```text
Implementación técnica completada por Copilot SDLC Automation Agent.

📋 Merge Request: {MR_URL}
🌿 Rama Git: {BRANCH_NAME}
📄 Especificaciones EARS: .docs/requerimientos.md
📐 Diseño Técnico: .docs/diseno.md
📊 Reporte Post-Tarea: .docs/report.md

Estado: Esperando revisión humana de código en GitLab.
Aceptación final: Por el Product Owner tras la fusión del MR.
```

### Paso 5.3 — Balance Final al Desarrollador
Presentar la tarjeta final de cierre:
```text
🎉 Ciclo SDLC Completado Exitosamente para {FormattedID}

📋 Rally:        {FormattedID} ➔ Completed
🔀 GitLab:       MR !{MR_IID} (Draft) ➔ {MR_URL}
🌿 Rama:         {BRANCH_NAME}
📝 Specs:        .docs/requerimientos.md, .docs/diseno.md
📊 Reporte:      .docs/report.md
🧪 Pruebas:      {PASS_COUNT}/{TOTAL_COUNT} pasando (100%)

Próximos pasos requeridos:
1. Revisor técnico: Inspeccionar el código en GitLab y retirar la marca de borrador (--draft).
2. Product Owner: Validar funcionalidad y transicionar a "Accepted" en Rally tras el merge.
```

---

## Reglas de Seguridad Inviolables

1. **PROHIBIDO** ejecutar comandos destructivos de git (`git push --force`, `git reset --hard` hacia ramas remotas, `git clean -fdx` indiscriminado).
2. **PROHIBIDO** modificar archivos fuera del directorio de trabajo `${workspaceFolder}`.
3. **OBLIGATORIO** crear todos los Merge Requests con el flag `--draft`.
4. **OBLIGATORIO** respetar todas las compuertas humanas (Gates 1, 2, 3 y 4). Nunca continuar a la siguiente fase sin confirmación del usuario.
5. **OBLIGATORIO** detenerse si el ciclo de auto-sanación de pruebas alcanza 3 iteraciones fallidas consecutivas.
