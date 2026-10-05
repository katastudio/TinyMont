# Spec 0007 — Fidelidad del mapa real + personajes típicos

- **Estado:** implementado en lo verificable (2026-10-04, v0.7.0).
- **Milestone:** mvp-0.1.0
- **Autor:** Martín
- **Relacionado:** roadmap #B8, ADR-0001 (render procedural)

## 1. Problema / motivación

El mapa actual ya evoca Monte Grande, pero queremos que el centro sea **reconocible
respecto de la ciudad real**: traza de calles, ubicación de la estación, la Plaza Mitre,
la Catedral, el municipio y los comercios icónicos. Además, poblarlo con **personajes
típicos** del lugar/conurbano para que el mundo se sienta vivo y local.

## 2. Objetivo

Que un vecino de Monte Grande reconozca su centro al jugar, y que cada personaje aporte
color costumbrista con diálogo en rioplatense.

## 3. Alcance

**Incluye:**
- Reordenar/ajustar la traza de calles y la posición de landmarks según datos reales.
- Agregar landmarks faltantes (Catedral, Palacio Municipal, peatonal/zona comercial).
- Sumar 4–8 NPCs de archetipos típicos con diálogo e interacción.

**No incluye:** mapas nuevos de otros barrios, quests con lógica (sólo diálogo por ahora).

## 4. Requisitos

- R1. La estación y las vías como eje de referencia con orientación correcta.
- R2. Plaza Mitre, Catedral y Municipio ubicados de forma coherente con la realidad.
- R3. Calles reales etiquetadas correctamente.
- R4. NPCs nuevos con nombre, personalidad y 2–4 líneas de diálogo localizado.
- R5. Todo procedural (sin assets) — respeta ADR-0001 y la constitución.

## 5. Criterios de aceptación

- [x] CA1. El centro es reconocible: estación + plaza + calles principales en disposición real.
  *Verificado (parcial):* `test_fidelidad`. La plaza está rodeada por Municipio, Escuela N°1, Comisaría,
  Parroquia, Casa de la Cultura (ex Hospital San José) y Banco Provincia, con fuente octogonal celeste de
  bordes blancos, según Wikipedia. **Sin verificar:** qué calle corre por cada lado de la plaza y la
  dirección exacta de la estación; las fuentes consultadas no lo dicen y no se renombraron calles.
- [x] CA2. Hay al menos 12 NPCs en total, varios de archetipos típicos, todos interactuables.
  *Verificado:* `test_fidelidad` (35 vecinos).
- [ ] CA3. Corre en web (GL Compatibility) sin errores.

## 6. Restricciones

- Paleta GB / 160×144 / GDScript / sin assets. ✔ no requiere ADR.

## 7. Preguntas abiertas

- ¿Cuánta fidelidad geográfica vs. jugabilidad? (un grid 44×48 no es 1:1 — priorizamos
  reconocibilidad sobre exactitud cartográfica).

## Fuentes

- Wikipedia: [Plaza Mitre (Monte Grande)](https://es.wikipedia.org/wiki/Plaza_Mitre_(Monte_Grande)) y
  [Parroquia Inmaculada Concepción (Monte Grande)](https://es.wikipedia.org/wiki/Parroquia_Inmaculada_Concepci%C3%B3n_(Monte_Grande)).
- Pendiente: contrastar la traza de calles con OpenStreetMap antes de mover el mapa.

- Investigación web sobre geografía de Monte Grande (Esteban Echeverría) — ver `context.md`.
