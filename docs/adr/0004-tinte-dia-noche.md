# ADR 0004 — Tinte día/noche sobre la paleta

- **Estado:** aceptado
- **Fecha:** 2026-10-04
- **Relacionado:** ADR-0002 (paleta), spec 0010 (reloj del mundo), roadmap "Día/noche"

## Contexto

El mundo vivo tiene reloj y rutinas por hora (spec 0010), pero de noche el barrio se ve
igual que al mediodía. La constitución centraliza los colores en `Pal`; teñir cambia el
color final de cada píxel, por eso la decisión necesita un ADR.

## Decisión

Un `CanvasModulate` en el mapa (`TinteDia`) multiplica el color del mundo según la hora.
La curva vive en `scripts/world/ciclo_dia.gd` (`CicloDia.tinte`): noche azulada, amanecer
rosado, día sin tinte y atardecer cálido, interpolando minuto a minuto. La interfaz vive en
`CanvasLayer` propios y no se tiñe. De noche la luminancia no baja del 50 %.

## Alternativas consideradas

- **Paletas alternativas por hora en `Pal`** — control total del color, pero duplica cada
  constante y obliga a redibujar todo el mapa al cambiar la hora.
- **Shader de post-proceso** — flexible, pero suma complejidad y riesgo en GL Compatibility/web.
- **CanvasModulate (elegida)** — una línea de código por tick, cero assets, compatible con web.

## Consecuencias

**Positivas:** el barrio cambia con la hora y refuerza las rutinas (de noche todos en casa).

**Negativas / costos:** los colores de `Pal` dejan de ser exactos de noche; el arte nuevo
debe leerse bien también con el tinte nocturno.

**Impacto en la constitución:** precisa §1: la paleta es la base diurna; el tinte horario
del mundo está permitido mientras la interfaz conserve los colores de `Pal`.
