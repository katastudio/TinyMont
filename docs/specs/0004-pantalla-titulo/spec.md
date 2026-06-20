# Spec 0004 — Pantalla de título / menú inicial

- **Estado:** draft
- **Milestone:** mvp-0.1.0
- **Autor:** Martín
- **Relacionado:** roadmap #B4

## 1. Problema / motivación

El juego arranca directo en el mapa. Falta una pantalla de entrada que dé identidad
(logo TinyMont estilo GB) y un punto de inicio claro ("Presioná Start").

## 2. Objetivo

Al abrir el juego se muestra una pantalla de título; al presionar interactuar/Start,
se carga el mundo (`monte_grande`).

## 3. Alcance

**Incluye:** escena de título procedural (texto + prompt parpadeante), transición al mundo.
**No incluye:** opciones, créditos, selección de partida (eso depende de 0005).

## 4. Requisitos

- R1. Nueva escena `scenes/ui/title_screen.tscn` como `main_scene` inicial.
- R2. Render procedural (paleta GB), sin assets.
- R3. "PRESS START" parpadeante; acción `interact` o `menu` arranca el juego.

## 5. Criterios de aceptación

- [ ] CA1. Al abrir, se ve la pantalla de título (no el mapa).
- [ ] CA2. Al presionar Z/Enter/Space, carga `monte_grande` y se puede jugar.
- [ ] CA3. Corre en web sin errores de consola.

## 6. Restricciones

- Paleta GB / 160×144 / GDScript / sin assets. ✔ no requiere ADR.

## 7. Preguntas abiertas

- ¿Música de título? → depende de B7 (que sí podría requerir ADR por assets de audio).

## Independencia (para paralelizar)

Toca `scenes/ui/` y `project.godot` (cambia `main_scene`). ⚠ El cambio de `main_scene`
puede chocar con 0006 (transición de mapas) — coordinar el merge de ese campo.
