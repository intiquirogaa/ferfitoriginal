# Posturas Ideales para Corrección de Ejercicios

## Estructura de la Tabla de Posturas
Esta tabla define los parámetros ideales para cada ejercicio, incluyendo coordenadas de articulaciones, ángulos aceptables y feedback para correcciones.

| Columna            | Descripción                                                                                     | Ejemplo                          |
|--------------------|-------------------------------------------------------------------------------------------------|----------------------------------|
| Ejercicio          | Nombre del ejercicio.                                                                          | Sentadilla                      |
| Articulación       | Nombre de la articulación (ej: rodilla, hombro).                                              | Rodilla                         |
| Coordenada X (0-1) | Posición horizontal normalizada (0 = izquierda, 1 = derecha).                                  | 0.6                             |
| Coordenada Y (0-1) | Posición vertical normalizada (0 = arriba, 1 = abajo).                                         | 0.7                             |
| Ángulo Mínimo (°)  | Ángulo mínimo aceptable para la articulación.                                                  | 80                              |
| Ángulo Máximo (°)  | Ángulo máximo aceptable para la articulación.                                                  | 100                             |
| Feedback           | Mensaje de corrección si la postura no cumple con los parámetros ideales.                     | "Alinea tus rodillas con los dedos de los pies" |

---

## Ejemplo: Sentadilla
```json
{
  "joints": {
    "shoulder_left": { "x": 0.4, "y": 0.3 },
    "shoulder_right": { "x": 0.6, "y": 0.3 },
    "knee_left": { "x": 0.45, "y": 0.7 },
    "knee_right": { "x": 0.55, "y": 0.7 },
    "hip_left": { "x": 0.4, "y": 0.5 },
    "hip_right": { "x": 0.6, "y": 0.5 }
  },
  "angles": {
    "knee": {
      "min": 80,
      "max": 100,
      "feedback": "Alinea tus rodillas con los dedos de los pies"
    },
    "back": {
      "min": 160,
      "max": 180,
      "feedback": "Mantén la espalda recta"
    }
  }
}
```

---

## Cómo Contribuir
1. **Definir posturas ideales**: Completa la tabla con los parámetros para cada ejercicio.
2. **Validar con expertos**: Consulta con entrenadores o fisioterapeutas para ajustar los ángulos y coordenadas.
3. **Exportar a JSON**: Guarda cada ejercicio como un archivo JSON en `server/_core/exercises/`.

---

## Herramientas Recomendadas
- **Kinovea**: Para medir ángulos en videos de referencia.
- **Google Sheets**: Para colaborar en la definición de posturas ideales.
- **MediaPipe Studio**: Para probar la detección de articulaciones en tiempo real.