# 🚀 SDLC Copilot Agent Skill: De Rally Issue a GitLab Merge Request (Python / Java)

> **Solución de Automatización End-to-End del Ciclo de Vida del Software (SDLC)**  
> Integra **Broadcom Rally MCP**, **GitHub Copilot Agent Mode** y **GitLab CLI (`glab`)** bajo una metodología rigurosa de **Desarrollo Guiado por Especificaciones (Spec-Driven Development)** con compuertas humanas obligatorias (*Human-in-the-Loop*), optimizado para **Python** y **Java**.

---

## 📌 1. Visión General y Flujo de Trabajo

Este repositorio contiene la arquitectura completa de un **Agent Skill** y un **Custom Agent** para VS Code, diseñado para transformar un requerimiento de negocio de Rally en un Merge Request verificado y documentado en GitLab para proyectos **Python** y **Java**:

```
Rally Issue ➔ requerimientos.md (EARS) ➔ diseño.md (Mermaid) ➔ Código (Python/Java) ➔ Tests (pytest/mvn) ➔ Git Branch ➔ Draft MR (glab) ➔ Rally Update ➔ report.md
```

### Diagrama de Estados y Compuertas Humanas

```mermaid
graph TD
    START["🎯 Usuario invoca:<br/>'@sdlc-orchestrator con US10293'"] --> P0["⚙️ Phase 0: Context Discovery<br/>detect-stack.sh/.bat (Python/Java)"]
    P0 --> P1["📥 Phase 1: Rally Ingestion<br/>Rally MCP: fetch fields"]
    P1 --> V1{"ScheduleState?"}
    V1 -->|Accepted| ABORT["🛑 ABORT<br/>Artefacto Inmutable"]
    V1 -->|Defined/In-Progress| P1b["📝 Normalizar HTML<br/>Defined ➔ In-Progress"]
    P1b --> G1{"🚪 GATE 1<br/>¿Confirmar alcance Rally?"}
    G1 -->|❌ Ajustar| P1
    G1 -->|✅ Aprobado| P2["📋 Phase 2: Spec Generation<br/>requerimientos.md + diseño.md"]
    P2 --> P2a["📄 .docs/requerimientos.md<br/>(Notación formal EARS)"]
    P2 --> P2b["📐 .docs/diseño.md<br/>(Mermaid + Contratos)"]
    P2a --> G2
    P2b --> G2{"🚪 GATE 2<br/>¿Aprobar especificaciones?"}
    G2 -->|❌ Ajustar| P2
    G2 -->|✅ Aprobado| P3["💻 Phase 3: Implementation<br/>Código + Self-Healing Tests"]
    P3 --> P3a["✍️ Escribir código Python/Java + Trazabilidad"]
    P3a --> P3b["🧪 Ejecutar suite de pruebas (pytest/mvn/gradle)"]
    P3b --> P3c{"¿Tests en verde?"}
    P3c -->|❌ iter < 3| P3a
    P3c -->|❌ iter ≥ 3| FAIL["⚠️ STOP<br/>Solicitar asistencia humana"]
    P3c -->|✅ 100% Green| G3{"🚪 GATE 3<br/>¿Aprobar implementación?"}
    G3 -->|❌ Ajustar| P3
    G3 -->|✅ Aprobado| P4["🔀 Phase 4: Git + GitLab MR<br/>Branch + Commit + glab CLI"]
    P4 --> P4a["🌿 git checkout -b feature/..."]
    P4a --> P4b["📊 Generar .docs/report.md"]
    P4b --> P4c["📬 glab mr create --draft --yes"]
    P4c --> P4d["💬 glab mr note create"]
    P4d --> G4{"🚪 GATE 4<br/>¿Validar MR creado?"}
    G4 -->|❌ Ajustar| P4
    G4 -->|✅ Aprobado| P5["🏁 Phase 5: Rally Closure<br/>Sync & Trazabilidad Cruzada"]
    P5 --> P5a["✅ Rally ScheduleState ➔ Completed"]
    P5a --> P5b["💬 Comentario de Discusión en Rally"]
    P5b --> DONE["🎉 Ciclo SDLC Finalizado<br/>Pendiente: PO Acceptance"]
```

---

## 📂 2. Estructura del Proyecto

