# 📊 Reporte Post-Tarea: {RALLY_FORMATTED_ID}

> **Rally ID:** {FormattedID}
> **Fecha:** {DATE}
> **Agente:** SDLC Automation Agent v1.0
> **Estado:** Completado

---

## 1. Resumen Ejecutivo

- **Objetivo:** {What was implemented and why}
- **Resultado:** {Outcome — tests passing, coverage, etc.}
- **Impacto:** {Business/system impact of this change}

## 2. Trazabilidad del Desarrollo

| Archivo | Acción | Requisito EARS Asociado |
|:---|:---|:---|
| `{path}` | {Created/Modified/Deleted} | {requirement reference} |

## 3. Checklist de Mejores Prácticas

> Referencia completa: `.github/skills/sdlc-automation/references/quality-checklist.md`

- [ ] **Código Formateado:** Sigue las guías de estilo del proyecto
- [ ] **Arquitectura Modular:** Principios SOLID respetados
- [ ] **Manejo de Errores:** Excepciones capturadas y registradas
- [ ] **Seguridad:** Inputs validados, sin credenciales hardcodeadas
- [ ] **Documentación:** Comentarios de trazabilidad Rally en cada archivo
- [ ] **DRY:** Sin duplicación de lógica

## 4. Métricas de Calidad

| Métrica | Valor | Umbral |
|:---|:---|:---|
| **Tests Pasando** | {X}/{Y} | 100% |
| **Test Coverage** | {Z}% | >80% |
| **Errores de Linting** | {N} | 0 |

## 5. Evaluación de Seguridad (OWASP)

| Categoría OWASP | Estado | Notas |
|:---|:---|:---|
| A01 — Access Control | ✅/⚠️/❌ | {details} |
| A02 — Crypto Failures | ✅/⚠️/❌ | {details} |
| A03 — Injection | ✅/⚠️/❌ | {details} |
| A04 — Insecure Design | ✅/⚠️/❌ | {details} |
| A05 — Misconfiguration | ✅/⚠️/❌ | {details} |
| A06 — Vulnerable Deps | ✅/⚠️/❌ | {details} |
| A07 — Auth Failures | ✅/⚠️/❌ | {details} |
| A08 — Data Integrity | ✅/⚠️/❌ | {details} |
| A09 — Logging Failures | ✅/⚠️/❌ | {details} |
| A10 — SSRF | ✅/⚠️/❌ | {details} |

## 6. Gestión de Riesgos

| Riesgo | Severidad | Probabilidad | Mitigación | Riesgo Residual |
|:---|:---|:---|:---|:---|
| {risk} | H/M/L | H/M/L | {mitigation} | {residual} |

## 7. Deuda Técnica

| Ítem | Descripción | Ticket de Remediación |
|:---|:---|:---|
| {item} | {description} | {future ticket ID} |

## 8. Resumen de Testing

- **Unitarios:** {count} tests, {pass_count} passing
- **Integración:** {count} tests, {pass_count} passing
- **Edge Cases:** {list of edge cases covered}

## 9. Referencias Cruzadas

| Sistema | Referencia |
|:---|:---|
| Rally | {FormattedID} |
| GitLab MR | #{MR_IID} — {MR_URL} |
| Branch | {BRANCH_NAME} |
| Specs | `.docs/requerimientos.md`, `.docs/diseño.md` |
