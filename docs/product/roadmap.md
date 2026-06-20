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

## Próximo milestone: `mvp-0.1.0` (publicable)

Objetivo: **primera versión jugable y publicada en web**.

| # | Ítem | Tipo | Prioridad | Estado |
|---|------|------|-----------|--------|
| B1 | Higiene de repo: commitear contenido, arreglar `.gitignore` | infra | 🔴 alta | idea |
| B2 | `export_presets.cfg` para Web (HTML5) | infra | 🔴 alta | idea |
| B3 | Pipeline CI: export headless + publish a itch.io | infra | 🟠 media | idea |
| B4 | Pantalla de título / menú inicial | feature | 🟠 media | spec ([0004](../specs/0004-pantalla-titulo/spec.md)) |
| B5 | Sistema de guardado (save/load de posición y progreso) | feature | 🟠 media | spec ([0005](../specs/0005-sistema-guardado/spec.md)) |
| B6 | Transición entre mapas (plaza ↔ monte_grande) | feature | 🟠 media | spec ([0006](../specs/0006-transicion-mapas/spec.md)) |
| B7 | Música/SFX chiptune (revisar si rompe regla "sin assets") | feature | 🟢 baja | idea |
| B8 | Más NPCs y mini-quests (ej: el gato de Doña Rosa) | contenido | 🟢 baja | idea |

## Backlog futuro (sin milestone)

- Día/noche (el Pipe menciona "cosas raras de noche en la estación").
- Inventario simple.
- Más barrios / mapas.
- Decisión: ¿migrar a Godot 4.7? (ver ADR pendiente — hoy en 4.4).

## Notas

- Migración de motor, sprites y dependencias externas **requieren ADR** (ver constitución).