```text
Issue_to_PR/
├── .github/
│   ├── agents/
│   │   └── sdlc-orchestrator.agent.md        ← Agente orquestador senior (@sdlc-orchestrator)
│   │
│   ├── skills/
│   │   └── sdlc-automation/
│   │       ├── SKILL.md                      ← Procedimientos operativos estándar (SOP)
│   │       │
│   │       ├── references/                   ← Bases de conocimiento técnico
│   │       │   ├── ears-notation.md          ← Guía sintáctica de los 5 patrones EARS
│   │       │   ├── rally-fields-map.md       ← Mapeo WSAPI, ScheduleState y limpieza HTML
│   │       │   ├── quality-checklist.md      ← Checklist SOLID, OWASP Top 10 y métricas
│   │       │   └── glab-commands.md          ← Guía de comandos no interactivos glab CLI
│   │       │
│   │       ├── templates/                    ← Plantillas estandarizadas para documentos
│   │       │   ├── requerimientos.md         ← Plantilla de requisitos formales EARS
│   │       │   ├── diseño.md                 ← Plantilla de diseño técnico y Mermaid
│   │       │   ├── report.md                 ← Plantilla de reporte post-tarea de calidad
│   │       │   └── mr-description.md         ← Plantilla para cuerpo del Merge Request
│   │       │
│   │       ├── scripts/                      ← Automatización ejecutable auxiliar (.sh y .bat)
│   │       │   ├── detect-stack.sh / .bat    ← Detección automática de Python o Java
│   │       │   ├── git-workflow.sh / .bat    ← Secuencia segura de Git + glab CLI
│   │       │   └── validate-rally-fields.sh / .bat ← Validador de esquemas y estados de Rally
│   │       │
│   │       └── examples/
│   │           └── completed-cycle/          ← Ciclos completos de referencia por stack
│   │               ├── requerimientos_python.md, diseño_python.md, report_python.md
│   │               └── requerimientos_java.md, diseño_java.md, report_java.md
│   │
│   └── copilot-instructions.md               ← Reglas maestras para VS Code Copilot
│
├── .vscode/
│   └── mcp.json                              ← Configuración MCP segura para Broadcom Rally
│
└── README.md                                 ← Documentación global del sistema
```

---

## 🛠️ 3. Requisitos Previos y Configuración

### 1. Entorno de Desarrollo
- **Visual Studio Code** con soporte para **GitHub Copilot Agent Mode**.
- **Entorno de ejecución:** Python 3.10+ (`pytest`, `poetry`, `pip`) o Java 17+ (Maven `mvn` o Gradle `gradle`).
- **Git** inicializado en el repositorio de trabajo.
- **GitLab CLI (`glab`)** instalado y autenticado:
  ```bash
  glab auth status
  # Si no está autenticado:
  glab auth login
  ```

### 2. Configuración de Rally MCP
El archivo `.vscode/mcp.json` incluye la definición del servidor MCP. Al iniciar VS Code, el IDE solicitará de forma segura el Token de Acceso Personal (PAT) sin exponer credenciales en el código:
```json
{
  "servers": {
    "rally-mcp": {
      "type": "http",
      "url": "https://mcp.rallydev.com/mcp",
      "headers": {
        "Authorization": "Bearer ${input:rally_pat}"
      }
    }
  }
}
```

---

## 🚀 4. Guía de Uso Paso a Paso

### Paso 1: Invocación del Agente
En el panel de chat de VS Code en **Agent Mode**, introduce:
```text
@sdlc-orchestrator Desarrolla la historia de usuario US10293
```
*O alternativamente:*
```text
Automatiza el requerimiento US10293 de Rally hasta Merge Request
```

### Paso 2: Validación de Compuertas Humanas
El agente se detendrá de manera determinista en cada una de las 4 compuertas:

1. **Gate 1 (Contexto de Rally):** Revisa el título, descripción limpia y criterios detectados. Confirma si el alcance es correcto.
2. **Gate 2 (Aprobación de Specs):** Inspecciona `.docs/requerimientos.md` y `.docs/diseño.md`. Puedes solicitar ajustes en el chat antes de aprobar.
3. **Gate 3 (Revisión de Código):** Verifica el resumen de archivos modificados y la confirmación de que el 100% de los tests pasan (`pytest` o `mvn test`).
4. **Gate 4 (Revisión de MR):** Inspecciona el enlace del Draft MR en GitLab antes de que el agente actualice Rally.

### Paso 3: Cierre Automático
El agente actualizará Rally a `Completed`, registrará el comentario con el enlace al MR y presentará el reporte final de cierre.

---

## 🔒 5. Políticas de Seguridad y Buenas Prácticas

- **Stacks Soportados Exclusivos:** Python y Java (con soporte a persistencia SQL / JPA / SQLAlchemy / Redis).
- **Protección contra Fusiones Prematuras:** Todo Merge Request se crea siempre con la bandera `--draft`.
- **Inmutabilidad de Artefactos Aceptados:** Si la historia en Rally ya está en estado `Accepted`, el agente aborta automáticamente.
- **Bucle de Auto-Sanación Seguro:** Si las pruebas fallan durante la Fase 3, el agente analiza el stack trace y corrige el código quirúrgicamente hasta un máximo de 3 intentos; si persisten los fallos, se detiene y solicita revisión humana.
- **Sin Comandos Destructivos:** Prohibido el uso de `git push --force` o modificaciones fuera del workspace.
- **Trazabilidad Integral:** Cada archivo modificado incluye cabeceras comentadas con el identificador de Rally, y cada commit sigue el estándar de *Conventional Commits*.
