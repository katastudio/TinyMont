# Roadmap & Backlog — TinyMont

Backlog de alto nivel. Cada ítem, cuando se vaya a trabajar, se convierte en un
**spec** bajo `specs/NNNN-nombre/`. Estados: `idea` → `spec` → `en progreso` → `hecho`.

## Milestone actual: `mvp-0.0.1` (base)

Hecho:
- [x] Movimiento grid-based del player
- [x] Sistema de diálogo typewriter
- [x] GameManager autoload + señales
- [x] Mapa Monte Grande con NPCs
- [x] Render procedural estilo GB

## Publicado ✅: `v0.1.0` (antes `mvp-0.1.0`)

Objetivo cumplido: **primera versión jugable y publicada en web**.
Live: https://katastudio.github.io/TinyMont/

| # | Ítem | Tipo | Estado |
|---|------|------|--------|
| B2 | `export_presets.cfg` para Web (HTML5) | infra | hecho |
| B3 | Pipeline CI: export headless + publish (GitHub Pages) | infra | hecho (deploy verde, live) |

## Milestone actual: `v0.2.0-alpha` — Editabilidad + personajes con vida

| # | Ítem | Estado |
|---|------|--------|
| C1 | Editor de mapa visual (TileMap nativo, swatches) | hecho |
| C2 | Carteles como nodos editables en el Inspector | hecho |
| C3 | NPCs migrados de código a nodos de escena | hecho |
| C4 | Sistema de personajes data-driven (rasgos → sprite de mapa + retrato) | hecho |
| C5 | Animación procedural (respiración, parpadeo, caminata) editable en Inspector | hecho |
| C6 | Branding web (ícono, boot splash, fondo) | hecho |
| C7 | Retratos en el cuadro de diálogo | pendiente |
| C8 | Gestos puntuales (AnimationPlayer / tween: saltito, saludo) | idea |
| C9 | Roster de figuras reconocibles (Monte Grande + íconos AR) | spec ([0008](../specs/0008-historia-principal-misiones/spec.md)) |

## Próximo milestone: `v0.3.0-beta` — Beta pública

Objetivo: **versión beta liberada**, jugable en web mobile y publicada en Play Store.

| # | Ítem | Estado |
|---|------|--------|
| D1 | Historia principal, personajes y diálogos definidos | spec ([0008](../specs/0008-historia-principal-misiones/spec.md)) |
| D2 | Mejorar jugabilidad (autonomía de NPCs) | spec ([0009](../specs/0009-npc-autonomia/spec.md)) |
| D3 | Vista web mobile (controles táctiles, canvas responsive) | idea |
| D4 | Export Android + publicación en Play Store | idea |

### Pendientes que vienen de 0.1.0
| # | Ítem | Estado |
|---|------|--------|
| B4 | Pantalla de título / menú inicial | spec ([0004](../specs/0004-pantalla-titulo/spec.md)) |
| B5 | Sistema de guardado (save/load) | spec ([0005](../specs/0005-sistema-guardado/spec.md)) |
| B6 | Transición entre mapas (plaza ↔ monte_grande) | spec ([0006](../specs/0006-transicion-mapas/spec.md)) |
| B7 | Música/SFX chiptune (revisar regla "sin assets") | idea |
| B8 | Más NPCs y mini-quests (ej: el gato de Doña Rosa) | idea |

## Backlog futuro (sin milestone)

- Día/noche (el Pipe menciona "cosas raras de noche en la estación").
- Inventario simple.
- Más barrios / mapas.
- Decisión: ¿migrar a Godot 4.7? (ver ADR pendiente — hoy en 4.4).

## Notas

- Migración de motor, sprites y dependencias externas **requieren ADR** (ver constitución).
