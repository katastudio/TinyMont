# Contexto vivo — "dónde quedamos"

> Estado actual del proyecto. Se actualiza al cerrar cada feature o sesión de trabajo.
> Es el primer archivo que leer al retomar el proyecto.

**Última actualización:** 2026-06-20

## Estado general

- Milestone activo: `mvp-0.0.1` → próximo objetivo: `mvp-0.1.0` (publicable en web).
- Motor: Godot **4.4.1** (instalado local; último estable disponible: 4.7 — migración a evaluar).
- El core loop (explorar + dialogar) funciona. Falta infra de publicación y features de juego.

### Hecho en esta sesión (spec 0007 + B2/B3)

- Mapa con **traza real** de Monte Grande: avenidas Las Heras / L.N. Alem / Dardo Rocha /
  M. Acosta, transversales Máximo Paz / V. López / Dorrego, estación Roca, Plaza Mitre.
- Landmarks nuevos: **Parroquia Inmaculada Concepción** y **Palacio Municipal** flanqueando la plaza.
- **15 NPCs** (8 previos + 7 típicos del conurbano: Beto el quiosquero, Rubén el canillita,
  Walter el colectivero, Doña Marta, Tito el de las bochas, El Chino del choripán, Padre Quique).
- Validado headless con Godot 4.4.1: corre sin errores.
- Publicación: `export_presets.cfg` (Web) + workflow `deploy-web.yml` (CI → GitHub Pages).
  **Pendiente:** habilitar Pages (Settings > Pages > Source = GitHub Actions) y push a main.

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

## Próximo paso sugerido

Arrancar backlog B1 (higiene de repo) y B2 (export web). Ver `../product/roadmap.md`.
