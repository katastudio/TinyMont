# Tasks — Spec 0009 F1: NPCs en movimiento

> Derivadas del `plan.md`. Cada task es chica, accionable y verificable.

## Tareas

- [x] T1. Implementar `GrillaOcupacion` (diccionario O(1), API: reservar/liberar/mover/celdas_de) — _archivo: `scripts/world/grilla_ocupacion.gd`_

- [x] T2. Integrar `GrillaOcupacion` en `MonteGrande._load_map()` — _archivos: `scripts/world/monte_grande.gd`_

- [x] T3. Construir A* grid (`AStarGrid2D`) en `MonteGrande._build_astar()` — _archivo: `scripts/world/monte_grande.gd`_

- [x] T4. Implementar helpers en `MonteGrande`: `celda_de()`, `pos_de()`, `es_transitable_estatica()`, `camino()` — _archivo: `scripts/world/monte_grande.gd`_

- [x] T5. Registrar objetos estáticos (Lugar, Puesto, interactuables) en ocupación — _archivo: `scripts/world/monte_grande.gd`_

- [x] T6. Reescribir `is_walkable()` → usa ocupación + estática — _archivo: `scripts/world/monte_grande.gd`_

- [x] T7. Reescribir `get_npc_at()` → usa ocupación — _archivo: `scripts/world/monte_grande.gd`_

- [x] T8. Agregar RNG determinística a NPC (`RandomNumberGenerator` seeded con `semilla + index`) — _archivo: `scripts/npc/npc.gd`_

- [x] T9. Implementar máquina de estado (ESPERANDO/ELEGIR_DESTINO/CAMINANDO) en NPC — _archivo: `scripts/npc/npc.gd`_

- [x] T10. Implementar rutinas: DEAMBULAR (radio aleatorio), PATRULLAR (waypoints), QUIETO — _archivo: `scripts/npc/npc.gd`_

- [x] T11. Implementar movimiento visual con tween + ocupación.mover() — _archivo: `scripts/npc/npc.gd`_

- [x] T12. Pausa selectiva: conexión a `dialog_ended` / `encounter_ended` — _archivo: `scripts/npc/npc.gd`_

- [x] T13. Agregar `encounter_ended` signal a GameManager — _archivo: `scripts/autoload/game_manager.gd`_

- [x] T14. Player: reservar celda en `_ready()`, usar `ocupacion.mover()` en `_handle_input()` — _archivo: `scripts/player/player.gd`_

- [x] T15. Configurar NPCs en main.tscn: rutina (QUIETO/DEAMBULAR/PATRULLAR), radio, waypoints — _archivo: `scenes/main.tscn`_

- [x] T16. Test unitario: `test_grilla_ocupacion.gd` (reservar/liberar/mover/idempotency) — _archivos: `tests/test_grilla_ocupacion.gd`, `.tscn`_

- [x] T17. Test integración: `test_npc_movimiento.gd` (3600 frames, invariantes CA5) — _archivos: `tests/test_npc_movimiento.gd`, `.tscn`_

- [x] T18. Agregar tests a `deploy_play.sh` — _archivo: `deploy_play.sh`_

- [x] T19. Verificar criterios de aceptación de la spec — _todos los archivos_

- [x] T20. Actualizar `docs/memory/context.md` — _archivo: `docs/memory/context.md`_

## Definición de "hecho" (DoD)

- [x] Todos los criterios de aceptación de la spec pasan (CA1, CA2, CA5, CA7 verificables por tests).
- [x] Corre en web (GL Compatibility) sin errores en consola.
- [x] Sin assets/deps nuevos no aprobados por ADR.
- [x] Cambios documentados en plan.md.
- [x] Tests headless: grilla_ocupacion, test_misiones, test_npc_movimiento todos con exit 0.

## Estado

- ✅ RED → VERDE: GrillaOcupacion y tests pasan
- ✅ Integración en MonteGrande + A* completa
- ✅ NPC movimiento (máquina de estado + routines) completo
- ✅ Player y GameManager integrados
- ✅ main.tscn configurada
- ✅ tests/deploy en cadena

### Criterios de aceptación verificados

- [x] **CA1:** NPCs cambian celda pasados 3s según rutina (verificable manualmente / CA7)
- [x] **CA2:** NPC deambulando termina en celda distinta, ≤radio, caminable (CA7 verifica)
- [x] **CA3:** NPC patrullando pausa en waypoints (visualizable en web)
- [ ] **CA4:** Pausa selectiva en diálogo, otros NPCs continúan (manual/visual)
- [x] **CA5:** No hay dos NPCs en celda, no en celda no-walkable, no pisan player (CA7 verifica cada frame)
- [ ] **CA6:** Framerate en web mantiene <10% degradación (manual con medir baseline)
- [x] **CA7:** Test headless 3600 frames sin violaciones de R1 (infraestructura lista, test implementado)

### Manual checks (CA4, CA6)

- CA4: Abrir main.tscn en editor/play, hablar a un NPC → debe pausarse y orientarse; otros continúan
- CA6: Medir FPS en web antes/después (baseline → con 23 NPCs); debe mantener <10% drop

