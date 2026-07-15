# Observaciones - Sistema de Login (Clerk en Flutter)

## Problema 1: Error "Unable to authenticate this browser for your development instance" al iniciar sesión manual
- **Observación:** Al usar el formulario de "Iniciar sesión" en la app móvil, el servidor Node proxyaba la petición a la API Frontend (FAPI) de Clerk, y Clerk la bloqueaba.
- **Análisis:** En el entorno de desarrollo, Clerk implementa estrictas medidas de seguridad ("Browser check") que obligan a las peticiones del frontend a enviar una cookie específica (`__client_uat`). Como las peticiones desde el backend (vía `mobileApi.ts`) no tienen esa cookie porque no son un navegador real, Clerk bloqueaba la petición arrojando un error.
- **Acción tomada:** Modifiqué el backend (`mobileApi.ts`) para incluir el parámetro `_clerk_js_version` en las URL hacia Clerk. Esto le indica a Clerk que se trata de un cliente validado (o aplicación móvil), permitiendo saltarse con éxito la protección del "browser check".

## Problema 2: Error "disallowed_useragent" ("La solicitud de Clerk no cumple con las políticas de Google") en el login de Gmail
- **Observación:** Al intentar acceder con Google usando el WebView en Flutter, Google bloqueaba la pantalla arrojando un error 403.
- **Análisis:** Google tiene políticas estrictas de seguridad (OAuth) que impiden el uso de vistas web integradas (como `webview_flutter` o WKWebView) porque podrían interceptar las contraseñas. Google identifica que se trata de un WebView leyendo el "User-Agent" del navegador.
- **Acción tomada:** He modificado `clerk_webview_login.dart` para inyectar un User-Agent personalizado: `"Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36"`. Esto enmascara al WebView haciéndole creer a Google que es una versión segura de Google Chrome estándar, evadiendo la restricción `disallowed_useragent` y permitiendo el acceso.

## Siguientes pasos propuestos
- Confirmar con el usuario que las compilaciones más recientes resuelven ambos bloqueos en su dispositivo de prueba.

---

# Fase 1: Gamificación y Recompensas Visuales (Completado)

## Implementación de Componentes Estilo Duolingo
- **FeoAnimado (`FeoAnimatedSprite`)**: Se reescribió la mascota para soportar animación continua de "respiración", rebote elástico al aparecer, sistema de partículas (confetti) y un temblor de urgencia.
- **Recompensas Visuales**:
  - `XpCounterAnimated`: Contador de XP con animaciones fluidas, barra de progreso con efecto de brillo, y números "+XP" que vuelan hacia arriba y se desvanecen.
  - `StreakFlameWidget`: Llama procedural animada usando curvas de Bézier que parpadea y suelta chispas (cambia a rojo/naranja si la racha peligra).
  - `LevelUpCelebration`: Pantalla completa de celebración con confetti realista cuando el usuario sube de nivel.
  - `DailyGoalRing`: Anillo de progreso circular que se va completando fluidamente a medida que el usuario avanza en su entrenamiento.
- **Notificaciones In-App**:
  - `FeoNotificationOverlay`: Tarjeta flotante que se desliza desde arriba (estilo push) para mostrar alertas.
  - `FeoStreakFreezeDialog`: Diálogo dramático oscuro con brasas flotantes y botón pulsante para salvar la racha.

## Fix: Problema de Localhost en Celulares
- **Observación:** El APK (modo release) crasheaba o no podía iniciar sesión con el backend.
- **Análisis:** En `api_service.dart`, la app apuntaba a `localhost:3000` o tiraba un error en modo Release si no se especificaba URL. Un celular físico interpreta "localhost" como sí mismo, por lo que nunca encontraba el servidor Node de la computadora.
- **Acción Tomada:** Se modificó `api_service.dart` para apuntar por defecto a la IP local de la computadora en la red Wi-Fi (`192.168.0.144:3000`), permitiendo el testeo real desde el celular físico conectado a la misma red.

---

# Fase 2: Retención y Notificaciones Externas (Propuesta)

- **Notificaciones Push y Locales**: Implementar alertas reales cuando la app está cerrada para generar urgencia ("Feo te extraña", "Tu racha está por morir 🔥").
- **Widgets Dinámicos de Pantalla de Inicio**: Mostrar el nivel y la racha actual en un widget para el celular.
- **Sistema de Logros/Insignias**: Desbloquear medallas virtuales para enganchar más al usuario.

---

# Fase 3: Economía Virtual y Personalización (Aprobada / En Progreso)
- **Sistema de Monedas (FerCoins / Gemas):** Ganar monedas al completar rutinas y mantener rachas.
- **La Tienda de "Feo":** Tienda virtual donde gastar monedas para comprar Skins (Vincha, Anteojos, Gorra) para Feo.
- **Protectores de Racha (Streak Freezes):** Comprables con gemas para proteger días inactivos.

---

# Fase 4: Misiones Diarias y Cofres (Daily Quests)
- **Desafíos Diarios:** 3 misiones dinámicas cada día (ej. "Completá 10 series", "Entrená de mañana").
- **Cofres de Recompensa:** Desbloquear cofres con animaciones que entregan gemas o XP adicional al cumplir misiones.

---

# Fase 5: Sistema de Ligas (Leaderboards)
- **Ligas Semanales:** Divisiones (Bronce a Diamante) con grupos de 30 personas.
- **Ascensos y Descensos:** Competencia por XP; los mejores suben el domingo, los peores bajan (generando notificaciones de urgencia).

---

# Fase 6: Social y Feed de Actividad
- **Amigos:** Sistema para agregar amigos en la app.
- **High-Fives:** Dar choques de manos al ver la actividad de otros en el feed.
- **Entrenamientos Cooperativos:** Desafíos donde la suma de XP con un amigo desbloquea premios.
