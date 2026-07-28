# SILONET — Bodega WEB

App web de gestión de contraseñas, totalmente offline, cifrada con AES-256-GCM del lado del cliente, con soporte multi-usuario y sincronización cloud vía Vercel + GitHub Gist.

---

## Arquitectura general

- **Single HTML file**: toda la app vive en un único `index.html` (y `mobil.html` para la versión mobile). No hay frameworks, no hay bundlers, no hay dependencias externas. Funciona abriendo el archivo directamente desde el disco (`file://`) o sirviéndolo con cualquier HTTP server.
- **Cifrado cliente**: nunca salen datos sin cifrar del navegador. La clave se deriva de la contraseña maestra + salt mediante PBKDF2 (SHA-256). El cifrado es AES-256-GCM con IV aleatorio de 12 bytes.
- **Persistencia local**: `localStorage` guarda el salt (`claves_salt_{user}`) y el vault cifrado (`claves_vault_{user}`). `sessionStorage` guarda el draft al editar una entrada.
- **Sincronización cloud**: cuando se sirve desde Vercel, un `fetch('/api/health')` detecta que la API está disponible y activa el modo `useApi`. Cada vez que se guarda, además de localStorage, hace un PUT a los endpoints de Vercel que escriben en un GitHub Gist privado.

---

## Versionado

- `VERSION = '1.2.0'`
- Fechas de modificaciones no trackeadas en el código (ver git log).

---

## Estructura de archivos

```
silonet/
├── index.html          # App principal (desktop)
├── mobil.html          # Versión mobile (touch optimizada)
├── vercel.json         # Config de deploy en Vercel
├── setup.ps1           # Script para crear el gist inicial
├── .gitignore
├── api/
│   ├── health.js       # Health check (GET)
│   ├── vault.js        # CRUD del vault cifrado (GET/PUT)
│   └── salt.js         # CRUD del salt (GET/PUT)
└── SILONET.md          # Este documento
```

---

## Funcionalidades

### 🔐 Login multi-usuario

- Selector de usuario en la pantalla de login: **Silvina** (ID `1`) y **Sandro** (ID `2`).
- Cada usuario tiene su propio salt, su propio vault cifrado con su propia contraseña maestra, y sus propios archivos en el gist.
- `currentUser()`: lee de localStorage `claves_last_user` (default `'1'`).
- `setUser(id)`: guarda el usuario activo y actualiza `KEY_SALT` y `KEY_VAULT` a `claves_salt_{id}` y `claves_vault_{id}`.
- Al cambiar de usuario, se resetea el formulario de login y se llama a `checkState()` para determinar si ese usuario ya tiene vault o hay que crear uno nuevo.

### 🔑 Derivación de clave

- `deriveKey(pw, salt)`: SHA-256(pwBytes + salt) → importKey raw AES-GCM.
- El salt se genera con `crypto.getRandomValues(new Uint8Array(16))` al crear el vault y se guarda en base64.
- Se usa el mismo salt para cifrar/descifrar mientras no cambie la contraseña maestra.

### 🔒 Cifrado/descifrado

- `enc(plain, key)`: AES-256-GCM con IV aleatorio de 12 bytes. Retorna `{iv: base64, data: base64}`.
- `dec(pkt, key)`: recibe `{iv, data}`, descifra y parsea JSON.
- `reencrypt(oldKey, newKey)`: descifra el vault con la clave vieja y lo vuelve a cifrar con la nueva (al cambiar la contraseña maestra).

### 📋 CRUD de entradas

- `addEntry(data)`: agrega una entrada con `id: crypto.randomUUID()`, llama a `persist()`.
- `updateEntry(id, data)`: modifica una entrada existente, llama a `persist()`.
- `deleteEntry(id)`: elimina una entrada, llama a `persist()`.
- `importFromCSV(text)`: parsea CSV con columnas `service,username,password,note,url` y las importa como entradas.
- `exportCSV()`: genera un CSV descargable con todas las entradas.

### 📱 Vista mobile

