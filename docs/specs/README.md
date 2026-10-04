# Specs

Una carpeta por feature: `specs/NNNN-kebab-case/`.

Cada carpeta contiene (en este orden de creación):

1. `spec.md`  — el **qué** y el **por qué**. Requisitos + criterios de aceptación. (plantilla: [`../templates/spec.template.md`](../templates/spec.template.md))
2. `plan.md`  — el **cómo**. Diseño técnico, archivos a tocar, trade-offs.
3. `tasks.md` — la **ejecución**. Lista accionable y verificable. (plantilla: [`../templates/tasks.template.md`](../templates/tasks.template.md))

## Reglas

- No se programa una feature sin su `spec.md` aprobado.
- El número `NNNN` es incremental y no se reutiliza.
- Si durante el plan aparece una decisión arquitectónica, se crea un ADR en `../adr/` y se linkea.
- Al terminar, se actualiza `../memory/context.md`.

## Índice de specs

| # | Feature | Estado | Milestone |
|---|---------|--------|-----------|
| [0004](0004-pantalla-titulo/spec.md) | Pantalla de título / menú inicial | draft | mvp-0.1.0 |
| [0005](0005-sistema-guardado/spec.md) | Sistema de guardado (save/load) | implementado | v0.6.0 |
| [0006](0006-transicion-mapas/spec.md) | Transición entre mapas | draft | mvp-0.1.0 |
| [0007](0007-fidelidad-mapa-personajes/spec.md) | Fidelidad del mapa real + personajes típicos | en progreso | mvp-0.1.0 |
| [0008](0008-historia-principal-misiones/spec.md) | Historia principal y misiones (álbum del barrio) | draft | v0.3.0-beta |
| [0009](0009-npc-autonomia/spec.md) | NPCs en movimiento: F1 ocupación + pathing + rutinas | implementado | v0.6.0 |
| [0010](0010-mundo-vivo/spec.md) | Mundo vivo: reloj + necesidades + utilidad + vida social (F2–F4) | implementado | v0.6.0 |
