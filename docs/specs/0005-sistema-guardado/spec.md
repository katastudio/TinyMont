# Spec 0005 — Sistema de guardado (save/load)

- **Estado:** implementado (2026-10-03, junto con spec 0010 F4). Pendiente: CA3 en web.
- **Milestone:** mvp-0.1.0
- **Autor:** Martín
- **Relacionado:** roadmap #B5

## 1. Problema / motivación

No hay persistencia: si cerrás el juego, perdés posición y progreso. Para un RPG de
exploración, poder retomar dónde quedaste es básico.

## 2. Objetivo

El jugador puede guardar y, al volver a abrir, retomar su posición y estado en el mapa.

## 3. Alcance

**Incluye:** guardar/cargar posición del player, mapa actual, y flags simples (ej: NPCs
ya hablados). Guardado a archivo `user://save.json`.
**No incluye:** múltiples slots, autosave por zona (futuro).

## 4. Requisitos

- R1. API en `GameManager`: `save_game()` / `load_game()` / `has_save()`.
- R2. Persistencia en `user://` (compatible con export web — usa IndexedDB por debajo).
- R3. Serialización en JSON legible.
- R4. Acción de guardado desde el menú (`menu` / tecla X).

## 5. Criterios de aceptación

- [x] CA1. Guardar, cerrar y reabrir restaura la posición del player.
  *Verificado:* `test_guardado`.
- [x] CA2. `has_save()` permite a la pantalla de título mostrar "Continuar" (integra con 0004).
  *Verificado por captura de la pantalla de título.*
- [ ] CA3. Funciona en export web (persistencia en navegador).

## 6. Restricciones

- GDScript / sin deps. ✔ no requiere ADR (JSON es nativo de Godot).

## 7. Decisiones (2026-10-03)

- Guardado automático: cada hora de juego, al cambiar una misión y al cerrar o pasar a
  segundo plano. No hay guardado manual (R4 queda reemplazado por el autoguardado).
- Archivo único `user://partida.json`; el título ofrece CONTINUAR y "nueva partida".

## 8. Preguntas abiertas

- ¿Dónde se dispara el guardado? ¿menú o punto físico (ej: la casa del player)?

## Independencia (para paralelizar)

Toca `scripts/autoload/game_manager.gd` (agrega métodos) y crea `scripts/save/`.
✅ Bastante aislado. Riesgo bajo de conflicto con 0004/0006 (solo el autoload, en métodos nuevos).
