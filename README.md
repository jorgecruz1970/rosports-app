# ROSports.app — Mono-repo

Plataforma móvil para reserva de canchas deportivas y partidos abiertos.

- **Dominio:** https://rosports.app
- **Ciudad piloto:** Bogotá, Colombia
- **Stack:** Flutter + Supabase + PayU/MercadoPago

## Estructura del repositorio

```
rosports-app/
├── mobile/          # Flutter app (iOS + Android)
├── backend/         # Supabase Edge Functions
├── infra/           # SQL migrations y seeds
├── docs/            # Documentación técnica
└── .github/         # GitHub Actions CI/CD
```

## Setup rápido

### Pre-requisitos

- Flutter SDK >= 3.19 (stable)
- Dart >= 3.3
- Android Studio / Xcode
- Supabase CLI (`npm install -g supabase`)
- Node.js >= 18 (para Edge Functions)

### 1. Clonar el repo

```bash
git clone https://github.com/tu-org/rosports-app.git
cd rosports-app
```

### 2. Configurar variables de entorno

```bash
cp mobile/.env.example mobile/.env
# Editar mobile/.env con tus valores de Supabase, PayU, Firebase
```

### 3. Aplicar migraciones SQL

```bash
cd infra
supabase db reset   # aplica todas las migraciones en orden
```

### 4. Correr la app Flutter

```bash
cd mobile
flutter pub get
flutter run
```

## Comandos útiles

| Comando | Descripción |
|---|---|
| `flutter run` | Correr en emulador/dispositivo |
| `flutter test` | Ejecutar tests unitarios |
| `flutter analyze` | Análisis estático del código |
| `flutter build apk` | Build Android release |
| `flutter build ios` | Build iOS release |
| `supabase functions serve` | Correr Edge Functions en local |
| `supabase db diff` | Ver cambios pendientes en DB |

## Contacto

**CTO:** Jorge M. Cruz Pereira  
**Email:** jorgem.cruz@gmail.com
