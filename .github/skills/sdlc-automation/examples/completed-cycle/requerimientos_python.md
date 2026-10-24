# Especificación de Requerimientos: US10293 — Renovación de Sesión por Heartbeat y Control de Inactividad (Python)

> **Identificador Rally:** `US10293`  
> **Título de la Historia:** Control de Inactividad y Renovación de Token de Sesión por Heartbeat con Auditoría SQL  
> **Iteración / Sprint:** Sprint 24.3 (Core Security)  
> **Fecha de Generación:** 2026-10-24  
> **Estado en Rally:** In-Progress (original: Defined)  
> **Stack Objetivo:** Python 3.12 (FastAPI / SQLAlchemy / Redis / pytest)  
> **Generado por:** Copilot SDLC Automation Agent  

---

## 1. Descripción Funcional

Para garantizar la seguridad de las cuentas de usuario y mitigar riesgos de secuestro de sesión (Session Hijacking) conforme a los estándares bancarios y PCI-DSS, el backend debe proporcionar una gestión centralizada y segura de la inactividad de sesiones.

El servicio expone endpoints seguros de heartbeat (`POST /api/v1/auth/session/heartbeat`) y revocación forzada (`POST /api/v1/auth/session/revoke`). Cuando un cliente autenticado confirma actividad dentro de la ventana de gracia, el sistema renueva el TTL de la sesión activa en el cluster de Redis y actualiza el registro histórico en la base de datos SQL (`session_audit_logs`). En caso de inactividad prolongada o expiración definitiva, el backend revoca activamente las credenciales de sesión en Redis e invalida cualquier intento de uso posterior.

---

## 2. Historia de Usuario

- **Como** servicio de autenticación y seguridad de la plataforma,
- **quiero** procesar solicitudes de renovación de sesión periódicas (heartbeat) y gestionar revocaciones por inactividad,
- **para** garantizar que sólo los usuarios activamente autorizados mantengan tokens válidos, registrando toda actividad en auditoría SQL sin degradar el rendimiento.

---

## 3. Criterios de Aceptación (Notación EARS)

### 3.1 Requisitos Conducidos por Eventos (CUANDO)
- **REQ-EVT-01:** CUANDO el backend reciba una solicitud `POST /api/v1/auth/session/heartbeat` con una cookie de sesión válida y token CSRF, EL SISTEMA DEBERÁ extender el TTL de la sesión en Redis por 900 segundos (15 minutos) y retornar un nuevo access token en menos de 100 ms (p95).
- **REQ-EVT-02:** CUANDO se invoque `POST /api/v1/auth/session/revoke` con motivo `inactivity_timeout`, EL SISTEMA DEBERÁ eliminar la clave de sesión de Redis, añadir el JTI a la lista negra temporal e insertar un registro en la tabla SQL `session_audit_logs`.

### 3.2 Requisitos Conducidos por Estado (MIENTRAS)
- **REQ-STA-01:** MIENTRAS el identificador de sesión figure en estado activo en Redis, EL SISTEMA DEBERÁ autorizar las solicitudes concurrentes a la API protegida.
- **REQ-STA-02:** MIENTRAS se procese una rotación de tokens por heartbeat, EL SISTEMA DEBERÁ asegurar operaciones atómicas en Redis mediante pipelines/transacciones para evitar condiciones de carrera.

### 3.3 Requisitos Opcionales o Condicionales (DONDE)
- **REQ-OPT-01:** DONDE el entorno esté configurado con auditoría detallada (`AUDIT_EXTENDED_LOGGING=True`), EL SISTEMA DEBERÁ registrar en la base de datos SQL la dirección IP de origen anonimizada y el User-Agent del cliente.

### 3.4 Requisitos de Manejo de Errores y Comportamiento Indeseado (SI)
- **REQ-NEG-01:** SI el token proporcionado en la solicitud de heartbeat ha expirado, está malformado o su JTI figura en la lista de revocados en Redis, EL SISTEMA DEBERÁ rechazar la operación con código HTTP 401 Unauthorized y detalle `ERR_SESSION_EXPIRED`.
- **REQ-NEG-02:** SI el servicio Redis no responde en 1500 ms, EL SISTEMA DEBERÁ degradar de forma segura la verificación utilizando la réplica de base de datos SQL o retornar HTTP 503 Service Unavailable con log estructurado `ERROR`.

### 3.5 Requisitos Ubicuos (SIEMPRE)
- **REQ-UBI-01:** EL SISTEMA DEBERÁ validar todos los payloads y cabeceras de entrada mediante modelos estrictos Pydantic v2.
- **REQ-UBI-02:** EL SISTEMA DEBERÁ registrar todas las transiciones de sesión en la tabla SQL `session_audit_logs` con timestamp UTC y Correlation ID.

---

## 4. Requisitos No Funcionales (NFR)

| Categoría | Especificación del Requisito | Métrica / Umbral Verificable |
| :--- | :--- | :--- |
| **Rendimiento** | Latencia del endpoint de heartbeat | < 100 ms (p95) bajo carga de 500 req/s |
| **Seguridad** | Algoritmo de firma y almacenamiento seguro | Tokens firmados con Ed25519 o RS256, sin secretos en código |
| **Persistencia** | Integridad transaccional SQL | ACID garantizado en inserciones de auditoría con SQLAlchemy |
| **Calidad de Código** | Formateo y análisis estático | 0 errores con `ruff check .` y tipado estricto `mypy` |

---

## 5. Fuera de Alcance (Out of Scope)

- Implementación de interfaz gráfica o componentes frontend de temporizador.
- Modificación del esquema de contraseñas de usuarios.

---

## 6. Preguntas Abiertas y Supuestos

- [x] **Supuesto:** Conexión asíncrona a PostgreSQL/SQLite configurada con `asyncpg` / `aiosqlite`.
- [x] **Supuesto:** Redis configurado con modo de persistencia AOF/RDB para tolerancia a fallos.

---

## 7. Matriz de Trazabilidad Rally

| Atributo Rally | Valor Ingerido |
| :--- | :--- |
| **FormattedID** | `US10293` |
| **Name** | Control de Inactividad y Renovación por Heartbeat (Python) |
| **ScheduleState** | `In-Progress` |
| **Owner** | Carlos Mendoza (Security Backend Lead) |
| **Project** | Digital Banking Core API (Python) |
| **Iteration** | Sprint 24.3 |
