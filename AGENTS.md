# AGENTS.md — Contexto de sesión (29-Jul-2026)

## Estado actual
Commits del día: `6cda333` → `c35c377` (14 commits)

## Cambios realizados hoy

### Diseño login
- **Glassmorphism**: login card con `backdrop-filter:blur(24px)`, fondo `rgba(0,0,0,0.05)`, bordes sutiles, gap 3px entre secciones
- **Secciones modulares**: `.login-head` (20px/14px), `.login-body` (14px), `.login-foot` (14px/20px) con bordes independientes `1px solid rgba(255,255,255,.06)`
- **Logo 3D flotante**: `@keyframes logo3d`, `text-shadow` multicapa, glow pulsante radial
- **Subtítulo "Bodega WEB"**: blanco con `text-shadow` relieve y glow azul
- **Fade-in**: `@keyframes fadeInUp` al cargar el login
- **Focus neón**: `box-shadow` con glow externo en inputs/select
- **Ripple**: onda blanca en botón, `@keyframes rippleAnim`
- **Toggle ver contraseña**: ícono 👁/🙈, highlight, transiciones
- **Shake**: `@keyframes shake` al fallar login
- **Error animado**: slide+fade con `max-height`, `padding`, `opacity`
- **Enter en select → salta a password**, hover con escala en toggle-vis

### Burbuja de foto
- Dropdown empieza vacío ("Seleccionar usuario"), botón inhabilitado sin usuario
- Error "Falta colocar el usuario" al intentar loguear sin seleccionar
- Burbuja de foto al seleccionar: imagen circular 120px flotando a la derecha, con flecha triangular y sombra, sin fondo ni borde

### Persistencia de sesión (F5)
- Sincrónica: chequeo de `sessionStorage.getItem('claves_session')` al inicio del script (antes del `init()` async)
- Si hay sesión, oculta login y muestra app al instante (sin flash)
- `tryAutoUnlock()` en `init()` completa la derivación de clave
- Clave: `claves_session` guarda `{u: userId, p: password}`

### Status dots (indicadores de conexión)
- **Siempre visibles**: overlay fijo abajo a la derecha (`bottom:12px; right:12px`)
- Fuera del HTML de ambas pantallas (entre `#screen-login` y `#screen-app`)
- Al seleccionar usuario en dropdown → su dot se prende
- Al hacer login → el dot del usuario conectado titila (`@keyframes blinkDot`)
- Al salir (lock) → dots vuelven a estado según último usuario
- `updateStatusDots()` se llama en init, en change del select, y en showUserBadge

### TOTEM
- Renombrado de "entradas" a "TOTEM" en toda la UI (13 ocurrencias)
- Logo de empresa (favicon) vía Google Favicons en cards, lista items y detalle

### Animaciones app
- **Search highlight**: texto coincidente en `<mark class="hl">`
- **Panel detail**: slide-in desde la derecha (`@keyframes slideIn`)
- **Lista**: staggered fade-in escalonado (`animation-delay: idx*25ms`)
- **Timer bar**: eliminada (no tenía función útil, solo mostraba cuenta regresiva)
- **Skeleton**: clases CSS listas (`.skel`, `@keyframes skelPulse`)

### Botón "+ Agregar TOTEM"
- Rediseñado con glassmorphism: `backdrop-filter:blur(24px)`, `border:1px solid rgba(255,255,255,.06)`, `border-radius:24px`

### WhatsApp (ELIMINADO)
- Se intentó agregar notificación WSP al loguear (abría `wa.me/PHONE?text=NOMBRE+ESTA+CONECTADA`)
- El usuario pidió sacarlo completamente

## Bugs corregidos
1. `sel` variable faltante en click handler → ReferenceError
2. Icono toggle pass usaba HTML entities en vez de Unicode escapes
3. `tryAutoUnlock()` no restauraba usuario con `setUser(sess.u)` antes de desbloquear
4. Status dots aparecían dentro del header (se movieron a overlay fijo fuera de ambos screens)
5. F5 mostraba login por 1 segundo (se agregó chequeo síncrono de sesión)
6. Timer de inactividad ocupaba espacio sin utilidad (eliminado)
7. Dots no titilaban al cambiar usuario en dropdown (se agregó `updateStatusDots()` en change handler)

## Decisiones clave
- Sesión en `sessionStorage` (no localStorage) → se cierra al cerrar pestaña
- Imágenes extraídas con `cmd /c git cat-file` porque PowerShell corrompe binarios
- Dots como `position:fixed` abajo a la derecha para no interferir con header

## Próximos pasos (pendientes)
1. Verificar que seleccionar un TOTEM muestre el detalle correctamente (posible bug reportado)
2. Ajustar velocidades/colores de animaciones según feedback
3. Considerar implementar skeleton loaders funcionales

## Archivos relevantes
- `C:\AI\sil\CLAVES\index.html` — app completa
- `C:\AI\sil\CLAVES\SILONET.md` — documentación general
- `C:\AI\sil\CLAVES\AGENTS.md` — este archivo (contexto de sesión)

## Tags de backup
- `v0.1-backup-antes-mejoras`
- `v0.2-backup-antes-mejoras2`
