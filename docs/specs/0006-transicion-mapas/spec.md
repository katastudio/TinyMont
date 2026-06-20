# Spec 0006 — Transición entre mapas

- **Estado:** draft
- **Milestone:** mvp-0.1.0
- **Autor:** Martín
- **Relacionado:** roadmap #B6

## 1. Problema / motivación

Hay dos mapas (`monte_grande`, `plaza`) pero no hay forma de pasar de uno a otro.
Sin transición, `plaza` es código muerto y el mundo no se siente conectado.

## 2. Objetivo

El jugador cruza un "borde/puerta" en un mapa y aparece en el mapa destino, en la
posición correcta, con una transición visual (fade GB).

## 3. Alcance

**Incluye:** tiles de tipo "portal" con destino y spawn; cambio de escena de mundo;
fade out/in. Antes, arreglar que `plaza` implemente `is_walkable`/`get_npc_at`.
**No incluye:** mapa overworld, mini-mapa.

## 4. Requisitos

- R1. Definir portales (posición + escena destino + spawn destino).
- R2. Cargar/instanciar el mapa destino y posicionar al player.
- R3. Fade simple con `CanvasLayer` (paleta GB).
- R4. `plaza.gd` debe implementar `is_walkable()` y `get_npc_at()` (hoy le faltan).

## 5. Criterios de aceptación

- [ ] CA1. Pisar un portal en `monte_grande` lleva a `plaza` en el spawn correcto, y viceversa.
- [ ] CA2. En `plaza` las paredes ya no son atravesables (deuda técnica resuelta).
- [ ] CA3. La transición no deja diálogos ni input "pegados".

## 6. Restricciones

- GDScript / sin assets. ✔ no requiere ADR.

## 7. Preguntas abiertas

- ¿La transición la coordina `GameManager` o un nodo `WorldManager` nuevo?
  → posible ADR si introducimos un gestor de mundos.

## Independencia (para paralelizar)

Toca `scripts/world/*` (ambos mapas) y posiblemente `GameManager`/`main.tscn`.
⚠ Mayor superficie de conflicto. Coordinar con 0004 (ambos tocan `main_scene`/arranque).
Sugerencia: mergear 0004 primero, después rebasear 0006.
