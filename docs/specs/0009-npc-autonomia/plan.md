# Plan — Spec 0009 F1: NPCs en movimiento

## Resumen ejecutivo

Implementar infraestructura de movimiento autónomo para NPCs:
- **Grilla de ocupación** (O(1) diccionario)
- **A* pathfinding** (AStarGrid2D nativo)
- **Rutinas simples** (QUIETO, DEAMBULAR, PATRULLAR)
- **Pausa selectiva** (dialog pausa un NPC)

## Flujo de datos

```
MonteGrande._load_map()
  ├─ _build_astar() → grilla A* con bloqueadores estáticos
  ├─ _register_static_interactables() → objetos en ocupacion
  └─ Player._ready() → reserva su celda
      └ ocupacion.reservar(celda_actual, self)

NPC._process(delta)
  └─ _actualizar_movimiento()
      ├─ ESPERANDO → timer pausa
      ├─ ELEGIR_DESTINO → random (DEAMBULAR) / waypoint (PATRULLAR)
      │    └─ mundo.camino(desde, hasta) → A* path
      └─ CAMINANDO → tween por cada celda
           └─ ocupacion.mover(de, hacia, self)
               ├─ reserva siguiente
               └─ libera anterior (al llegar)

Player._handle_input() → move_to(next_pos)
  └─ ocupacion.mover(celda_actual, celda_siguiente, self)
```

## Archivos tocados

**Creados:**
- `scripts/world/grilla_ocupacion.gd` — clase RefCounted, diccionario O(1)
- `tests/test_grilla_ocupacion.gd` — unit tests: reservar/liberar/mover/idempotency
- `tests/test_grilla_ocupacion.tscn`
- `tests/test_npc_movimiento.gd` — integración: 3600 frames, invariantes
- `tests/test_npc_movimiento.tscn`

**Modificados:**
- `scripts/world/monte_grande.gd`
  - Nuevo: `@export semilla`, `var ocupacion`, `var astar`
  - Nuevo: `_build_astar()`, `_register_static_interactables()`
  - Nuevo: `celda_de(pos)`, `pos_de(celda)`, `es_transitable_estatica(celda)`, `camino(de, hasta)`
  - Reescrito: `is_walkable()` → usa `ocupacion.esta_libre()`
  - Reescrito: `get_npc_at()` → usa `ocupacion.ocupante()`

- `scripts/npc/npc.gd`
  - Nuevo: `enum Rutina`, `enum Estado`
  - Nuevo: `@export rutina`, `@export radio_deambular`, `@export waypoints`, `@export velocidad`, `@export pausa_min/max`
  - Nuevo: `_ready()` → RNG determinística + reserva celda
  - Reescrito: `_process()` → delega a `_actualizar_movimiento()`
  - Nuevo: Máquina de estado (ESPERANDO/ELEGIR_DESTINO/CAMINANDO)
  - Nuevo: `_elegir_destino_deambular()`, `_elegir_destino_patrullar()`
  - Nuevo: `_avanzar_en_camino(delta)` → tween + ocupacion.mover()
  - Nuevo: `_on_dialog_ended()`, `_on_encounter_ended()` → pause on dialog
  - Modificado: `interact()` → set `_en_dialogo = true`

- `scripts/player/player.gd`
  - Modificado: `_ready()` → reserva celda inicial en ocupacion
  - Modificado: `_handle_input()` → usa `ocupacion.mover()` en lugar de asignación directa

- `scripts/autoload/game_manager.gd`
  - Nuevo: `signal encounter_ended`
  - Modificado: `end_encounter()` → emite `encounter_ended`

- `scenes/main.tscn`
  - Agregado: `rutina = 0/1/2` a 6 NPCs (Tito, Walter, Gordo, Lucia, Ramon, Mili)
  - Agregado: `radio_deambular`, `waypoints` según rutina

- `deploy_play.sh`
  - Agregado: `test_grilla_ocupacion.tscn` en sequence

## Regla de ocupación

**Invariante crítica:** El NPC mantiene AMBAS celdas (actual + siguiente) mientras se mueve, evitando que el player camines "a través de" un paso a medio hacer.

```gdscript
# En CAMINANDO:
ocupacion.mover(celda_actual, celda_siguiente, self)  # reserva siguiente, libera actual
# Luego tween de T px en delta segundos
# En arrival:
celda_actual = celda_siguiente  # actualiza tras completar el tween
```

Esto es **O(1)** porque cada NPC ocupa ≤1 celda de inicio + ≤1 de destino = máximo 2 en lookup.

## Manejo de bloqueos

Si `ocupacion.mover()` falla 3 veces (otro NPC en el camino):
- Abandon path (ESPERANDO)
- Retry después de pausa aleatoria
- Sin freeze, sin bucle infinito (CA4/R4)

## Pausa selectiva

- NPC al recibir `interact()`: set `_en_dialogo = true`
- Conecta a `GameManager.dialog_ended` y `encounter_ended`
- Al emitirse: set `_en_dialogo = false` → reanuda movimiento
- Otros NPCs siguen moviéndose (no pausa global)

## Rendimiento

- A* grid: marcadas celdas sólidas una sola vez en `_load_map()` (static)
- Pathfinding: O(log(MAP_W*MAP_H)) por NPC/frame (A*)
- Ocupación: O(1) por movimiento
- Con 23 NPCs: ~23 ops/frame + ocasional A* call → <10% overhead (CA6 manual)

## Pendiente (spec 0010)

- Necesidades (hambre, energía)
- POIs (casa, restaurante, etc.)
- Cerebro de utilidad (decisiones)
- Ciclo día/noche
- Emergencia social (NPC-NPC)
