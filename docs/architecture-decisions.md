# Architecture Decision Records (ADR)
## ROSports.app — MVP

---

### ADR-001 — Flutter como framework móvil

**Estado:** Aprobado  
**Fecha:** Junio 2026

**Decisión:** Usar Flutter (Dart) para el desarrollo de la app móvil.

**Razones:**
- Un solo codebase para iOS y Android
- Rendimiento cercano a nativo
- Madurez del ecosistema en 2026
- Soporte robusto para animaciones, mapas y plugins nativos
- Reducción de costo de desarrollo con un solo dev

**Alternativas consideradas:** React Native (descartado por menor rendimiento en UI compleja), nativo Swift/Kotlin (descartado por costo de mantenimiento doble)

---

### ADR-002 — Supabase como backend principal

**Estado:** Aprobado  
**Fecha:** Junio 2026

**Decisión:** Usar Supabase (PostgreSQL + Auth + Storage + Realtime + Edge Functions)

**Razones:**
- Todo-en-uno: reduce la cantidad de servicios a gestionar
- PostgreSQL como DB relacional sólida para queries complejas de reservas
- RLS nativo para seguridad por fila sin código adicional
- Realtime integrado para disponibilidad en vivo
- Edge Functions para lógica de negocio serverless
- Plan gratuito suficiente para desarrollo y beta temprana

**Alternativas consideradas:** Firebase (descartado por limitaciones de queries complejas en Firestore), AWS (descartado por complejidad operacional para un solo dev)

---

### ADR-003 — Riverpod como gestor de estado

**Estado:** Aprobado  
**Fecha:** Junio 2026

**Decisión:** Usar flutter_riverpod para gestión de estado

**Razones:**
- Compilación segura (sin ProviderNotFoundError en runtime)
- Mejor integración con Clean Architecture que Provider
- Soporte nativo para async/await con AsyncValue
- Code generation con riverpod_annotation reduce boilerplate

**Alternativas consideradas:** BLoC (más verboso para este proyecto), Provider (predecesor con limitaciones conocidas)

---

### ADR-004 — Comisión del 10% en Año 1

**Estado:** Aprobado  
**Fecha:** Junio 2026

**Decisión:** Cobrar 10% de comisión sobre cada reserva pagada durante el primer año

**Razones:**
- Precio competitivo frente a Playtomic (~15%) y otras plataformas
- Suficiente para validar el modelo de monetización
- Se reduce al 5% a partir del Año 2 como incentivo de fidelización

**Impacto técnico:** Campo `commission` en tabla `reservations` calculado y almacenado en creación

---

### ADR-005 — Bloqueo temporal de slot por 10 minutos

**Estado:** Aprobado  
**Fecha:** Junio 2026

**Decisión:** Al iniciar el checkout, marcar el slot como `pending` durante 10 minutos máximo

**Razones:**
- Previene doble booking durante el flujo de pago
- 10 minutos es suficiente para completar el pago en móvil
- Si expira sin pago, se libera automáticamente (job programado o trigger)

**Implementación:** Constraint UNIQUE en `(court_id, start_time)` + UPDATE con TTL en availability_slots
