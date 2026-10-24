# Requerimientos: US98765 — Implementar Autenticación de Dos Factores (2FA)

> **Rally ID:** US98765
> **Iteración:** Sprint 2024-Q4-03
> **Fecha de generación:** 2024-12-15
> **Generado por:** SDLC Automation Agent

---

## Descripción Funcional

El sistema requiere la implementación de autenticación de dos factores (2FA) para
incrementar la seguridad del proceso de inicio de sesión. Los usuarios podrán
configurar 2FA mediante una aplicación autenticadora (Google Authenticator, Authy)
o recibir códigos de verificación por SMS. La funcionalidad debe ser opcional
pero fuertemente recomendada para cuentas con permisos administrativos.

## Historia de Usuario

**Como** usuario con cuenta activa en el sistema,
**quiero** poder configurar autenticación de dos factores en mi perfil,
**para** proteger mi cuenta contra accesos no autorizados incluso si mi contraseña es comprometida.

## Criterios de Aceptación (Notación EARS)

### Requisitos de Evento (CUANDO)
- CUANDO el usuario accede a la configuración de seguridad de su perfil, EL SISTEMA DEBERÁ
  mostrar la opción de activar 2FA con al menos dos métodos disponibles (App y SMS)
  EN MENOS DE 2 segundos.

- CUANDO el usuario escanea el código QR con su aplicación autenticadora, EL SISTEMA DEBERÁ
  validar el código TOTP ingresado y confirmar la activación EN MENOS DE 3 segundos.

- CUANDO un usuario con 2FA activo intenta iniciar sesión con credenciales válidas,
  EL SISTEMA DEBERÁ solicitar el código de verificación antes de conceder acceso.

### Requisitos de Estado (MIENTRAS)
- MIENTRAS el proceso de configuración de 2FA está en curso, EL SISTEMA DEBERÁ
  mantener la sesión activa sin timeout durante al menos 10 minutos.

- MIENTRAS la verificación 2FA está pendiente, EL SISTEMA DEBERÁ
  bloquear el acceso a todas las funcionalidades protegidas.

### Requisitos Negativos (SI — manejo de errores)
- SI el usuario ingresa un código TOTP inválido 5 veces consecutivas,
  EL SISTEMA DEBERÁ bloquear la cuenta temporalmente por 15 minutos
  y notificar al administrador.

- SI el servicio de SMS no está disponible, EL SISTEMA DEBERÁ
  ofrecer el método alternativo (App) y mostrar un mensaje de error descriptivo.

- SI el usuario pierde acceso a su dispositivo 2FA, EL SISTEMA DEBERÁ
  proporcionar un flujo de recuperación mediante códigos de respaldo generados
  durante la configuración inicial.

### Requisitos Ubicuos (SIEMPRE)
- EL SISTEMA DEBERÁ generar 10 códigos de respaldo únicos de 8 caracteres
  durante la activación de 2FA.
- EL SISTEMA DEBERÁ registrar todos los intentos de verificación 2FA en el log de auditoría.

## Requisitos No Funcionales

| Categoría | Requisito | Métrica |
|:---|:---|:---|
| **Rendimiento** | Validación de código TOTP | < 500ms |
| **Seguridad** | Códigos TOTP válidos por ventana temporal | 30 segundos (RFC 6238) |
| **Disponibilidad** | Servicio 2FA operativo | 99.9% uptime |
| **Escalabilidad** | Usuarios concurrentes con 2FA | Soportar 10,000 validaciones/min |

## Fuera de Alcance

- Autenticación biométrica (fingerprint, facial recognition)
- 2FA por email (solo App y SMS en esta iteración)
- Integración con hardware keys (FIDO2/WebAuthn) — planificada para Sprint Q1-2025

## Preguntas Abiertas

- [x] ¿Se requiere 2FA obligatorio para administradores? → SÍ, confirmado por PO
- [x] ¿Qué proveedor de SMS usar? → Twilio, ya contratado
- [ ] ¿Los códigos de respaldo deben tener expiración? → Pendiente decisión del PO

## Dependencias

| Tipo | Descripción | Estado |
|:---|:---|:---|
| Upstream | US98700 — Refactorización del módulo de autenticación | ✅ Completado |
| External | Twilio SMS API — Cuenta de producción configurada | ✅ Disponible |
| Downstream | US98800 — Dashboard de seguridad del administrador | ⏳ En progreso |

## Trazabilidad

| Campo Rally | Valor |
|:---|:---|
| FormattedID | US98765 |
| Name | Implementar Autenticación de Dos Factores (2FA) |
| ScheduleState | In-Progress |
| Iteration | Sprint 2024-Q4-03 |
| Owner | jgarcia@company.com |
| Project | Backend Platform |
| PlanEstimate | 8 |
| Tags | security, authentication, high-priority |
