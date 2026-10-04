# Prompt: ficha de personaje (generación offline)

Se usa con un LLM **en tiempo de diseño**, nunca en runtime (ADR-0003). La salida se guarda en
`data/personajes/<id>.json` y se valida con `tests/test_fichas.tscn`.

## Entrada

- Nombre del NPC (`npc_name` en `scenes/main.tscn`) y sus líneas de diálogo actuales.
- Si da una misión, cuál (debe seguir ubicable entre las 7 y las 22).
- Lista de POIs disponibles (abajo).

## Prompt

```
Sos guionista de TinyMont, un RPG estilo Game Boy ambientado en Monte Grande (Buenos Aires).
Escribí la ficha de comportamiento de {NOMBRE}. Sus diálogos actuales son: {DIALOGOS}.
{SI_DA_MISION: "Da la misión {MISION}: tiene que pasar el día cerca de su lugar propio."}

Tono costumbrista, cálido y respetuoso. Si el personaje está inspirado en una figura pública,
mantenelo amable y genérico: nada de escándalos inventados ni datos privados.

Devolvé SOLO un JSON con este esquema:
- id: snake_case sin acentos derivado del nombre
- nombre, descripcion (una oración)
- personalidad.afinidad: {hambre, energia, social, ocio, deber} entre 0 y 1
- personalidad.fuerza_rutina: entre 0 y 1 (puesteros y quienes dan misiones: 0.9 o más)
- decaimiento: {hambre, energia, social, ocio, deber} en puntos de urgencia por hora (3 a 10)
- necesidades_iniciales: opcional, urgencias de 0 a 100
- lugar_propio.satisface: qué necesidades alivia su casa o su puesto
- plan_semanal: lista de {dias: [0=lunes..6=domingo] o [] para todos, desde, hasta, poi}
  usando SOLO ids de la lista de POIs o "propio". Incluí la noche en "propio" (22 a 7).
- rumores_semilla: 2 o 3 frases cortas, completas, que otros vecinos puedan repetir
- dialogos_por_humor: {} (reservado)

POIs: anden, plaza_fuente, plaza_bancos, cancha_bochas, mostaza, kfc, burger, la_veneciana,
mcdonalds, el_faro, iglesia, escuela, comisaria, municipio, club, clinica, parada_306,
terminal_306.
```

## Política de regeneración

- Se regenera a mano cuando cambia el personaje o el mapa, nunca durante el juego.
- Toda ficha nueva o regenerada se revisa a ojo y pasa `test_fichas` antes de commitear.
