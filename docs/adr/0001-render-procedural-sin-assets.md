# ADR 0001 — Render procedural sin assets binarios

- **Estado:** aceptado (decisión ya vigente en el código del MVP)
- **Fecha:** 2026-06-20
- **Relacionado:** constitución §2

## Contexto

TinyMont necesita gráficos estilo Game Boy. Las dos vías clásicas en Godot son:
(a) sprites/PNG + `TileMap` del editor, o (b) dibujo por código con `_draw()`.
El MVP ya está construido enteramente con la opción (b): mapas como `PackedInt32Array`
y todo el arte (player, NPCs, tiles, fuente, UI) generado con primitivas en `_draw()`.

## Decisión

Mantenemos **render 100% procedural por código, sin assets binarios**, como default del proyecto.

## Alternativas consideradas

- **TileMap + sprites (PNG):** estándar de la industria, mejor para artistas y mapas grandes.
  Contra: agrega archivos binarios, peso al `.pck`, y un pipeline de arte que hoy no tenemos.
- **Procedural `_draw()` (elegida):** cero assets, repo liviano, todo en GDScript, fácil de
  versionar y diffear. Contra: cada elemento visual es código; escalar contenido es más caro
  y no es amigable para colaboradores artistas.

## Consecuencias

**Positivas:**
- Repo liviano, sin binarios; diffs legibles; build reproducible.
- Coherencia estética garantizada (la paleta está en constantes).

**Negativas / costos:**
- Agregar mucho contenido visual nuevo es trabajo de programación, no de arte.
- Animaciones complejas son tediosas.

**Impacto en la constitución:** consolida §2 ("sin assets binarios cuando se pueda").
Introducir sprites en el futuro requerirá un nuevo ADR que reemplace o acote a éste.
