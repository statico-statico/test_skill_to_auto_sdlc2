# Notación EARS — Easy Approach to Requirements Syntax

## Patrones

| Patrón | Sintaxis | Uso |
|:---|:---|:---|
| **Ubicuo** | `EL SISTEMA DEBERÁ [acción]` | Requisitos que siempre se aplican |
| **Evento** | `CUANDO [evento], EL SISTEMA DEBERÁ [acción]` | Respuestas a triggers específicos |
| **Estado** | `MIENTRAS [estado], EL SISTEMA DEBERÁ [acción]` | Comportamiento durante una condición |
| **Opcional** | `DONDE [feature habilitada], EL SISTEMA DEBERÁ [acción]` | Funcionalidad configurable |
| **Negativo** | `SI [condición indeseada], EL SISTEMA DEBERÁ [respuesta]` | Manejo de errores |

## Reglas de Composición

Los patrones EARS pueden combinarse para expresar requisitos complejos:

- **Evento + Estado**: `MIENTRAS [estado], CUANDO [evento], EL SISTEMA DEBERÁ [acción]`
- **Condición + Evento**: `SI [condición], CUANDO [evento], EL SISTEMA DEBERÁ [acción]`

## Ejemplos Correctos

### Patrón Ubicuo
- EL SISTEMA DEBERÁ registrar todas las transacciones en un log de auditoría inmutable.
- EL SISTEMA DEBERÁ cifrar todos los datos sensibles en tránsito y en reposo.

### Patrón Evento (CUANDO)
- CUANDO el usuario envía un formulario con campos vacíos,
  EL SISTEMA DEBERÁ mostrar un mensaje de error por cada campo requerido faltante.

- CUANDO se recibe una solicitud de API sin token de autenticación válido,
  EL SISTEMA DEBERÁ responder con HTTP 401 y un mensaje descriptivo.

### Patrón Estado (MIENTRAS)
- MIENTRAS una transferencia está en proceso,
  EL SISTEMA DEBERÁ bloquear la cuenta origen contra retiros adicionales.

- MIENTRAS el servicio externo reporta degradación,
  EL SISTEMA DEBERÁ activar el modo de respaldo local.

### Patrón Opcional (DONDE)
- DONDE la funcionalidad de notificaciones push está habilitada,
  EL SISTEMA DEBERÁ enviar alertas en tiempo real al dispositivo del usuario.

### Patrón Negativo (SI)
- SI el servicio de pagos no responde en 30 segundos,
  EL SISTEMA DEBERÁ cancelar la transacción y notificar al usuario.

- SI la validación de datos falla en más de 3 campos,
  EL SISTEMA DEBERÁ rechazar el formulario completo sin procesamiento parcial.

## Anti-patrones

| Anti-patrón | Problema | Corrección EARS |
|:---|:---|:---|
| "El sistema debe ser rápido" | Ambiguo, no medible | CUANDO el usuario solicita una búsqueda, EL SISTEMA DEBERÁ retornar resultados EN MENOS DE 2 segundos |
| "Los usuarios deberían poder hacer cosas" | Vago, no accionable | CUANDO el usuario accede al dashboard, EL SISTEMA DEBERÁ mostrar los últimos 10 registros ordenados por fecha |
| "El sistema tiene que funcionar bien" | Sin criterio verificable | EL SISTEMA DEBERÁ mantener un uptime del 99.9% medido mensualmente |
| "Debería manejar errores" | Incompleto | SI ocurre un error de conexión a la base de datos, EL SISTEMA DEBERÁ reintentar 3 veces con backoff exponencial y notificar al administrador si falla |

## Guía de Selección de Patrón

```
¿El requisito aplica SIEMPRE?
  └─ SÍ → Patrón UBICUO
  └─ NO → ¿Depende de un EVENTO discreto?
            └─ SÍ → Patrón EVENTO (CUANDO)
            └─ NO → ¿Depende de un ESTADO continuo?
                      └─ SÍ → Patrón ESTADO (MIENTRAS)
                      └─ NO → ¿Es una feature CONFIGURABLE?
                                └─ SÍ → Patrón OPCIONAL (DONDE)
                                └─ NO → ¿Describe un FALLO o ERROR?
                                          └─ SÍ → Patrón NEGATIVO (SI)
```