- `mobil.html`: misma lógica que `index.html` pero con layout siempre single-column, panel de detalle como overlay fijo, targets táctiles más grandes, y sin breakpoints responsive.
- Compatible con iOS y Android. Se puede agregar a la pantalla de inicio como bookmark.

### 🌐 URL field

- Cada entrada puede tener un campo `url` opcional.
- Se muestra como link clickeable en el detalle y en la vista de cards.
- Botón de copiar URL al lado del link.
- Se incluye en CSV de exportación y en el draft.

### ❤️ Favoritos

- Botón de estrella en cada entrada para marcarla como favorita.
- Las favoritas aparecen primero en la lista principal.
- Se almacenan como un `Set` de IDs en el vault (`S.favSet`).

### 🔍 Búsqueda y ordenamiento

- `searchInput`: filtra entradas por `service`, `username`, `note`, `url` (case-insensitive).
- `listSort`: ordena por más recientes, más antiguos, A-Z, Z-A.

### 👁️ Visor de contraseñas

- Botón "👁" en cada entrada para mostrar/ocultar la contraseña.
- Auto-oculta después de 30 segundos (`CLIP_MS`).

### 📥 Importación desde archivo

- `importFromLogin()`: en la pantalla de login, botón para importar un vault desde un archivo JSON.
- `exportVault()`: desde configuración o botón 💾, descarga el vault completo como JSON.
- `Settings → Importar URLs`: importa archivo `claves-urls.json` con pares `{service, url}`.
- `Settings → Exportar URLs`: descarga las URLs como `claves-urls.json`.

### 🔄 Sincronización Vercel + GitHub Gist

- `checkApi()`: hace `fetch('/api/health')` con timeout de 3 segundos. Si responde OK y tiene `hasToken && hasGistId`, activa `useApi = true`.
- `syncPull()`: hace GET a `/api/salt?user=X` y `/api/vault?user=X`, guarda los datos en localStorage.
- `syncPush()`: hace PUT a `/api/salt?user=X` y `/api/vault?user=X` con los datos de localStorage.
- `persist()`: siempre guarda en localStorage primero (funciona siempre), luego si `useApi` está activo llama a `syncPush()`.
- `init()`: al cargar la app, llama a `checkApi()` → si hay API, `syncPull()` para traer los datos más recientes.

### ⏱️ Inactividad

- `INACTIVITY_MS = 5 * 60 * 1000` (5 minutos).
- Un timer se resetea con cada interacción (`mousedown`, `keydown`, `touchstart`).
- Al vencer, se ejecuta `lock()` que vuelve a la pantalla de login y limpia la clave en memoria.

### 🎨 Matrix rain background

