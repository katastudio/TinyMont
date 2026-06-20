# TinyMont — Documentación y memoria del proyecto

Esta carpeta es la **memoria de proyecto** de TinyMont y la fuente de verdad para trabajar
con **SDD (Spec-Driven Development)**: primero se escribe el *qué* y el *por qué* (spec),
después el *cómo* (plan), después las *tareas*, y recién ahí se programa.

> Regla de oro SDD: **no se escribe código de una feature sin un spec aprobado.**
> El código implementa la spec; la spec no documenta el código a posteriori.

## Cómo está organizada

```
docs/
├── README.md             # este archivo (índice + cómo usar)
├── constitution.md       # principios y reglas NO negociables del proyecto
├── product/
│   ├── vision.md         # qué es TinyMont, para quién, pilares de diseño
│   └── roadmap.md        # backlog de alto nivel / milestones
├── specs/                # 1 carpeta por feature: spec.md + plan.md + tasks.md
│   └── README.md         # convención de nombres y flujo
├── adr/                  # Architecture Decision Records (decisiones técnicas)
├── memory/
│   ├── context.md        # "dónde quedamos" — estado vivo del proyecto
│   └── memory-strategy.md# cómo manejamos memoria de agente (engram, etc.)
└── templates/            # plantillas para crear specs/tasks/adr nuevos
```

## El flujo de trabajo (ciclo SDD)

1. **Idea / backlog** → entra como ítem en [`product/roadmap.md`](product/roadmap.md).
2. **Spec** → se crea `specs/NNNN-nombre/spec.md` desde la plantilla. Define requisitos
   y criterios de aceptación. *Sin código todavía.*
3. **Plan** → `specs/NNNN-nombre/plan.md`: diseño técnico, archivos a tocar, trade-offs.
4. **Tasks** → `specs/NNNN-nombre/tasks.md`: lista accionable y verificable.
5. **Decisión relevante** → si hay una elección arquitectónica, se registra un ADR en `adr/`.
6. **Implementación** → se programa siguiendo el plan; cada task se marca al cerrar.
7. **Cierre** → se actualiza [`memory/context.md`](memory/context.md) con el nuevo estado.

## Convención de IDs

- Specs y ADRs usan numeración incremental de 4 dígitos: `0001`, `0002`, …
- Una feature = una carpeta `specs/NNNN-kebab-case/`.
- Un ADR = un archivo `adr/NNNN-kebab-case.md`.
