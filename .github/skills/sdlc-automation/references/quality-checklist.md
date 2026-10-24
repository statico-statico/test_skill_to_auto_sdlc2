# Checklist de Calidad y Seguridad — SDLC Automation Agent (Python / Java)

Este checklist define los criterios obligatorios que el agente y los revisores humanos deben verificar antes de aprobar la transición hacia Git y Merge Request en proyectos **Python** y **Java**. Se refleja directamente en la sección 3 del archivo `.docs/report.md`.

---

## 1. Principios SOLID de Diseño de Software

- [ ] **S — Single Responsibility Principle (SRP):** Cada clase, función o módulo tiene una única responsabilidad y una única razón para cambiar. Los controladores/routers no contienen lógica de negocio; las entidades no ejecutan persistencia directa.
- [ ] **O — Open/Closed Principle (OCP):** El código está abierto a la extensión pero cerrado a la modificación directa. Se emplean patrones como Strategy, decoradores en Python o interfaces/inyección en Java para añadir nuevos comportamientos sin alterar código probado.
- [ ] **L — Liskov Substitution Principle (LSP):** Cualquier clase derivada puede sustituir a su clase base sin alterar la correctitud del programa. No se lanzan excepciones inesperadas en subtipos.
- [ ] **I — Interface Segregation Principle (ISP):** Las interfaces (o Protocolos/Abstract Classes en Python) son pequeñas, cohesivas y orientadas al cliente. Ningún componente está obligado a implementar métodos que no utiliza.
- [ ] **D — Dependency Inversion Principle (DIP):** Los módulos de alto nivel dependen de abstracciones (interfaces o protocolos), nunca de implementaciones concretas. Se utiliza inyección de dependencias (FastAPI `Depends`, Spring `@Autowired` / inyección por constructor).

---

## 2. Evaluación de Seguridad — OWASP Top 10

| ID OWASP | Categoría de Vulnerabilidad | Criterio de Verificación del Agente |
| :--- | :--- | :--- |
| **A01:2021** | **Broken Access Control** | Todas las operaciones verifican permisos de usuario/rol en el backend. No se confía en la protección del cliente ni en identificadores numéricos manipulables. |
| **A02:2021** | **Cryptographic Failures** | No hay secretos en texto claro. Se emplean algoritmos criptográficos robustos (AES-256-GCM, SHA-256, bcrypt/Argon2 para contraseñas, PyJWT / Nimbus JOSE para JWT). |
| **A03:2021** | **Injection** | Consultas SQL parametrizadas o a través de ORM seguro (SQLAlchemy, Spring Data JPA / Hibernate). Ninguna entrada de usuario se concatena directamente en sentencias SQL ni comandos del sistema operativo. |
| **A04:2021** | **Insecure Design** | Se implementan límites de tasa (rate limiting), validación de esquemas (Pydantic en Python, Bean Validation / Hibernate Validator en Java) y controles de flujo de negocio seguros. |
| **A05:2021** | **Security Misconfiguration** | Modo debug desactivado en producción (`DEBUG=False` o `spring.profiles.active=prod`). Encabezados de seguridad HTTP configurados. Sin credenciales por defecto. |
| **A06:2021** | **Vulnerable & Outdated Components** | Todas las dependencias añadidas a `pyproject.toml`, `requirements.txt`, `pom.xml` o `build.gradle` provienen de fuentes oficiales y en versiones estables sin vulnerabilidades conocidas (`pip-audit`, `dependency-check`). |
| **A07:2021** | **Identification & Authentication Failures** | Tokens de sesión con expiración estricta y firma criptográfica verificada. Protección contra ataques de fuerza bruta y revocación activa en cache/Redis. |
| **A08:2021** | **Software & Data Integrity Failures** | Deserialización segura. Verificación de integridad y validación de tipos estricta en payloads entrantes. |
| **A09:2021** | **Security Logging & Monitoring Failures** | Se registran eventos clave de seguridad (fallos de autenticación, revocaciones de sesión, accesos no autorizados) con timestamps UTC en logs estructurados (JSON), sin registrar datos sensibles (PII/contraseñas). |
| **A10:2021** | **Server-Side Request Forgery (SSRF)** | Peticiones HTTP salientes validadas contra una lista blanca de dominios permitidos. Prohibido acceso a rangos IP locales o metadata de nube (`169.254.169.254`). |

---

## 3. Estándares de Código y Buenas Prácticas

### 3.1 Higiene del Código y Trazabilidad
- [ ] **Sin Secretos Hardcodeados:** Ninguna clave API, contraseña, token o URI de infraestructura privada está inscrita en el código fuente. Se leen desde variables de entorno (`os.getenv`, `pydantic-settings` o `@Value` / `application.yml`).
- [ ] **Trazabilidad Rally Inline:** Cada archivo creado o sustancialmente modificado incluye un comentario inicial vinculante:
  ```python
  # Python:
  # Rally: US10293 — Requisito EARS: REQ-001 (Validación de sesión)
  ```
  ```java
  // Java:
  // Rally: US10293 — Requisito EARS: REQ-001 (Validación de sesión)
  ```
- [ ] **DRY (Don't Repeat Yourself):** No existe duplicación innecesaria de lógica. Los cálculos y transformaciones comunes residen en módulos utilitarios o servicios compartidos.
- [ ] **Imports Limpios:** Sin imports no utilizados, circulares o con comodines (`from module import *`, `import java.util.*`).
- [ ] **Manejo Defensivo de Errores:** Todas las llamadas a I/O, base de datos SQL, APIs de red o parsing de datos están envueltas en bloques de control (`try/except` en Python, `try/catch` en Java) con excepciones personalizadas tipadas.

### 3.2 Logging y Diagnóstico
- [ ] Niveles de log respetados:
  - `ERROR`: Fallos no recuperables que requieren atención inmediata.
  - `WARN`: Condiciones anómalas recuperables o advertencias de rendimiento.
  - `INFO`: Hitos significativos del flujo de negocio.
  - `DEBUG`: Información de diagnóstico detallada (desactivada en producción).
- [ ] Logs estructurados (formato JSON estándar).

---

## 4. Estándares de Pruebas Automatizadas (Python / Java)

| Métrica / Tipo de Prueba | Umbral Mínimo Requerido | Herramienta Python | Herramienta Java |
| :--- | :--- | :--- | :--- |
| **Tasa de Aprobación** | **100%** de los tests deben pasar | `pytest` | `mvn test` / `./gradlew test` |
| **Cobertura de Código** | **≥ 80%** en líneas y ramas | `pytest-cov` | JaCoCo |
| **Happy Path Tests** | Al menos 1 por cada criterio EARS nominal | Test de endpoint / servicio | `@Test` JUnit 5 |
| **Negative Tests (Edge Cases)** | Al menos 2 por cada criterio negativo EARS | `pytest.raises(HTTPException)` | `assertThrows(...)` |
| **Pruebas de Integración** | Mínimo 1 test de extremo a extremo | `httpx.AsyncClient` + DB | `@SpringBootTest` + `@AutoConfigureMockMvc` |
