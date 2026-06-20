# ADR 0002 — Paleta colorida alegre (reemplaza la estética Game Boy)

- **Estado:** aceptado
- **Fecha:** 2026-06-20
- **Relacionado:** reemplaza ADR-0001 (en lo referido a color), constitución §1
- **Decidido por:** Martín (pedido explícito)

## Contexto

El MVP nació con la paleta original de Game Boy: 4 verdes fijos. Al verificar el juego
antes de publicar, se evaluó que el resultado es monótono y poco atractivo. Se busca una
identidad visual **alegre y colorida**, de referencia "Super Mario Bros".

## Decisión

Adoptamos una **paleta colorida estilo plataformero clásico (NES/SMB)** como identidad
visual del juego, centralizada en `scripts/palette.gd` (`class_name Pal`).

Se mantiene: pixel art nítido (filtro nearest), resolución base 160×144, GDScript,
render procedural sin assets (ADR-0001 sigue vigente en ese punto).

Se reemplaza: la restricción de "4 colores fijos Game Boy" de la constitución §1.

## Alternativas consideradas

- **Mantener GB (4 verdes):** identidad retro pura, pero el usuario la considera apagada.
- **Paleta colorida SMB (elegida):** más alegre y comercial; sigue siendo pixel art retro.

## Consecuencias

**Positivas:** juego más atractivo y vendible; color comunica mejor calles/agua/edificios.
**Negativas:** color por elemento agrega complejidad al render (más constantes y casos).

**Impacto en la constitución:** enmienda §1 (paleta). El resto de §1 (160×144, pixel art,
ambientación Monte Grande) se mantiene.
