# Bitácora de Implementación: Corrección de Postura en Tiempo Real

## Contexto
Esta bitácora documenta el proceso de implementación de la feature **"Corrección de Postura en Tiempo Real"** para la aplicación FerFit. El objetivo es permitir a los usuarios recibir feedback instantáneo sobre su postura durante los ejercicios mediante el análisis de video en tiempo real.

---

## Decisiones Clave

### 1. Tecnologías Seleccionadas
| Componente          | Tecnología          | Razones                                                                                     |
|---------------------|---------------------|---------------------------------------------------------------------------------------------|
| **Detección**       | MediaPipe           | - Gratis y de código abierto.
                                  |                     |                     | - Optimizado para tiempo real.
                                  |                     |                     | - Compatible con React y Flutter (vía WebView).                    |
| **Almacenamiento**  | AWS S3              | - Gratis por 12 meses (5 GB).
                                  |                     |                     | - Integración sencilla con Node.js.
                              |                     |                     | - Políticas de retención automática.                               |
| **Animaciones**     | Lottie              | - Animaciones fluidas y ligeras.
                                |                     |                     | - Compatible con React y Flutter.
                                |                     |                     | - Biblioteca gratuita (LottieFiles).                               |
| **Base de Datos**   | Drizzle ORM + PostgreSQL | - Gratis en Supabase/Railway.
                                |                     |                     | - Integración con el backend existente.
                          |

---

### 2. Flujo de Trabajo
1. **Captura de Video**:
   - Resolución: `640x480` (equilibrio entre precisión y rendimiento).
   - FPS: 15 (suficiente para feedback fluido).

2. **Procesamiento con MediaPipe**:
   - Detección de 33 landmarks del cuerpo en tiempo real.
   - Comparación con posturas ideales definidas en JSON.

3. **Feedback Visual**:
   - Superposición de esqueletos en el video (líneas verdes/rojas).
   - Animaciones con Lottie para guiar correcciones.
   - Tips textuales en tiempo real.

4. **Almacenamiento Opcional**:
   - Guardar métricas y URLs de imágenes en AWS S3 y base de datos.

---

### 3. Posturas Ideales
- **Formato**: JSON por ejercicio (ej: `sentadilla.json`).
- **Contenido**:
  - Coordenadas normalizadas (`x`, `y`) para articulaciones clave.
  - Rangos de ángulos aceptables.
  - Feedback para correcciones.
- **Validación**: Tabla colaborativa en Google Sheets para definir parámetros.

---

## Plan de Implementación

### Fase 1: Configuración Inicial
- [x] Crear estructura de carpetas y archivos de documentación.
- [x] Definir ejemplo de postura ideal para "sentadilla".
- [ ] Configurar MediaPipe en el frontend (React y Flutter).

### Fase 2: Detección de Postura
- [ ] Integrar MediaPipe en React usando `@mediapipe/pose`.
- [ ] Integrar MediaPipe en Flutter usando `webview_flutter`.
- [ ] Implementar lógica de comparación con posturas ideales.

### Fase 3: Feedback Visual
- [ ] Superponer esqueletos en el video usando `canvas`.
- [ ] Integrar animaciones con Lottie para correcciones.
- [ ] Mostrar tips textuales en tiempo real.

### Fase 4: Almacenamiento y Historial
- [ ] Configurar AWS S3 para almacenar imágenes.
- [ ] Crear tabla `user_posture_history` en la base de datos.
- [ ] Implementar guardado selectivo de métricas.

### Fase 5: Pruebas y Optimización
- [ ] Validar con fotos/videos de prueba.
- [ ] Ajustar umbrales de detección.
- [ ] Optimizar rendimiento en dispositivos móviles.

---

## Riesgos y Mitigaciones
| Riesgo                          | Mitigación                                                                                     |
|----------------------------------|---------------------------------------------------------------------------------------------|
| Rendimiento en dispositivos lentos | Reducir resolución y FPS. Usar `modelComplexity: 0` en MediaPipe.                          |
| Precisión en la detección        | Validar con datos de referencia y ajustar umbrales.                                         |
| Privacidad de los usuarios       | Procesar imágenes localmente. Guardar solo métricas (no imágenes) por defecto.              |
| Compatibilidad con navegadores   | Usar MediaPipe.js (soportado en Chrome, Firefox, Edge y Safari).                           |

---

## Próximos Pasos
1. **Configurar MediaPipe en React y Flutter**.
2. **Implementar la lógica de comparación con posturas ideales**.
3. **Integrar animaciones con Lottie**.
4. **Configurar AWS S3 y la base de datos para almacenamiento**.

---

## Enlaces Útiles
- [MediaPipe Pose](https://google.github.io/mediapipe/solutions/pose.html)
- [LottieFiles](https://lottiefiles.com/)
- [AWS S3](https://aws.amazon.com/s3/)
- [Drizzle ORM](https://orm.drizzle.team/)