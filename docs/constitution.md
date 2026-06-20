# Constitución de TinyMont

Principios **no negociables**. Toda spec, plan y ADR debe respetarlos; si una propuesta
los contradice, primero se enmienda esta constitución (con un ADR que lo justifique).

## 1. Identidad

- **Género:** RPG top-down de exploración, costumbrista, ambientado en Monte Grande (Buenos Aires).
- **Tono:** local, en español rioplatense. Los NPCs hablan como vecinos reales.
- **Pixel art alegre estilo plataformero clásico (NES/Super Mario Bros):** paleta
  **colorida** centralizada en `scripts/palette.gd` (`class_name Pal`). Resolución nativa
  **160×144** escalada por enteros, filtro *nearest* (pixel art nítido, sin suavizado).
  _(La paleta GB original de 4 colores fue reemplazada — ver [ADR-0002](adr/0002-paleta-colorida.md).)_

## 2. Restricciones técnicas

- **Motor:** Godot 4.x, **GDScript** (no C#, salvo ADR que lo justifique).
- **Renderer:** **GL Compatibility** — el juego debe poder correr en web y hardware viejo.
- **Sin assets binarios cuando se pueda:** el arte se genera por código (`_draw()`).
  Introducir sprites/PNG requiere un ADR (cambia el pipeline y el peso del `.pck`).
- **Cero dependencias de terceros** sin ADR. Hoy el proyecto no tiene `addons/`; es una ventaja.
- **Movimiento grid-based** (tile a tile, 16px). No se usa la física del motor para el player
  salvo justificación; la colisión es lógica (`is_walkable`).

## 3. Reglas de proceso (SDD)

- Toda feature nace de un **spec aprobado** antes de programar.
- Toda decisión arquitectónica relevante queda en un **ADR**.
- El estado vivo del proyecto se mantiene en `memory/context.md`.

## 4. Higiene de repositorio

- Nada de `.DS_Store`, `builds/`, `*.pck`, `.godot/` en el control de versiones.
- Commits con prefijo de milestone: `[mvp-0.0.1] ...`.
- El contenido del juego (scenes/scripts/tilesets) **siempre versionado**.

## 5. Calidad y operabilidad

- Cada feature define **criterios de aceptación verificables** en su spec.
- Releases reproducibles: export por CLI headless, no "desde la compu de alguien".
