# Contexto vivo — "dónde quedamos"

> Estado actual del proyecto. Se actualiza al cerrar cada feature o sesión de trabajo.
> Es el primer archivo que leer al retomar el proyecto.

**Última actualización:** 2026-10-03 (mundo vivo F1–F4 implementado, v0.6.0)

## Estado general

- **Versión publicada:** v0.5.0 en Play Store (internal test) + web.
- Motor: Godot **4.7.1** (migrado ✓).
- El core loop (explorar + dialogar + misiones) funciona.
- **Mundo vivo (specs 0009, 0010, 0005):** implementado. 23 NPCs con cerebro de utilidad, 18 POIs, charlas y rumores, guardado automático. 8 tests headless en verde.
- **Próximo:** verificación manual en Android y web; luego historia principal (spec 0008).

### Hecho en esta sesión (spec 0007 + B2/B3)

- Mapa con **traza real** de Monte Grande: avenidas Las Heras / L.N. Alem / Dardo Rocha /
  M. Acosta, transversales Máximo Paz / V. López / Dorrego, estación Roca, Plaza Mitre.
- Landmarks nuevos: **Parroquia Inmaculada Concepción** y **Palacio Municipal** flanqueando la plaza.
- **15 NPCs** (8 previos + 7 típicos del conurbano: Beto el quiosquero, Rubén el canillita,
  Walter el colectivero, Doña Marta, Tito el de las bochas, El Chino del choripán, Padre Quique).
- Validado headless con Godot 4.4.1: corre sin errores.
- Publicación: `export_presets.cfg` (Web) + workflow `deploy-web.yml` (CI → GitHub Pages).
  **Pendiente:** habilitar Pages (Settings > Pages > Source = GitHub Actions) y push a main.

### Iteración pre-publicación (geografía + paleta)

- **Geografía real corregida** (fuentes: Wikipedia Plaza Mitre + paradas OSM): plaza central
  enmarcada por Boulevard Bs As / Av. Las Heras / Sofía Terrero / Dardo Rocha; Av. L.N. Alem
  como eje comercial; Máximo Paz transversal; vías del Roca arriba. Estación a ~500m de la plaza.
- **Paleta nueva (ADR-0002):** cambiada de Game Boy (4 verdes) a paleta colorida estilo
  Super Mario Bros, centralizada en `scripts/palette.gd` (`class_name Pal`). Cielo celeste,
  pasto verde, asfalto gris, edificios ladrillo/crema/techo, agua celeste, player tipo Mario.
- Recoloreados: monte_grande, player, npc, dialog_box, clear_color de project.godot.
- ⚠ **Pendiente:** `plaza.gd` sigue con paleta GB vieja (mapa secundario, hoy inalcanzable
  sin B6). Recolorear cuando se trabaje la transición de mapas.
- Validado headless con Godot 4.4.1: sin errores.

## Arquitectura en una frase

Motor de juego mínimo en ~1.150 líneas de GDScript: el mapa es un `PackedInt32Array`,
el arte se dibuja en vivo con `_draw()`, el movimiento es grid-based manual (no física),
la colisión es lógica (`is_walkable`), y `GameManager` (autoload) coordina el diálogo
con un flag global `is_dialog_active` + señales.

## Archivos clave

| Archivo | Rol |
|---------|-----|
| `scripts/autoload/game_manager.gd` | Singleton global: estado de diálogo, input, señales |
| `scripts/player/player.gd` | Movimiento grid-based, interacción |
| `scripts/world/monte_grande.gd` | Mapa principal (activo en `main.tscn`) |
| `scripts/world/plaza.gd` | Mapa secundario (⚠ sin `is_walkable` aún) |
| `scripts/ui/dialog_box.gd` | UI de diálogo typewriter (construida por código) |
| `scripts/npc/npc.gd` | NPC con diálogo, se gira hacia el player |

## Deuda técnica conocida

- ⚠ Contenido del juego sin commitear (riesgo de pérdida) → backlog B1.
- ⚠ `.DS_Store` no ignorado.
- ⚠ `plaza.gd` no implementa `is_walkable`/`get_npc_at` (paredes atravesables ahí).
- ⚠ Falta `export_presets.cfg` (no se puede exportar).

## Arquitectura aprobada: "Mundo vivo" (v0.6.0)

**Fases F1–F4** (4 sprints planeados):

1. **F1 — Ocupación + pathfinding + rutinas** (spec 0009):
   - Grilla de ocupación Dictionary (O(1) lookup, reemplaza loop O(n)).
   - `AStarGrid2D` para pathfinding.
   - Rutinas deambular/patrullar/quieto editables desde Inspector.

2. **F2 — Reloj + POIs + necesidades** (spec 0010):
   - `WorldClock` autoload (tick lento ~0.5s real = 1 min juego).
   - Puntos de Interés editables con capacidad + horarios.
   - Necesidades dinámicas (hambre, energía, social, ocio, deber) que decaen.

3. **F3 — Cerebro de utilidad + fichas offline** (spec 0010):
   - Utilidad = urgencia × afinidad × encaje_horario / distancia.
   - Fichas JSON (generadas offline con IA, no runtime).
   - Reproducibilidad: misma seed = comportamiento idéntico.

4. **F4 — Emergencia social + rumores** (spec 0010):
   - NPCs adyacentes charlan, intercambian hechos.
   - Diálogos varían por relación/memoria (hook para spec 0008).

**Decisión clave:** utility-based AI + fichas offline (ADR-0003). No GOAP, no runtime LLM.
Offline-first (web + Play Store), determinista, expandible a 50+ NPCs.

## Próximo paso sugerido

Probar v0.6.0 en un teléfono y en la web: rendimiento con 23 NPCs, persistencia del guardado en
el navegador y que los vecinos que dan misiones se encuentren fácil. Después, spec 0008.
