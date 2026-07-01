# GitHub Repository Setup Guide
## ROSports.app — Configuración post-push

Repo: https://github.com/jorgecruz1970/rosports-app

---

## 1. Estructura de ramas

```
main          ← producción (protegida, solo merge via PR)
develop       ← integración (protegida, solo merge via PR)
feature/*     ← desarrollo de features por sprint
hotfix/*      ← correcciones urgentes sobre main
```

### Flujo de trabajo
```
feature/xxx → develop → main
hotfix/xxx  → main + develop
```

---

## 2. Branch Protection Rules

> ⚠️ **Nota:** Las branch protection rules en repos **privados** requieren
> GitHub Team ($4/mes) o Enterprise. En plan Free solo funcionan en repos públicos.
>
> **Opciones disponibles:**
> - **Opción A (recomendada MVP):** Hacer el repo público — las reglas funcionan gratis
>   y GitHub Actions tiene 2.000 min/mes gratis vs 500 en privado.
>   Settings → General → Change repository visibility → Make public
> - **Opción B:** Upgradar a GitHub Team ($4/mes)
> - **Opción C:** Mantener privado sin protecciones técnicas — el CI/CD igual corre
>   en cada push y avisa si algo falla. Válido para 1 solo dev.

### Si eliges Opción A o B — configurar estas reglas:

#### Regla para `main`
- Branch name pattern: `main`
- ✅ Require a pull request before merging
  - ✅ Require approvals: 1
  - ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require status checks to pass before merging
  - Status check requerido: `Flutter Analyze & Test`
- ✅ Require branches to be up to date before merging
- ✅ Do not allow bypassing the above settings

#### Regla para `develop`
- Branch name pattern: `develop`
- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging
  - Status check requerido: `Flutter Analyze & Test`
- ✅ Require branches to be up to date before merging

---

## 3. GitHub Secrets — CI/CD

### Configurar en: Settings → Secrets and variables → Actions → New repository secret

#### Secrets de Supabase
| Secret | Descripción | Dónde obtener |
|--------|-------------|----------------|
| `SUPABASE_URL` | URL del proyecto Supabase | Supabase Dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Clave pública anon | Supabase Dashboard → Project Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Clave de servicio (solo backend) | Supabase Dashboard → Project Settings → API |

#### Secrets de Sentry
| Secret | Descripción | Dónde obtener |
|--------|-------------|----------------|
| `SENTRY_DSN` | DSN del proyecto Sentry | sentry.io → Project → Settings → Client Keys |

#### Secrets de Google Maps
| Secret | Descripción | Dónde obtener |
|--------|-------------|----------------|
| `GOOGLE_MAPS_API_KEY` | API Key de Google Maps | Google Cloud Console → APIs & Services → Credentials |

#### Secrets de iOS (para CD a TestFlight)
| Secret | Descripción | Dónde obtener |
|--------|-------------|----------------|
| `APP_STORE_CONNECT_KEY_ID` | ID de la API Key de App Store Connect | appstoreconnect.apple.com → Users → Keys |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID de App Store Connect | Misma página que arriba |
| `APP_STORE_CONNECT_KEY_CONTENT` | Contenido del archivo .p8 (base64) | Descargar .p8 y convertir: `base64 -i AuthKey.p8` |
| `MATCH_PASSWORD` | Password para cifrar certificados con Fastlane Match | Definir un password seguro |
| `MATCH_GIT_URL` | URL del repo privado con certificados Match | Crear repo privado: `github.com/jorgecruz1970/rosports-certs` |

#### Secrets de Android (para CD a Play Console)
| Secret | Descripción | Dónde obtener |
|--------|-------------|----------------|
| `ANDROID_KEYSTORE_BASE64` | Keystore de firma en base64 | `base64 -i rosports.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Password del keystore | El que definiste al crear el keystore |
| `ANDROID_KEY_ALIAS` | Alias de la clave | El que definiste al crear el keystore |
| `ANDROID_KEY_PASSWORD` | Password de la clave | El que definiste al crear el keystore |
| `PLAY_STORE_JSON_KEY` | JSON de la cuenta de servicio de Google Play | Play Console → Setup → API access → Create service account |

---

## 4. Crear el Android Keystore (una sola vez)

Ejecuta este comando en tu terminal (requiere Java/keytool):

```bash
keytool -genkey -v \
  -keystore rosports.keystore \
  -alias rosports \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Guarda el archivo `rosports.keystore` en un lugar seguro.  
**Nunca lo subas al repositorio.**

Luego conviértelo a base64 para el secret:
```bash
# Mac/Linux
base64 -i rosports.keystore | pbcopy

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("rosports.keystore")) | Set-Clipboard
```

---

## 5. Configurar Fastlane Match (iOS — una sola vez)

```bash
# Crear repo privado para certificados
# github.com/jorgecruz1970/rosports-certs (privado)

# Inicializar Match
cd mobile/ios
bundle exec fastlane match init
# Seleccionar: git
# URL: https://github.com/jorgecruz1970/rosports-certs.git

# Generar certificados AppStore
bundle exec fastlane match appstore --app_identifier app.rosports.mobile
```

---

## 6. Variables de entorno para desarrollo local

Copia y completa el archivo `.env`:

```bash
cp mobile/.env.example mobile/.env
```

Edita `mobile/.env` con tus valores reales de Supabase sandbox.

Para correr la app con las variables:
```bash
cd mobile
flutter run --dart-define-from-file=.env
```

---

## 7. Resumen del flujo Git para el Sprint 1

```bash
# Arrancar una tarea del backlog
git checkout develop
git pull origin develop
git checkout -b feature/ROSP-30-infra-setup

# Trabajar... commits frecuentes
git add .
git commit -m "feat(infra): configurar Supabase y schema SQL"

# Subir y crear PR hacia develop
git push -u origin feature/ROSP-30-infra-setup
# → Abrir PR en GitHub: feature/ROSP-30-infra-setup → develop
# → CI corre automáticamente (lint + tests)
# → Merge cuando pase el CI
```

---

## 8. Primer Sprint recomendado (Sprint 1 — 2 semanas)

Épicas a atacar en paralelo:

| # | Historia | Épica |
|---|----------|-------|
| ROSP-30 | Setup infraestructura base (Supabase + repo) | E7 |
| ROSP-35 | Configurar FCM | E8 |
| ROSP-01 | Registro con email | E1 |
| ROSP-02 | Login Google + Apple | E1 |
| ROSP-37 | Política de privacidad y T&C | E9 |

Objetivo del Sprint 1: **Auth funcionando end-to-end + Supabase conectado**
