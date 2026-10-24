# Requerimientos: {RALLY_FORMATTED_ID} — {TITLE}

> **Rally ID:** {FormattedID}
> **Iteración:** {Iteration}
> **Fecha de generación:** {DATE}
> **Generado por:** SDLC Automation Agent

---

## Descripción Funcional

{PROCESSED_DESCRIPTION — rewritten from Rally Description field with clarity
and completeness. Remove HTML artifacts.}

## Historia de Usuario

**Como** {role extracted from context},
**quiero** {action from Description},
**para** {business value / benefit}.

## Criterios de Aceptación (Notación EARS)

> Referencia de notación: `.github/skills/sdlc-automation/references/ears-notation.md`

### Requisitos de Evento (CUANDO)
- CUANDO {event}, EL SISTEMA DEBERÁ {action} EN MENOS DE {SLA}.

### Requisitos de Estado (MIENTRAS)
- MIENTRAS {state}, EL SISTEMA DEBERÁ {continuous_behavior}.

### Requisitos Negativos (SI — manejo de errores)
- SI {error_condition}, EL SISTEMA DEBERÁ {recovery_action}.

### Requisitos Ubicuos (SIEMPRE)
- EL SISTEMA DEBERÁ {always_true_constraint}.

### Requisitos Opcionales (DONDE — si aplica)
- DONDE {feature habilitada}, EL SISTEMA DEBERÁ {configurable_behavior}.

## Requisitos No Funcionales

| Categoría | Requisito | Métrica |
|:---|:---|:---|
| **Rendimiento** | {description} | {metric} |
| **Seguridad** | {description} | {metric} |
| **Disponibilidad** | {description} | {metric} |
| **Escalabilidad** | {description} | {metric} |

## Fuera de Alcance

- {What is explicitly NOT included in this issue}

## Preguntas Abiertas

- [ ] {Any ambiguities found in the Rally issue}

## Dependencias

| Tipo | Descripción | Estado |
|:---|:---|:---|
| Upstream | {dependency that must be completed first} | {status} |
| Downstream | {dependency that depends on this issue} | {status} |
| External | {external system dependency} | {status} |

## Trazabilidad

| Campo Rally | Valor |
|:---|:---|
| FormattedID | {FormattedID} |
| Name | {Name} |
| ScheduleState | {ScheduleState} |
| Iteration | {Iteration} |
| Owner | {Owner} |
| Project | {Project} |
| PlanEstimate | {PlanEstimate} |
| Tags | {Tags} |
