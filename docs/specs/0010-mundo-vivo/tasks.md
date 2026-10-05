# Tasks 0010 — Mundo vivo

## F2 — Reloj, POIs, necesidades y cerebro
- [x] `WorldClock` autoload con tick lento, escala configurable y serialización
- [x] `PuntoInteres` editable en el Inspector
- [x] `CerebroNPC` de utilidad con plan semanal, horarios, capacidad y ruido sembrado
- [x] 18 POIs reales en `main.tscn`, cada uno en celda transitable
- [x] 23 fichas en `data/personajes` + plantilla de prompt + README del pipeline
- [x] Rutina `CEREBRO` en `npc.gd` y los 23 NPCs migrados
- [x] Tests: `test_cerebro_npc_unit`, `test_fichas`, `test_mundo_vivo` (8 horas)

## F3 — Vida social
- [x] `MemoriaNPC` con olvido a 3 días y relaciones
- [x] Coordinador de charlas en `MonteGrande` con globo de diálogo
- [x] Diálogos condicionados por relación, hambre y último chisme
- [x] La ayuda del jugador se vuelve noticia del barrio
- [x] Tests: `test_memoria_npc` y criterios sociales en `test_mundo_vivo`

## F4 — Guardado
- [x] `snapshot` / `restaurar` del mundo, NPCs, reloj, jugador y objetos tomados
- [x] API de guardado en `GameManager` y autoguardado
- [x] Título con CONTINUAR y nueva partida
- [x] Test: `test_guardado` (determinismo tras cargar)

## Pendiente
- [ ] Verificación manual en Android y en web (persistencia en el navegador, rendimiento)
- [x] Test de las rutinas de respaldo DEAMBULAR y PATRULLAR (`test_rutinas_simples`)
- [x] `dialogos_por_humor`: cinco ánimos derivados de las necesidades, líneas en las 23 fichas (`test_humor`)
- [x] Guardar la bici: posición y si el jugador va montado (`test_guardado`)
