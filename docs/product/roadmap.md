# Roadmap & Backlog — TinyMont

Backlog de alto nivel. Cada ítem, cuando se vaya a trabajar, se convierte en un
**spec** bajo `specs/NNNN-nombre/`. Estados: `idea` → `spec` → `en progreso` → `hecho`.

## Hecho: `mvp-0.0.1` (base)

- [x] Movimiento grid-based del player
- [x] Sistema de diálogo typewriter
- [x] GameManager autoload + señales
- [x] Mapa Monte Grande con NPCs
- [x] Render procedural estilo GB

## Publicado ✅: `v0.1.0` (antes `mvp-0.1.0`)

Objetivo cumplido: **primera versión jugable en web**.
Live: https://katastudio.github.io/TinyMont/

| # | Ítem | Tipo | Estado |
|---|------|------|--------|
| B2 | `export_presets.cfg` para Web (HTML5) | infra | hecho |
| B3 | Pipeline CI: export headless + publish (GitHub Pages) | infra | hecho |

## Hecho: `v0.2.0-alpha` — Editabilidad + personajes con vida

| # | Ítem | Estado |
|---|------|--------|
| C1 | Editor de mapa visual (TileMap nativo, swatches) | hecho |
| C2 | Carteles como nodos editables en el Inspector | hecho |
| C3 | NPCs migrados de código a nodos de escena | hecho |
| C4 | Sistema de personajes data-driven (rasgos → sprite de mapa + retrato) | hecho |
| C5 | Animación procedural (respiración, parpadeo, caminata) editable en Inspector | hecho |
| C6 | Branding web (ícono, boot splash, fondo) | hecho |

## Publicado ✅: `v0.5.0` — Beta inicial

Versión actual: **publicada en Play Store (internal test) y web**. Incluye:
- Migración a Godot 4.7.1 + target Android 16 (API 36)
- Controles táctiles en web y mobile
- Historia principal y misiones iniciales
- Pantalla de título + menú
- Sistema de guardado

| # | Ítem | Estado |
|---|------|--------|
| B4 | Pantalla de título / menú inicial | hecho |
| B7 | Música/SFX chiptune | hecho |
| D3 | Vista web mobile (controles táctiles, canvas responsive) | hecho |
| D4 | Export Android + publicación en Play Store | hecho |
| — | Migración a Godot 4.7.1 | hecho |

## Milestone `v0.6.0` — Mundo vivo 🌍 (implementado 2026-10-03)

Objetivo: **NPCs autónomos con vida propia**. Reloj de juego, necesidades, decisiones
emergentes, vida social y guardado.

| # | Ítem | Estado | Spec |
|---|------|--------|------|
| E1 | F1: grilla de ocupación, A*, pasos sin superposición, pausa selectiva | hecho | [0009](../specs/0009-npc-autonomia/spec.md) |
| E2 | F2: reloj, 18 POIs reales, necesidades, cerebro de utilidad, 23 fichas offline | hecho | [0010](../specs/0010-mundo-vivo/spec.md) |
| E3 | F3: charlas entre vecinos, rumores, relaciones, diálogos condicionados | hecho | [0010](../specs/0010-mundo-vivo/spec.md) |
| E4 | F4: guardado del mundo, autoguardado, CONTINUAR en el título | hecho | [0005](../specs/0005-sistema-guardado/spec.md) + [0010](../specs/0010-mundo-vivo/spec.md) |
| E5 | Verificación manual en Android y web (rendimiento, persistencia) | pendiente | — |

### Backlog pendiente (sin cambiar en v0.6.0)

| # | Ítem | Estado | Spec |
|---|------|--------|------|
| C7 | Retratos en el cuadro de diálogo | hecho (v0.7.0, `test_retrato_dialogo`) | — |
| C8 | Gestos puntuales: saltito y saludo procedurales | hecho (v0.7.0, `test_gestos`) | — |
| B5 | Sistema de guardado base | hecho (v0.6.0) | [0005](../specs/0005-sistema-guardado/spec.md) |
| B6 | Transición entre mapas (plaza ↔ monte_grande) | draft | [0006](../specs/0006-transicion-mapas/spec.md) |
| B8 | Más NPCs y mini-quests | idea | — |

## Backlog futuro (sin milestone)

- Transiciones día/noche con tinte de paleta (requiere ADR de assets).
- Inventario simple + objetos coleccionables.
- Más barrios / mapas (requiere ADR de scope + assets).
- Entrar/salir de edificios (requiere plan de arquitectura).
- Puntuación / logros / achievements.

## Notas

- Migración de motor, sprites y dependencias externas **requieren ADR** (ver constitución).
- NPCs con comportamiento inteligente: **IA offline + determinismo**, no runtime LLM (ADR-0003).
