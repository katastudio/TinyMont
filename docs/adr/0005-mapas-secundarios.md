# ADR 0005 — Mapas secundarios sobre un mundo principal que nunca se detiene

- **Estado:** aceptado
- **Fecha:** 2026-10-04
- **Relacionado:** spec 0006 (transición entre mapas), spec 0010 (mundo vivo), roadmap "Entrar a edificios", "Más barrios"

## Contexto

El backlog pide entrar a edificios, otros barrios y transiciones entre mapas. El mapa
principal (`MonteGrande`) contiene el mundo vivo: reloj, 35 vecinos con cerebro, ocupación,
guardado y la fiesta final. Cambiar de escena con `change_scene` lo destruiría y cortaría la
simulación y el estado en memoria.

## Decisión

- El mapa principal **nunca se destruye**. Al cruzar una puerta se oculta, su jugador se congela
  en la vereda y su simulación sigue corriendo (los vecinos siguen con su día).
- Los mapas secundarios (`MapaSecundario`) se cargan como hermanos del principal. Se arman
  desde un plano de texto, se dibujan por código e implementan la misma interfaz que
  `MonteGrande` (`is_walkable`, `get_npc_at`, `ocupacion`, `camino`, ...), así el jugador y los
  NPCs funcionan sin cambios. Tienen su propio Monti y su cámara.
- Las puertas (`Portal`) se colocan sobre la celda de la puerta de un edificio; se entra caminando
  contra ella. En el mapa secundario, caminar contra la salida (`X`) vuelve a la vereda.
- `GameManager.ir_a_mapa` / `volver_al_barrio` coordinan el cambio con un fundido a negro.
- El guardado sigue siendo del mundo principal: guardar adentro deja a Monti en la vereda.
- El prototipo `plaza.gd` (paleta Game Boy, sin referencias, duplicaba la Plaza Mitre del mapa
  principal) se retira; spec 0006 pasa a cubrir los mapas secundarios.

## Alternativas consideradas

- **`change_scene` entre mapas** — simple, pero destruye el mundo vivo y obliga a serializarlo
  en cada puerta.
- **Todo en un solo mapa gigante** — sin transiciones, pero los interiores no entran en la
  grilla de 44×48 y el rendimiento web sufre.
- **Mapas superpuestos con el principal vivo (elegida)** — conserva la simulación y reutiliza
  la interfaz existente.

## Consecuencias

**Positivas:** se pueden sumar interiores y barrios con un plano de texto y una puerta; el
barrio sigue vivo mientras Monti está adentro.

**Negativas / costos:** los NPCs de los mapas secundarios no tienen cerebro ni misiones del
catálogo (el álbum vive en el mapa principal); hay dos jugadores en memoria mientras dura la visita.

**Impacto en la constitución:** ninguno (GDScript, sin assets, grilla lógica).
