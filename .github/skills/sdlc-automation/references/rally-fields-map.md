# Mapeo de Campos Rally WSAPI → Documentos SDLC

## Campos Principales

| Campo Rally WSAPI      | Tipo       | Documento Destino       | Sección            |
|:-----------------------|:-----------|:------------------------|:-------------------|
| FormattedID            | string     | Todos                   | Header             |
| Name                   | string     | requerimientos.md       | Título             |
| Description            | HTML/text  | requerimientos.md       | Descripción        |
| AcceptanceCriteria     | HTML/text  | requerimientos.md       | Criterios EARS     |
| Notes                  | HTML/text  | requerimientos.md       | Contexto adicional |
| ScheduleState          | enum       | Flujo de control        | Gate validation    |
| Owner                  | ref        | report.md               | Trazabilidad       |
| Iteration              | ref        | Branch naming           | Git workflow       |
| Tags                   | collection | MR labels               | glab --label       |
| Project                | ref        | report.md               | Contexto           |

## Campos Secundarios

| Campo Rally WSAPI      | Tipo       | Uso en el Agente                          |
|:-----------------------|:-----------|:------------------------------------------|
| ObjectID               | int        | Identificador interno para updates via API |
| PlanEstimate           | float      | Referencia en report.md (story points)    |
| Release                | ref        | Contexto de release en report.md          |
| Blocked                | boolean    | Validación — si blocked, avisar al usuario |
| BlockedReason          | string     | Contexto adicional si Blocked = true      |
| CreationDate           | datetime   | Referencia temporal en report.md          |
| LastUpdateDate         | datetime   | Detección de cambios recientes            |

## Valores de ScheduleState

| Estado      | Acción del Agente                    | Transición Permitida       |
|:------------|:-------------------------------------|:---------------------------|
| Defined     | Transicionar a In-Progress, proceder | Defined → In-Progress      |
| In-Progress | Proceder sin cambio de estado        | In-Progress → Completed    |
| Completed   | Advertir al usuario, pedir permiso   | Completed → (ya completado)|
| Accepted    | ABORTAR — no modificar               | N/A — estado final         |

## Consultas WSAPI Comunes

### Leer User Story por FormattedID
```
GET /hierarchicalrequirement
  query: (FormattedID = "{ID}")
  fetch: FormattedID,Name,Description,AcceptanceCriteria,Notes,
         ScheduleState,Owner,Iteration,Project,Tags,ObjectID,
         PlanEstimate,Blocked,BlockedReason
```

### Leer Defecto por FormattedID
```
GET /defect
  query: (FormattedID = "{ID}")
  fetch: FormattedID,Name,Description,Notes,ScheduleState,
         Owner,Iteration,Project,Tags,ObjectID,Priority,Severity
```

### Actualizar ScheduleState
```
POST /hierarchicalrequirement/{ObjectID}
  payload: { "HierarchicalRequirement": { "ScheduleState": "{new_state}" } }
```

### Añadir Discussion Comment
```
POST /conversationpost/create
  payload: {
    "ConversationPost": {
      "Artifact": "/hierarchicalrequirement/{ObjectID}",
      "Text": "{message}"
    }
  }
```

## Procesamiento de Campos HTML

Muchos campos de Rally contienen HTML. El agente debe:

1. **Preservar la estructura** semántica (listas, tablas, encabezados)
2. **Eliminar tags de presentación** (`<div>`, `<span>`, `<font>`)
3. **Convertir a Markdown** para uso en documentos generados
4. **Detectar contenido vacío**: campos con solo `<p>&nbsp;</p>` o similar deben tratarse como vacíos
