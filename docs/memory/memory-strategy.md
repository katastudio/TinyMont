# Estrategia de memoria

Distinguimos **dos memorias** complementarias. No competen entre sí.

## 1. Memoria de proyecto (esta carpeta `/docs`)

- **Qué guarda:** specs, planes, decisiones (ADR), backlog, contexto.
- **Para quién:** humanos y agentes. Versionada en git, legible, diffeable.
- **Cómo:** SDD. Es la fuente de verdad del *qué* y *por qué*.
- **Autoridad:** máxima. Si un agente "recuerda" algo que contradice `/docs`, gana `/docs`.

## 2. Memoria de agente (runtime, entre sesiones)

- **Qué guarda:** lo que la IA aprendió trabajando (decisiones puntuales, gotchas, contexto
  de sesión) para no re-explicar todo cada vez.
- **Opciones evaluadas:**
  - **Memoria nativa de Claude Code** (archivos en el dir de proyecto del agente). Gratis,
    ya disponible, sin instalar nada. Buena para preferencias y hechos del proyecto.
  - **engram** (https://github.com/Gentleman-Programming/engram): binario Go + SQLite/FTS5,
    MCP, agent-agnostic. Mejor si se usan **varios agentes** (Cursor, Copilot, Claude…) que
    deben compartir memoria, o si se quiere búsqueda/timeline/sync por git.
- **Autoridad:** auxiliar. Lo importante se "promueve" a `/docs` (un spec o ADR), no se deja
  sólo en la memoria del agente.

## Regla de promoción

> Si algo que el agente recordó importa para el futuro del proyecto, **se escribe en `/docs`**
> (context.md, un ADR, o un spec). La memoria de agente es borrador; `/docs` es oficial.

## Decisión vigente

- **Memoria de proyecto:** SDD en `/docs` (este scaffold). ✅ adoptado.
- **Memoria de agente:** por ahora la nativa de Claude Code. Evaluar **engram** si sumamos
  más agentes o necesitamos memoria compartida/buscable. (Pendiente: ver veredicto en chat.)
