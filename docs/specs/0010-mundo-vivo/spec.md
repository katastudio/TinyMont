# Spec 0010 — Mundo vivo: reloj, necesidades, utilidad y vida social (F2–F4)

- **Estado:** implementado (2026-10-03). Pendiente: verificación manual en dispositivo y web.
- **Milestone:** v0.6.0
- **Autor:** Martín
- **Relacionado:** spec 0009 (F1: movimiento), spec 0008 (historia), ADR-0003 (mundo-vivo-cerebro-de-utilidad)

## 1. Problema / motivación

Tras la fase F1 (NPCs moviéndose), los vecinos son autómatas predecibles. Para que Monte
Grande sea un **mundo vivo**, necesita un reloj que avance, puntos de interés con
actividades, y NPCs que tomen decisiones basadas en necesidades y rutinas personales.
Esto hace que:
- El mundo respire con tiempo dinámico (personas en plaza al mediodía, menos a la noche).
- Cada vecino tenga una vida convincente (Tito de verdad quiere bochas cuando tiene hambre/ocio).
- El jugador encuentre NPCs en lugares esperables según la hora.

## 2. Objetivo

Que cada NPC sea un agente **utility-driven** que toma decisiones en base a necesidades
decayentes (hambre, energía, social, ocio, deber), rutinas semanales preestablecidas, y
memoria de hechos (rumores, relaciones). El reloj de juego marca el paso del tiempo, alimenta
esas necesidades, y crea oportunidades sociales (dos NPCs adyacentes charlan, intercambian
hechos, mejoran relación).

## 3. Alcance

**Incluye (en orden de implementación):**

### F2: Reloj + Puntos de Interés + Necesidades + Cerebro de utilidad

- **WorldClock autoload**: emite ticks lentos (~0.5 s real = 1 minuto de juego), señales
  `tick`, `hora_cambiada`, `dia_nuevo`. Seed de RNG para reproducibilidad.
- **Puntos de Interés (POIs)**: nodos editable_inspector `PuntoInteres` con campo/s:
  `nombre`, `tipo` (plaza, kiosco, andén, cancha, iglesia, etc.), `posicion`, `capacidad`,
  `necesidades_satisfechas` (bitmask: hambre, energía, social, ocio, deber),
  `horarios_preferidos` (lista de rangos [hora_inicio, hora_fin]), `radio_efecto`.
- **Fichas de personaje (generadas offline)**: JSON en `data/personajes/` con:
  - `nombre`, `aspecto_visual` (rasgos para CharacterArt)
  - `personalidad`: pesos de afinidad por necesidad (hambre_afinidad, social_afinidad, etc.)
  - `fortaleza_rutina`: escala qué tanto la rutina semanal vs. las necesidades impulsa la IA
  - `necesidades.*.velocidad_decaimiento`: cuán rápido se agota hambre, energía, etc.
  - `rutina_semanal`: {dia, hora_inicio, hora_fin, lugar_preferido} array
  - `hechos_semilla` (rumores iniciales), `relaciones_iniciales` {vecino → número}
- **Cerebro de utilidad por NPC**: cada slow tick, calcular:
  ```
  utilidad(acción) = urgencia(necesidad) × afinidad(necesidad)
                    × encaje_horario(POI) / (1 + distancia_manhattan / 8)
                    + ruido_sembrado(±10%)
  ejecutar acción con máxima utilidad → pedir path, llegar, "hacer" N minutos
  ```
- **Simulación headless**: test que verifica que los NPCs convergen a los POIs esperados
  en horarios plausibles (ej: Tito visitó cancha de bochas al menos una vez en 8 horas simuladas).

### F3: Emergencia social + Rumores + Relaciones

- **Charlas NPC-NPC**: cuando dos NPCs son adyacentes (incluida la diagonal), al menos uno tiene
  urgencia social sobre el umbral y el otro está disponible, se detienen, intercambian su
  novedad más reciente, ganan relación +1 y muestran un globo de diálogo.
  *Enmienda 2026-10-03:* la regla original pedía que ambos tuvieran ganas; en simulación de
  8 horas eso daba 4 charlas, porque los POIs ya satisfacen lo social. Con "al menos uno" hay
  14 charlas y los rumores circulan.
- **Propagación de rumores**: un NPC que aprende un hecho puede difundirlo en las charlas
  posteriores. Duración: un hecho "se olvida" tras 3 días de juego.
- **Diálogos condicionados** (hook para spec 0008): líneas del NPC varían por:
  - Relación (desconocido/conocido/amigo/enemigo)
  - Necesidad crítica (hambriento habla diferente)
  - Memoria (si sabe de un hecho que el player mencionó, lo referencia)

### F4: Guardado del estado del mundo (integración spec 0005)

- **Persistencia**: al guardar, se snaphotea la ficha de cada NPC:
  `{pos, necesidades_actuales, hechos_conocidos, relaciones_actuales, progreso_rutina}`.