- Canvas con columnas de caracteres katakana cayendo.
- **Login screen**: verde clásico (#0f0).
- **App**: colores HSL cíclicos (multicolor).
- Los paneles son semi-transparentes (82% de opacidad) para que el matrix se vea tenuemente por detrás.

### 🔄 Reset completo

- `location.search.includes('reset')`: si la URL tiene `?reset`, borra los datos del usuario actual de localStorage.
- Botón "Limpiar vault y empezar de nuevo" en la pantalla de login (hace `localStorage.clear()` + reload).

---

## API endpoints (Vercel serverless)

### GET /api/health

Retorna `{ok: true, hasToken: bool, hasGistId: bool, node: "v18.x"}`.

### GET /api/salt?user=1

Lee del gist el archivo `{user}-salt.txt`. Retorna `{salt: "base64..."}`.

### PUT /api/salt?user=1

Recibe `{salt: "base64..."}` y escribe el archivo `{user}-salt.txt` en el gist.

### GET /api/vault?user=1

Lee del gist el archivo `{user}-vault.json`. Retorna `{iv: "base64...", data: "base64..."}`.

### PUT /api/vault?user=1

Recibe `{iv: "base64...", data: "base64..."}` y escribe el archivo `{user}-vault.json` en el gist.

---

## Variables de entorno (Vercel)

| Variable | Descripción |
|---|---|
| `GITHUB_TOKEN` | Token clásico de GitHub con scope `gist` |
| `GIST_ID` | ID del gist privado (ej: `bfb1e16abacedd12760dbab147b060b7`) |

---

## GitHub Gist structure

```
gist/
├── 1-vault.json    # Vault cifrado de Silvina
├── 1-salt.txt      # Salt de Silvina (base64)
├── 2-vault.json    # Vault cifrado de Sandro
└── 2-salt.txt      # Salt de Sandro (base64)
```

Los archivos se crean con contenido placeholder. La primera vez que un usuario crea su vault, se reemplazan con datos reales.

---

## Configuraciones y constantes clave

| Constante | Valor | Propósito |
|---|---|---|
| `KEY_SALT` | `claves_salt_{user}` | Clave localStorage para el salt |
| `KEY_VAULT` | `claves_vault_{user}` | Clave localStorage para el vault |
| `KEY_DRAFT` | `claves_draft` | Clave sessionStorage para el draft |
| `KEY_LAST_USER` | `claves_last_user` | Clave localStorage para recordar el último usuario |
| `INACTIVITY_MS` | `300000` (5 min) | Timeout de bloqueo por inactividad |
| `CLIP_MS` | `30000` (30 s) | Tiempo hasta ocultar contraseña mostrada |
| `API_BASE` | `/api` | Base URL para endpoints de sincronización |
| `VERSION` | `'1.2.0'` | Versión actual de la app |

---

## Deploy

### Requisitos

- Cuenta en GitHub
- Cuenta en Vercel (gratuita, se conecta con GitHub)

### Pasos

1. Crear un repositorio en GitHub con el contenido de este proyecto.
2. Crear un token clásico de GitHub con solo el scope `gist`.
3. Ejecutar `setup.ps1` o crear manualmente un gist privado con los 4 archivos (`1-vault.json`, `1-salt.txt`, `2-vault.json`, `2-salt.txt`). Anotar el Gist ID.
4. En Vercel, importar el repositorio y configurar las variables de entorno `GITHUB_TOKEN` y `GIST_ID`.
5. Deployar. La app queda accesible en `https://{project}.vercel.app`.

### Notas

- No requiere build command ni output directory.
- El plan gratuito de Vercel tiene límite de 10 segundos de ejecución por función serverless (configurado en `vercel.json` como `maxDuration: 10`).
- No se necesita Vercel KV ni base de datos externa — todo el almacenamiento es el gist de GitHub.

---

## Seguridad

- **Zero-knowledge**: el servidor nunca ve las contraseñas ni los datos sin cifrar. Todo el cifrado/descifrado ocurre en el navegador con Web Crypto API.
- **Cifrado**: AES-256-GCM con IV único por operación.
- **Derivación de clave**: SHA-256 (PBKDF2-like simplificado: hash(password + salt)).
- **Separación de usuarios**: cada usuario tiene su propio salt y vault independientes. Aunque compartan el mismo gist, no pueden descifrar los datos del otro sin la contraseña maestra correspondiente.
- **Token con mínimo privilegio**: el `GITHUB_TOKEN` solo tiene scope `gist` — no puede leer repos, no puede modificar el perfil, solo leer/escribir gists.

---

## Convenciones de código

- JavaScript moderno (ES2020+): async/await, arrow functions, destructuring, template literals, optional chaining.
- IDs de elementos con kebab-case.
- Variables del DOM con prefijo: `mp` (master password), `mpc` (confirm), `loginBtn`, etc.
- Estado global en `S` (State object).
- Funciones de utilidad: `$('id')` para `document.getElementById`, `b64`/`fb64` para base64, `esc` para escape HTML.
- `diagMsg()` para logging de diagnóstico en un overlay oculto en la pantalla de login.
- Toast notifications con `toast(msg, type)` donde type puede ser `'success'`, `'error'`, `'info'`.

---

## Posibles mejoras futuras

- [ ] Drag & drop para reordenar entradas
- [ ] Tags / categorías configurables
- [ ] Soporte para más de 2 usuarios
- [ ] PWA con service worker (requiere HTTPS, no funciona en file://)
- [ ] Autocompletado de contraseñas en formularios (WebAuthn / Credential Management API)
- [ ] Modo oscuro configurable (actualmente siempre oscuro)
