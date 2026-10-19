# Finanzas · app móvil (Flutter)

App móvil de cargos y abonos. Implementa el diseño “Finanzas — diseño de la app”
(Material 3, Manrope + IBM Plex Mono, verde `#0F5F4F`).

- **Auth:** Neon Auth (Managed Better Auth). Google OAuth en el navegador del sistema (Custom Tabs / ASWebAuthenticationSession) o correo/contraseña.
- **Datos:** Neon Data API (REST tipo PostgREST) con el JWT de Neon Auth. RLS en Postgres.
  La app no guarda credenciales de base de datos.

## Arquitectura por capas

```
lib/
  app/          composición: DI (di.dart), router, shell, MaterialApp
  core/         tema, config, cliente Data API, errores, utilidades, widgets comunes
  features/<feature>/
    domain/        entidades + interfaces de repositorio (Dart puro)
    data/          datasources (HTTP) + modelos JSON + repositorios concretos
    presentation/  providers Riverpod + páginas + widgets
```

Features: `auth`, `resumen` (Inicio), `movimientos`, `metas`, `categorias`, `cuentas`, `ajustes`.
La presentación solo usa interfaces de dominio. Las implementaciones se conectan en `lib/app/di.dart`.

### Sin N+1

- Cada pantalla hace un número fijo de peticiones, sin importar cuántas filas haya:
  - **Inicio:** 2 peticiones en paralelo (RPC `app_resumen_periodo` + `SELECT … LIMIT 4`).
  - **Movimientos:** 1 por página (filtros, orden y `limit/offset` en el servidor; se pide `limit+1` para saber si hay más sin `COUNT`).
  - **Categorías / Cuentas:** 1 RPC con `LEFT JOIN … GROUP BY` (`app_categorias_con_totales`, `app_cuentas_con_conteo`).
  - **Metas:** 1 `SELECT`. El aporte usa la RPC atómica `app_aportar_meta`, que devuelve la fila y actualiza solo esa en memoria.
  - **Exportar CSV:** 1 `GET` con `Accept: text/csv`, serializado por el servidor.
- Los catálogos (categorías, cuentas) se piden una vez por sesión y se reutilizan.
- El refresco del JWT es *single-flight*: N peticiones concurrentes → 1 llamada a `/get-session`.
- La búsqueda tiene *debounce* (350 ms) y las ediciones envían solo los campos cambiados.

## Configuración

### 1. Neon

1. En Neon Console → **Auth**: habilítalo y activa **Google**. Las credenciales compartidas de Neon sirven
   para desarrollo. Con credenciales propias (Web client), el redirect URI en Google Cloud es `{NEON_AUTH_URL}/callback/google`.
2. En **Auth → Configuration → Trusted domains** agrega:
   - `http://localhost:43821` (callback loopback del OAuth). Sin esto, Neon responde `INVALID_CALLBACKURL`.
   - El valor de `NEON_AUTH_ORIGIN`, p. ej. `https://finanzas.app`.
3. **Data API**: habilítala con Neon Auth como proveedor.
4. Ejecuta la migración (aditiva, sobre tus tablas `movimientos` y `categorias`):
   ```bash
   for f in db/migrations/00*.sql; do psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
   ```
   Después, en **Postgres database → Data API**, pulsa **Refresh schema cache**. La Data API guarda el
   esquema en caché y no ve funciones ni tablas nuevas hasta refrescarla (`NOTIFY pgrst` no basta).
5. Inicia sesión una vez en la app y autoriza tu usuario (lista blanca de RLS):
   ```sql
   insert into public.usuarios_permitidos (user_id)
   select id::text from neon_auth."user" where email = '<tu correo>';
   ```
   Hasta entonces, la Data API responde vacío o `403` para esa cuenta.

> El servidor MCP de Claude se conecta como dueño de la base y no pasa por RLS, así que sigue funcionando igual.

No se necesitan clients OAuth de Android/iOS ni SHA-1: Google solo habla con Neon Auth.

### 2. Variables

```bash
cp env.example.json env.json   # edita los valores; env.json está en .gitignore
flutter run --dart-define-from-file=env.json
```

| Clave | Valor |
|---|---|
| `NEON_AUTH_URL` | Auth URL de la rama (Console → Auth → Configuration) |
| `NEON_DATA_API_URL` | REST endpoint de la Data API (termina en `/rest/v1`) |
| `NEON_AUTH_ORIGIN` | Origen de confianza que se envía como `Origin` (las apps nativas no tienen uno) |

## Release (orbixmx.com)

En desarrollo el OAuth regresa por loopback (`http://localhost:43821`). En release usa una
página puente en tu dominio:

1. **Puente:** publica `https://finanzas.orbixmx.com/auth` (Cloudflare Worker), que redirige a `finanzas://auth?…`.
   Opciones (estática, Cloudflare, nginx, Vercel) en [deploy/orbixmx/README.md](deploy/orbixmx/README.md).
2. **Neon Console → Auth → Trusted domains:** agrega `https://finanzas.orbixmx.com`.
3. **Google Cloud:** el redirect URI del Web client sigue siendo `{NEON_AUTH_URL}/callback/google`.
   En la *pantalla de consentimiento*, agrega `orbixmx.com` como dominio autorizado y publica la app
   (en modo *Testing* solo entran los usuarios de prueba).
4. **Variables:** `cp env.release.example.json env.release.json` y llena los valores.
5. **Firma Android:**
   ```bash
   keytool -genkey -v -keystore C:/Users/carlo/keys/finanzas-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias finanzas
   ```
   Copia `android/key.properties.example` a `android/key.properties` con tus contraseñas.
   Respalda el `.jks` y las contraseñas: sin ellos no podrás publicar actualizaciones.
6. **Compilar:**
   ```bash
   flutter build appbundle --release --dart-define-from-file=env.release.json
   ```
   Para instalar directo (sin Play), usa `flutter build apk --release --dart-define-from-file=env.release.json`.

## Flujo de autenticación

```
POST {auth}/sign-in/social {provider:"google", callbackURL:"http://localhost:43821/auth"}
  └─ { url } + Set-Cookie session_challenge
Navegador del sistema → Google → {auth}/callback/google
  → http://localhost:43821/auth?neon_auth_session_verifier=…   (servidor efímero en 127.0.0.1 de la app)
  → 302 finanzas://auth  (cierra el navegador y vuelve a la app)
GET {auth}/get-session?neon_auth_session_verifier=… (Cookie challenge)
  └─ Set-Cookie session_token → Keychain/Keystore  +  header set-auth-jwt (JWT corto)
Data API  Authorization: Bearer <JWT>  → RLS: auth.user_id() ∈ usuarios_permitidos
```

Ante un `401`, el JWT se refresca una vez y se reintenta. Si vuelve a fallar, se cierra la sesión.
Con el desbloqueo biométrico activado, la sesión guardada queda bloqueada hasta validar huella o Face ID.

## Pendiente / fuera de alcance

- El interruptor “Avisos de nuevos movimientos” solo guarda la preferencia. Falta conectar push (FCM/APNs).
- Las pantallas web (Login y Dashboard) del diseño no forman parte de esta app móvil.

## Tests

```bash
flutter analyze
flutter test
```
