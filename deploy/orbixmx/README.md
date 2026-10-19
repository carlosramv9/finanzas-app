# Puente OAuth en orbixmx.com

Neon Auth solo acepta callbacks `https://` de un dominio de confianza. Esta ruta
recibe el callback y lo reenvía al deep link de la app:

```
https://orbixmx.com/finanzas/auth?neon_auth_session_verifier=XYZ
  → finanzas://auth?neon_auth_session_verifier=XYZ
```

Elige **una** de estas formas según dónde esté alojado orbixmx.com. La redirección
302 del servidor es la más confiable. La página HTML sirve para hosting estático
y trae un botón de respaldo.

## A. Página estática (cualquier hosting)

Sube `finanzas/auth/index.html` para que responda en `https://orbixmx.com/finanzas/auth`.

## B. Cloudflare (Worker en la ruta `orbixmx.com/finanzas/auth*`)

```js
export default {
  fetch(req) {
    const { search } = new URL(req.url);
    return new Response(null, {
      status: 302,
      headers: { Location: `finanzas://auth${search}`, 'Cache-Control': 'no-store' },
    });
  },
};
```

## C. nginx

```nginx
location = /finanzas/auth {
    add_header Cache-Control no-store;
    return 302 finanzas://auth$is_args$args;
}
```

## D. Vercel / Next.js (`next.config.js` o middleware)

```js
// middleware.ts
import { NextResponse } from 'next/server';
export function middleware(req) {
  if (req.nextUrl.pathname === '/finanzas/auth') {
    return NextResponse.redirect(`finanzas://auth${req.nextUrl.search}`, 302);
  }
}
```

Comprueba que el query string llegue intacto:

```bash
curl -sI "https://orbixmx.com/finanzas/auth?neon_auth_session_verifier=prueba"
```

Con B, C o D la respuesta debe ser `Location: finanzas://auth?neon_auth_session_verifier=prueba`.