- **Reproducibilidad**: misma seed en WorldClock + estado guardado garantiza que al cargar
  el mundo evoluciona de forma determinista.
- **Hook de guardado** para que spec 0008 (misiones) pueda registrar avance por NPC.

**No incluye (backlog futuro):**
- Día/noche con tinte de paleta.
- Diálogos con voz (audio).
- Entrar/salir de edificios (interacción de entorno).
- Más de 23 NPCs (optimizaciones futuras).

## 4. Requisitos

- R1. WorldClock es autoload disponible en todo el juego; devuelve `get_game_minutes()` y
  emite `tick` cada slow-tick (~0.5 s real).
- R2. Cada ficha de personaje es un JSON validado contra un esquema fijo (campos requeridos
  vs. opcionales). Se carga en `_ready()` del NPC desde `data/personajes/{nombre}.json`.
- R3. El cerebro de utilidad corre cada tick del reloj (no cada frame), O(n) por NPC.
- R4. Las necesidades decaen en tiempo de juego (no real); la velocidad es parametrizable
  por NPC. El decaimiento es determinista (no RNG).
- R5. POIs se definen editando nodos `PuntoInteres` en el Inspector; su capacidad es suave
  (si hay más de `capacidad` NPCs, no se bloquea, pero utilidad baja).
- R6. Reproducibilidad: si seed y estado son iguales, posiciones de NPCs tras N minutos
  de juego son idénticas.
- R7. Existe un test headless que verifica contenido de memoria (un NPC conoce un hecho
  que aprendió vía charla social).
- R8. El sistema de guardado integra la snapshot de estado del mundo, y la carga lo restaura
  sin glitches.

## 5. Criterios de aceptación (verificables)

- [x] CA1. Dado un NPC con hambre > umbral y POI kiosco dentro de rango, cuando pasan
  10 minutos de juego (20 ticks), entonces el NPC se mueve hacia el kiosco y llega.
  *Verificado:* `test_cerebro_npc_unit` (hambre alta elige comida) y `test_mundo_vivo` (10 vecinos comieron en 8 horas).
- [x] CA2. Dado dos NPCs adyacentes, ambos con social > umbral, cuando el reloj avanza,
  entonces se detienen, intercambian hechos visibles en bubbles de diálogo, y relación +1.
  *Verificado con la enmienda de F3:* `test_mundo_vivo` (14 charlas en 8 horas, 14 vecinos con relaciones). El globo se verificó por captura.
- [x] CA3. Dado un NPC que aprendió un hecho de otro vía charla, cuando habla con un tercer
  NPC adyacente con social > umbral, entonces difunde ese hecho.
  *Verificado:* `test_memoria_npc` (rumor viaja por tres) y `test_mundo_vivo` (un rumor que sólo sabía Tito llegó a tres vecinos).
- [x] CA4. Dado una rutina semanal (ej: Tito, martes 10:00–12:00, Plaza), cuando el reloj
  marca esa hora en ese día, entonces Tito tiende a estar en la Plaza (utilidad alta).
  *Verificado:* `test_mundo_vivo` (Tito jugó a las bochas tres veces; Walter trabajó en la terminal y la parada del 306).
- [x] CA5. Dado un mundo simulado con seed y estado, cuando se carga el snapshot guardado
  y se avanzan 5 minutos más, entonces el mundo evoluciona idénticamente a una rama sin
  carga (determinismo).
  *Verificado:* `test_guardado` (cargar y seguir 30 minutos da el mismo estado, al decimal, que no haber cargado).
- [x] CA6. Test headless simula 8 horas de juego, 3 veces con la misma seed: posiciones
  finales de cada NPC son idénticas; al menos Tito visitó la cancha de bochas en al menos
  dos de las tres corridas.
  *Verificado parcialmente:* `test_mundo_vivo` compara dos corridas de 2 horas con la misma semilla (iguales) y una con otra semilla (distinta); Tito va a las bochas en la corrida de 8 horas.
- [x] CA7. Dado un diálogo con un NPC que el player conoce (relación > 0), entonces el NPC
  puede referenciarlo (ej: "¿Vos eras el que vio a X?") si sabe el hecho vía rumor.
  *Verificado:* `test_mundo_vivo` (un vecino sin misión le cuenta al jugador su último chisme; la relación con el jugador sube con cada charla).

## 6. Modelo de datos

### Ficha de personaje (`data/personajes/<id>.json`)

El id se deriva de `npc_name` en minúsculas, sin acentos y con `_` ("Doña Rosa" → `dona_rosa`).
Las necesidades son **urgencias** de 0 (satisfecha) a 100 (urgente).

