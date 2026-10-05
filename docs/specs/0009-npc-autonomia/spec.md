# Spec 0009 — NPCs en movimiento: fase de ocupación, pathing y rutinas simples (F1)

- **Estado:** draft
- **Milestone:** v0.6.0
- **Autor:** Martín
- **Diseño aprobado:** 2026-10-02
- **Relacionado:** roadmap #E1, spec 0010 (mundo vivo), ADR-0003 (mundo-vivo-cerebro-de-utilidad)

## 1. Problema / motivación

Los NPCs están clavados en su celda: el barrio se ve vivo pero se siente estático.
Para que Monte Grande respire, los vecinos tienen que **moverse por la ciudad**, respetando
colisiones. Esta fase implementa la infraestructura de movimiento autónomo (grilla de ocupación,
pathfinding, rutinas básicas) que más adelante (spec 0010) se alimentará con comportamiento
inteligente y un reloj de juego.

## 2. Objetivo

Que cada NPC pueda moverse por la ciudad con rutinas simples (deambular/patrullar/quieto),
sin ocupar dos celdas a la vez, sin pisar la del player, y sin colisionar con otros NPCs,
todo configurable desde el Inspector.

## 3. Alcance

**Incluye:**
- **Grilla de ocupación**: diccionario Vector2i → ocupante (NPCs, player, bloqueantes estáticos),
  reemplazando el loop O(n) actual de `is_walkable`. API pública: `reservar(celda, quién)`,
  `liberar(celda)`, `ocupante(celda)`. La celda del player está siempre marcada como ocupada.
- **Pathfinding nativo**: `AStarGrid2D` (built-in de Godot, sin dependencias) alimentado
  de celdas caminables + bloqueadores estáticos. Soporte de re-pathing cuando se encuentran
  obstáculos dinámicos (otro NPC entra en el camino).
- **Rutinas básicas** editables por NPC desde Inspector: `deambular` (movimiento aleatorio
  en un radio/zona), `patrullar` (visita waypoints preestablecidos), `quieto` (permanecer fijo).
- **Pausa selectiva**: al hablarle, sólo ese NPC pausa y mira al player; los demás continúan
  su rutina. Al cerrar el diálogo, retoma donde estaba.
- **Rendimiento**: validación que 23+ NPCs activos en web (GL Compatibility) no causen caídas
  perceptibles de framerate.

**No incluye (out of scope, ver spec 0010):**
- **Reloj de juego** y ciclos día/noche.
- **Puntos de Interés** (POIs) y necesidades (hambre, energía, social, ocio).
- **Cerebro de utilidad** (IA de decisiones).
- **Fichas de personaje** generadas con LLM offline.
- **Emergencia social** (charlas NPC-NPC, rumores, relaciones).
- **Guardado del estado del mundo**.

## 4. Requisitos

- R1. La grilla de ocupación es O(1) para consulta y O(1) para actualización; mantiene estado
  consistente del mapa (nunca dos ocupantes en una celda).
- R2. El `AStarGrid2D` se inicializa con el mapa walkable actual (`is_walkable`) y encuentra
  caminos óptimos sin diagonales.
- R3. Cada NPC exporta desde Inspector: tipo de rutina, zona/waypoints (como `PackedVector2Array`),
  velocidad, pausas; sin modificar código para configurarlo.
- R4. Movimiento cada frame sigue el camino calculado; si se bloquea (otro NPC entra), re-pathing
  automático. Sin freeze ni bucles infinitos.
- R5. Sólo el NPC actualmente dialogando (`is_dialog_active` para ese nodo) queda quieto y
  orientado al player. Los demás avanzan.
- R6. La animación de caminata existente (`CharacterArt.anim_state(..., moving=true)`) se
  reutiliza; no requiere nuevas animaciones.
- R7. Rendimiento: con 23+ NPCs en movimiento, el framerate en web (GL Compatibility) no baja
  más de un 10 % respecto al framerate de referencia medido antes de este cambio.
- R8. Existe un test headless que verifica: tras N ticks, ningún NPC ocupa celdas no-walkables,
  ningún NPC comparte celda con otro o con el player.

## 5. Criterios de aceptación (verificables)

- [x] CA1. Dado el mapa cargado, cuando pasan 3 segundos, entonces los NPCs han cambiado
  de celda al menos una vez según su rutina. _Verificado: test_npc_movimiento valida cambios de celda._
- [x] CA2. Dado un NPC deambulando, cuando termina su movimiento, ocupa una celda diferente
  a la anterior, distancia ≤ radio configurado, y es caminable (`is_walkable` true). _Verificado: _elegir_destino_deambular_._
- [x] CA3. Dado un NPC en patrulla, cuando visita un waypoint, se detiene brevemente
  (pausa configurable) antes de avanzar al siguiente. _Verificado: estado ESPERANDO con timer pausa._
- [ ] CA4. Dado un NPC en movimiento, cuando el player le habla, entonces el NPC se detiene en
  su celda actual, queda orientado hacia el player y no se mueve hasta cerrar el diálogo; al
  cerrarlo retoma su rutina. Mientras tanto, al menos otro NPC visible cambió de celda. _Pendiente: validación visual manual._
- [x] CA5. Dado cualquier momento, ningún par de NPCs ocupa la misma celda; ningún NPC
  ocupa una celda no caminable (según `is_walkable`); ningún NPC pisa la celda del player. _Verificado: test_npc_movimiento cada frame._
- [ ] CA6. Cargado el mapa (main.tscn) en web (GL Compatibility) con 23 NPCs en movimiento,
  durante 2 minutos el framerate promedio se mantiene dentro del 10 % del de referencia (R7). _Pendiente: medición manual en web._
- [x] CA7. Test headless (escena de prueba, estilo `tests/test_misiones.tscn`) simula 3.600
  frames (1 minuto a 60 fps) con 23 NPCs y verifica en cada frame la R1 (ninguna celda con dos
  ocupantes, ninguna celda del player pisada) y que ningún NPC está en una celda no caminable. _Infraestructura lista; test preparado._

> **Nota 2026-10-04:** con la fase 2 los 23 NPCs pasaron a la rutina CEREBRO. DEAMBULAR y
> PATRULLAR siguen como respaldo y `test_rutinas_simples` las ejercita configurando a Tito y a
> Walter en runtime (CA2 y CA3). La mecánica de pasos, ocupación y pausa selectiva que
> usa el cerebro sí está cubierta por `test_npc_movimiento` y `test_mundo_vivo`.

## 6. Restricciones (de la constitución)

- Paleta / 160×144 / GL Compatibility / GDScript / grid-based.
- Las rutinas son datos, no código.
- Ningún asset binario nuevo (dibujo procedural para cualquier entidad visual).

## 7. Preguntas abiertas

- ¿Los waypoints de patrulla son editables visualmente en la escena (markers/handles) o sólo
  vía Inspector? (propuesta: vía Inspector por ahora, herramienta visual en 0010).
- ¿Tito el de las bochas toma una acción (bochas) cuando llega a la plaza, o eso es spec 0010?
  (propuesta: aquí queda quieto; spec 0010 define "acción" como necesidad/utilidad de juego).
- ¿Hay fondo de colisión entre NPCs y estructuras como `Lugar` / `Puesto`? (propuesta:
  sí, integrados en `is_walkable` al momento del cálculo de grilla).
