# Fichas de personaje

Una ficha JSON por NPC de `scenes/main.tscn`. El NPC la carga en `_ready()` según su
`ficha_id` o, si está vacío, según su `npc_name` normalizado ("Doña Rosa" → `dona_rosa.json`).
Sin ficha válida, el NPC usa DEAMBULAR con radio 2 y avisa con `push_warning`.

- **Esquema:** ver `docs/specs/0010-mundo-vivo/spec.md`, sección 6.
- **Generación:** offline, con el prompt de `tools/prompts/ficha_personaje.md` (ADR-0003).
  Ningún LLM corre durante el juego.
- **Validación:** `godot --headless --path . res://tests/test_fichas.tscn` comprueba campos,
  rangos, que cada POI del plan exista y sea transitable, y que todo NPC tenga ficha.
