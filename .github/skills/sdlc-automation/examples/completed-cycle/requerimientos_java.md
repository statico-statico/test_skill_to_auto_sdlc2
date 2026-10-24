# Especificación de Requerimientos: US10293 — Renovación de Sesión por Heartbeat y Control de Inactividad (Java)

> **Identificador Rally:** `US10293`  
> **Título de la Historia:** Control de Inactividad y Renovación de Token de Sesión por Heartbeat con Auditoría SQL  
> **Iteración / Sprint:** Sprint 24.3 (Core Security)  
> **Fecha de Generación:** 2026-10-24  
> **Estado en Rally:** In-Progress (original: Defined)  
> **Stack Objetivo:** Java 21 (Spring Boot 3.3 / Spring Data JPA / Redis / JUnit 5)  
> **Generado por:** Copilot SDLC Automation Agent  

---

## 1. Descripción Funcional

Para satisfacer los requisitos de cumplimiento bancario y mitigar vulnerabilidades de gestión de sesiones según OWASP y PCI-DSS, el backend corporativo en Java debe implementar un servicio centralizado de control de expiración de sesiones.

El servicio expone endpoints seguros de heartbeat (`POST /api/v1/auth/session/heartbeat`) y revocación forzada (`POST /api/v1/auth/session/revoke`). Cuando el cliente autenticado confirma actividad, el backend extiende el TTL de la sesión activa en Redis a 15 minutos (900 segundos) y registra el evento transaccional en la tabla SQL `session_audit_logs` mediante Spring Data JPA. En caso de inactividad o revocación voluntaria, la clave de Redis es destruida inmediatamente, impidiendo cualquier uso ulterior del token de sesión.

---

## 2. Historia de Usuario

- **Como** servicio de seguridad y autenticación corporativo,
- **quiero** gestionar la renovación periódica de sesiones por heartbeat y procesar revocaciones por timeout,
- **para** garantizar la integridad de las sesiones de los usuarios y mantener un registro auditable e inmutable en base de datos SQL.

---

## 3. Criterios de Aceptación (Notación EARS)

### 3.1 Requisitos Conducidos por Eventos (CUANDO)
- **REQ-EVT-01:** CUANDO el backend reciba una solicitud `POST /api/v1/auth/session/heartbeat` con una cookie de sesión válida y token CSRF, EL SISTEMA DEBERÁ renovar el TTL de la clave de sesión en Redis por 900 segundos y retornar un nuevo token de acceso en menos de 100 ms (p95).
- **REQ-EVT-02:** CUANDO se invoque `POST /api/v1/auth/session/revoke` con motivo `inactivity_timeout`, EL SISTEMA DEBERÁ eliminar la sesión de Redis, añadir el JTI a la lista negra e insertar un registro en la tabla SQL `session_audit_logs`.

### 3.2 Requisitos Conducidos por Estado (MIENTRAS)
- **REQ-STA-01:** MIENTRAS la clave de sesión exista y no haya expirado en Redis, EL SISTEMA DEBERÁ autorizar las peticiones concurrentes del usuario.
- **REQ-STA-02:** MIENTRAS se ejecute la transacción de revocación, EL SISTEMA DEBERÁ garantizar la consistencia atómica entre Redis y la base de datos SQL.

### 3.3 Requisitos Opcionales o Condicionales (DONDE)
- **REQ-OPT-01:** DONDE el perfil de ejecución sea `prod`, EL SISTEMA DEBERÁ verificar que las cookies de sesión incluyan los atributos `HttpOnly`, `Secure` y `SameSite=Strict`.

### 3.4 Requisitos de Manejo de Errores y Comportamiento Indeseado (SI)
- **REQ-NEG-01:** SI el token proporcionado ha expirado o su sesión no existe en Redis, EL SISTEMA DEBERÁ retornar código HTTP 401 Unauthorized con payload JSON de error tipado.
- **REQ-NEG-02:** SI la base de datos SQL no está disponible durante la inserción de auditoría, EL SISTEMA DEBERÁ registrar el fallo en el log de errores (`ERROR`) y emitir una alerta a la cola de auditoría asíncrona sin bloquear la sesión del usuario.

### 3.5 Requisitos Ubicuos (SIEMPRE)
- **REQ-UBI-01:** EL SISTEMA DEBERÁ validar todas las peticiones entrantes mediante anotaciones de Bean Validation (`@Valid`, `@NotNull`, `@NotBlank`).
- **REQ-UBI-02:** EL SISTEMA DEBERÁ registrar cada renovación y expiración en la tabla SQL `session_audit_logs` con fecha UTC y Correlation ID.

---

## 4. Requisitos No Funcionales (NFR)

| Categoría | Especificación del Requisito | Métrica / Umbral Verificable |
| :--- | :--- | :--- |
| **Rendimiento** | Latencia de respuesta en renovación de sesión | < 100 ms (p95) bajo carga de 500 req/s |
| **Seguridad** | Cifrado y gestión de tokens | Tokens firmados con RS256; sin secretos en código |
| **Transaccionalidad** | Persistencia SQL | Cumplimiento ACID garantizado con `@Transactional` en Spring |
| **Calidad de Código** | Análisis estático y estilo | 0 violaciones con `mvn checkstyle:check` |

---

## 5. Fuera de Alcance (Out of Scope)

- Implementación de clientes gráficos o componentes frontend.
- Modificación de esquemas de autenticación LDAP / SAML corporativos.

---

## 6. Preguntas Abiertas y Supuestos

- [x] **Supuesto:** Cluster de Redis configurado con `LettuceConnectionFactory`.
- [x] **Supuesto:** Base de datos relacional (PostgreSQL / MySQL / H2 para tests) gestionada con Hibernate / Flyway.

---

## 7. Matriz de Trazabilidad Rally

| Atributo Rally | Valor Ingerido |
| :--- | :--- |
| **FormattedID** | `US10293` |
| **Name** | Control de Inactividad y Renovación por Heartbeat (Java) |
| **ScheduleState** | `In-Progress` |
| **Owner** | Carlos Mendoza (Security Backend Lead) |
| **Project** | Digital Banking Core API (Java / Spring Boot) |
| **Iteration** | Sprint 24.3 |
