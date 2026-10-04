# Plan 0010 — Mundo vivo (F2–F4)

## Archivos

| Archivo | Rol |
|---|---|
| `scripts/autoload/world_clock.gd` | Autoload `WorldClock`: minutos de juego, tick cada 0,5 s real, señales `tick`, `hora_cambiada`, `dia_nuevo`, `avanzar()`, `reiniciar()`, serialización |
| `scripts/world/punto_interes.gd` | `PuntoInteres`: POI editable; `como_opcion()` lo traduce para el cerebro |
| `scripts/npc/cerebro_npc.gd` | `CerebroNPC`: utilidad pura y testeable |
| `scripts/npc/memoria_npc.gd` | `MemoriaNPC`: hechos, olvido, relaciones, charla, serialización |
| `scripts/npc/npc.gd` | Rutina `CEREBRO`: elige, camina, hace la actividad; charla; diálogos condicionados; `a_dict`/`restaurar` |
| `scripts/world/monte_grande.gd` | Recolecta POIs, coordina las charlas, `snapshot`/`restaurar`, autoguardado |
| `scripts/autoload/game_manager.gd` | `save_game`, `leer_partida`, `has_save`, `borrar_partida`, `autoguardar` |
| `scripts/ui/title_screen.gd` | CONTINUAR / nueva partida |
| `data/personajes/*.json` | 23 fichas generadas offline |
| `scenes/main.tscn` | 18 POIs reales; los 23 NPCs con `rutina = CEREBRO` |

## Flujo

1. Cada tick del reloj cada NPC suma urgencias; si está en actividad descuenta minutos.
2. Cuando el NPC espera, el cerebro puntúa los 18 POIs más su lugar propio y elige uno.
3. El NPC camina con la mecánica de F1 a la celda del POI o a la libre más cercana (radio 2).
4. Al llegar hace la actividad `duracion_min` minutos de juego; al terminarla se aplican sus efectos.
5. El mundo junta vecinos adyacentes: si uno quiere charlar y el otro está disponible, se frenan
   10 minutos, intercambian su novedad más reciente y suben la relación. Misma pareja: 1 hora de espera.
6. Hablar con el jugador suma relación; las líneas ambientales agregan saludo, hambre y último chisme.
   Completar una misión siembra la noticia en la memoria del NPC y el barrio la difunde.
7. Autoguardado cada hora de juego, al cambiar una misión y al pasar a segundo plano (no en headless).

## Decisiones

- **Lugar propio en vez de 23 casas inventadas.** Cada NPC vuelve a su celda de origen; así los
  puesteros trabajan en su puesto y quienes dan misiones siguen ubicables entre las 7 y las 22.
- **El bonus del plan no se descuenta por distancia.** Con descuento, una rutina lejana perdía
  contra cualquier necesidad cercana y Tito nunca iba a las bochas.
- **Charla con "al menos uno con ganas".** Ver enmienda en la spec.
- **El reloj no se pausa en diálogos.** Sólo se frena el NPC con el que habla el jugador.
- **Sin tinte día/noche.** La spec lo deja fuera de alcance.

## Trampas encontradas

- JSON entrega números como float: `0 in [0.0]` es falso. El plan se normaliza a int al cargar.
- `class_name` igual al nombre de un autoload rompe el autoload.
- Tras crear `class_name` nuevos hay que regenerar la caché (`godot --headless --editor --quit`).
- Un objeto levantado dejaba su celda reservada para siempre: la grilla ahora descarta ocupantes liberados.
