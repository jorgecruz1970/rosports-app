# Configuración Auth — Supabase Dashboard
## ROSports.app

### Authentication → URL Configuration

Ir a: https://supabase.com/dashboard/project/jbhcxsortawvezgqbubn/auth/url-configuration

#### Site URL
```
app.rosports.mobile://login-callback
```

#### Redirect URLs (agregar todas estas)
```
app.rosports.mobile://login-callback
app.rosports.mobile://reset-password
http://localhost:3000
```

> Clic en "Add URL" para cada una → Save

---

### Authentication → Email Templates

Ir a: Authentication → Email Templates

#### Confirm signup
- Subject: `Confirma tu cuenta en ROSports`
- Body: dejar el default por ahora

#### Reset Password  
- Subject: `Restablecer contraseña — ROSports`
- Body: dejar el default por ahora

---

### Authentication → Settings

- **Enable email confirmations:** OFF (durante desarrollo)
  Volver a ON antes de lanzamiento en producción
- **Minimum password length:** 6
- **JWT expiry:** 604800 (7 días)
