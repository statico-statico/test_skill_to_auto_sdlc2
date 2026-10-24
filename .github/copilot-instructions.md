# GitHub Copilot Instructions — SDLC Automation Workspace (Python / Java)

Este archivo define las directrices maestras para GitHub Copilot y el Modo Agente en este repositorio para proyectos **Python** y **Java**.

---

## 1. Agente Orquestador y Habilidad SDLC

Este proyecto cuenta con un sistema especializado de automatización del ciclo de vida del software (SDLC) compuesto por:
1. **Agente Especializado:** `@sdlc-orchestrator` (definido en `.github/agents/sdlc-orchestrator.agent.md`).
2. **Agent Skill Principal:** `sdlc-automation` (definido en `.github/skills/sdlc-automation/SKILL.md`).
3. **Stacks Soportados:** **Python** (pytest, Poetry, pip) y **Java** (Maven, Gradle, JUnit).

### Invocación Rápida
Cuando el usuario mencione un identificador de Broadcom Rally (ej. `US10293`, `DE4512`) o solicite *"automatiza este issue"*, *"de issue a PR"* o *"crea el MR para la historia..."*, Copilot debe activar automáticamente el skill `sdlc-automation` o delegar la orquestación en `@sdlc-orchestrator`.

---

## 2. Principios de Desarrollo del Repositorio

1. **Desarrollo Guiado por Especificaciones (Spec-Driven Development):**
   - **NUNCA** generes código fuente ni modifiques archivos del proyecto directamente a partir de un ticket sin antes haber creado y obtenido aprobación explícita de:
     - `.docs/requerimientos.md` (con criterios en **Notación EARS**).
     - `.docs/diseño.md` (con diagramas de arquitectura Mermaid y contratos).
2. **Compuertas Humanas Obligatorias (Human-in-the-Loop):**
   - El agente debe pausar la ejecución y solicitar confirmación expresa del desarrollador en cada una de las 4 compuertas:
     - **Gate 1:** Tras la ingesta y extracción de datos de Rally.
     - **Gate 2:** Tras la generación de `.docs/requerimientos.md` y `.docs/diseño.md`.
     - **Gate 3:** Tras la implementación y ejecución exitosa de pruebas (100% en verde con `pytest` o `mvn/gradle test`).
     - **Gate 4:** Tras la publicación de la rama y creación del Draft MR en GitLab.
3. **Trazabilidad Bidireccional Total:**
   - Todo archivo creado o modificado debe contener en sus líneas iniciales el comentario de trazabilidad:
     ```python
     # Python:
     # Rally: {FormattedID} — Requisito EARS: {ID_REQUISITO}
     ```
     ```java
     // Java:
     // Rally: {FormattedID} — Requisito EARS: {ID_REQUISITO}
     ```
   - Todos los commits y Merge Requests deben referenciar el identificador de Rally.
4. **Seguridad y No Destructividad:**
   - Todos los Merge Requests deben ser creados con la bandera `--draft`.
   - Queda terminantemente prohibido ejecutar `git push --force`, `git reset --hard` sobre ramas remotas o comandos interactivos que bloqueen el terminal.
   - En caso de fallos de pruebas, aplicar el bucle de auto-sanación con un máximo de 3 iteraciones. Si no se resuelve, detenerse y solicitar asistencia humana.

---

## 3. Estructura de Recursos del Skill SDLC

- **Plantillas:** `.github/skills/sdlc-automation/templates/`
  - `requerimientos.md`, `diseño.md`, `report.md`, `mr-description.md`.
- **Referencias Técnicas:** `.github/skills/sdlc-automation/references/`
  - `ears-notation.md` (guía de patrones sintácticos EARS).
  - `rally-fields-map.md` (mapeo de atributos WSAPI y máquina de estados).
  - `quality-checklist.md` (estándares SOLID, OWASP Top 10 y métricas).
  - `glab-commands.md` (guía rápida no interactiva de GitLab CLI).
- **Scripts de Soporte:** `.github/skills/sdlc-automation/scripts/`
  - `detect-stack.sh` / `detect-stack.bat` (detección automática de Python o Java).
  - `git-workflow.sh` / `git-workflow.bat` (orquestación segura de Git + glab).
  - `validate-rally-fields.sh` / `validate-rally-fields.bat` (validación de campos y estados de Rally).
- **Ejemplos Completos de Referencia:** `.github/skills/sdlc-automation/examples/completed-cycle/`
  - Python: `requerimientos_python.md`, `diseño_python.md`, `report_python.md`
  - Java: `requerimientos_java.md`, `diseño_java.md`, `report_java.md`
