# Checklist de Calidad — SDLC Automation Agent

## Principios SOLID
- [ ] **S** — Single Responsibility: Cada clase/módulo tiene una sola razón para cambiar
- [ ] **O** — Open/Closed: Extendible sin modificar código existente
- [ ] **L** — Liskov Substitution: Subtipos sustituibles por sus bases
- [ ] **I** — Interface Segregation: Interfaces pequeñas y enfocadas
- [ ] **D** — Dependency Inversion: Depender de abstracciones, no de implementaciones

## Seguridad (OWASP Top 10)
- [ ] A01 — Broken Access Control: Permisos verificados en cada operación
- [ ] A02 — Cryptographic Failures: Datos sensibles cifrados
- [ ] A03 — Injection: Inputs sanitizados, queries parametrizadas
- [ ] A04 — Insecure Design: Patrones seguros desde el diseño
- [ ] A05 — Security Misconfiguration: No credenciales por defecto
- [ ] A06 — Vulnerable Components: Dependencias actualizadas
- [ ] A07 — Auth Failures: Tokens y sesiones gestionados correctamente
- [ ] A08 — Data Integrity: Validación de datos en entrada y salida
- [ ] A09 — Logging Failures: Eventos de seguridad registrados
- [ ] A10 — SSRF: Requests externos validados y restringidos

## Código
- [ ] Sin credenciales hardcodeadas
- [ ] Manejo de errores en todas las llamadas externas
- [ ] Logging con niveles adecuados (ERROR, WARN, INFO)
- [ ] Tests cubren happy path + edge cases + error cases
- [ ] Código sigue convenciones existentes del proyecto
- [ ] No hay código muerto o comentado sin razón
- [ ] Imports ordenados y sin duplicados

## Documentación
- [ ] Comentarios de trazabilidad Rally en cada archivo modificado
- [ ] Docstrings/JSDoc en funciones públicas
- [ ] README actualizado si se añaden nuevas features o dependencias
- [ ] CHANGELOG actualizado si el proyecto lo usa

## Testing
- [ ] Tests unitarios para cada función nueva
- [ ] Tests de integración para flujos end-to-end
- [ ] Edge cases cubiertos (null, vacío, límites, concurrencia)
- [ ] Mocking apropiado de dependencias externas
- [ ] Tests ejecutan en < 30 segundos (unitarios)

## Performance
- [ ] No hay queries N+1 o loops ineficientes
- [ ] Datos grandes paginados o limitados
- [ ] Cache utilizado donde sea apropiado
- [ ] Operaciones de I/O son asíncronas cuando corresponde

## Git & CI/CD
- [ ] Commits siguen Conventional Commits (`feat:`, `fix:`, `chore:`)
- [ ] Branch sigue convención del proyecto
- [ ] MR creado como Draft
- [ ] No se incluyen archivos generados o temporales en el commit
- [ ] `.gitignore` actualizado si se añaden nuevos tipos de archivos generados

## Evaluación de Seguridad para report.md

Usar esta tabla en el reporte de cada tarea:

| Categoría OWASP       | Estado   | Criterio de Verificación                              |
|:-----------------------|:---------|:------------------------------------------------------|
| A01 — Access Control   | ✅/⚠️/❌ | ¿Se verifican permisos en cada operación sensible?     |
| A02 — Crypto Failures  | ✅/⚠️/❌ | ¿Se cifran datos sensibles en tránsito y reposo?       |
| A03 — Injection        | ✅/⚠️/❌ | ¿Se sanitizan inputs y se usan queries parametrizadas? |
| A04 — Insecure Design  | ✅/⚠️/❌ | ¿Se aplicaron patrones de diseño seguros?              |
| A05 — Misconfiguration | ✅/⚠️/❌ | ¿No hay credenciales por defecto ni configs inseguras? |
| A06 — Vulnerable Deps  | ✅/⚠️/❌ | ¿Las dependencias están actualizadas?                  |
| A07 — Auth Failures    | ✅/⚠️/❌ | ¿Se gestionan tokens y sesiones correctamente?         |
| A08 — Data Integrity   | ✅/⚠️/❌ | ¿Se validan datos en entrada y salida?                 |
| A09 — Logging Failures | ✅/⚠️/❌ | ¿Se registran eventos de seguridad?                    |
| A10 — SSRF             | ✅/⚠️/❌ | ¿Se validan y restringen requests externos?            |

### Leyenda de Estados

| Estado | Significado |
|:-------|:------------|
| ✅     | Verificado y conforme |
| ⚠️     | Parcialmente conforme o no aplica completamente |
| ❌     | No conforme — requiere acción |
| N/A    | No aplica para este cambio |