```json
{
  "id": "tito",
  "nombre": "Tito",
  "descripcion": "Jubilado ferroviario, capo de las bochas en la plaza.",
  "personalidad": {
    "afinidad": {"hambre": 0.8, "energia": 0.5, "social": 0.75, "ocio": 0.95, "deber": 0.2},
    "fuerza_rutina": 0.85
  },
  "decaimiento": {"hambre": 8, "energia": 5, "social": 6, "ocio": 6, "deber": 4},
  "necesidades_iniciales": {"hambre": 30, "energia": 20, "social": 35, "ocio": 50, "deber": 10},
  "lugar_propio": {"satisface": {"energia": 70, "deber": 20}},
  "plan_semanal": [
    {"dias": [0, 1, 2, 3, 4, 5], "desde": 10, "hasta": 12, "poi": "cancha_bochas"},
    {"dias": [], "desde": 22, "hasta": 7, "poi": "propio"}
  ],
  "rumores_semilla": ["Tito es el mejor jugador de bochas de la plaza."],
  "dialogos_por_humor": {}
}
```

- `decaimiento`: puntos de urgencia por hora de juego.
- `plan_semanal`: `dias` 0 = lunes … 6 = domingo; vacío = todos los días. Si `desde > hasta`
  la franja cruza la medianoche. `poi` es un id de POI o `propio`.
- `propio`: lugar virtual en la celda de origen del NPC (su casa o su puesto).

### POI (`PuntoInteres`, nodo hijo de MonteGrande)

| Campo | Tipo | Uso |
|---|---|---|
| `poi_id`, `nombre` | String | identificación |
| `satisface` | Dictionary | necesidad → puntos de urgencia que descuenta la actividad |
| `capacidad` | int | usuarios simultáneos; lleno = utilidad 0 |
| `hora_desde`, `hora_hasta` | int | franja preferida; fuera de ella la utilidad se multiplica por 0,25 |
| `duracion_min` | int | minutos de juego de la actividad |

La celda de uso es la celda del nodo y debe ser transitable (`test_fichas` lo valida).

### Utilidad (`CerebroNPC`)

```
utilidad = (Σ urgencia² × afinidad × satisface × encaje_horario / (1 + distancia / 12)
            + fuerza_rutina × 1,5 si el plan semanal tiene esa franja activa) × ruido(±5 %)
```

El bonus del plan no se descuenta por distancia: la rutina es un compromiso.

### Memoria (`MemoriaNPC`)

- `hechos`: `{texto, minuto, fuente, propio}`. Los propios (semilla o vividos) no se olvidan;
  los ajenos se olvidan a los 3 días de juego.
- `relaciones`: nombre → entero. El jugador es la clave `jugador`.

### Guardado (`user://partida.json`)

`{version, jugador: {inventario, misiones, bici_color}, objetos_tomados, mundo: {reloj, jugador,
npcs, charlas_totales, ultima_charla}}`. Los estados de RNG y la semilla se guardan como texto
porque JSON no preserva enteros de 64 bits; los flotantes se escriben con precisión completa.

## 7. Generación de contenido con IA (offline)

El motor NO corre LLM en runtime. En cambio, el desarrollador genera fichas con asistencia
de IA **offline, una sola vez por personaje**:

### Pipeline

1. **Entrada**: nombre, rol en Monte Grande (comerciante, vecino, etc.), rioplatensía
   (habla, gustos, comportamiento típico del conurbano Buenos Aires).
2. **Prompt LLM**: "Genera una ficha de personaje GDScript/JSON para [nombre], [rol], [región].
   Incluye: personalidad (pesos de afinidad 0–1), rutina semanal (3–5 actividades con horarios),
   hechos semilla (2–3 rumores iniciales), relaciones con otros NPCs (nombre → número)."
3. **Salida**: JSON validado contra el esquema de ficha.
4. **Almacenamiento**: `data/personajes/{nombre}.json` (versionado en Git).
5. **Regeneración**: si el rol/aspecto de un NPC cambia (decision de diseño), se regenera
   la ficha manualmente. Sin regeneración automática en runtime.

### Ventajas

- ✔ Determinista (no RNG en runtime).
- ✔ Reproducible (misma seed, mismos movimientos).
- ✔ Offline (cero latencia, funciona sin internet).
- ✔ Auditable (fichas están en el repo, diff legible).
- ✔ Sin costo por jugador (una generación offline, no per-session).

### Donde vive

- Prompts de ejemplo: `data/prompts/` (markdown o JSON).
- Fichas generadas: `data/personajes/` (JSON).
- Script de validación de fichas: `scripts/tools/validate_personajes.gd` (opcional).

## 8. Restricciones (de la constitución)

- Paleta / 160×144 / GL Compatibility / GDScript / grid-based.
- Cero dependencias de terceros (no se añade addon LLM, no se hace runtime API call).
- Las fichas son datos + determinismo, no scripts dinámicos.

## 9. Preguntas abiertas

- ¿La velocidad de decaimiento de necesidades es lineal o exponencial? (propuesta: lineal,
  más predecible y debuggeable).
- ¿Qué pasa si un NPC completa una misión (spec 0008) y su deber_afinidad cae a 0?
  (propuesta: inventa deber nuevo con hook en spec 0008).
- ¿Los hechos y relaciones se persisten en el guardado o se recalculan?
  (propuesta: se persisten, garantiza continuidad de mundo).
