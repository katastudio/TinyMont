# Desarrollo en paralelo con git worktrees

Cómo corremos 2–3 features a la vez sin que se pisen. La **unidad de paralelismo es el spec**:
un spec aprobado = un track = un worktree = una rama = un PR.

## Reglas de oro

1. **Un track por worktree.** Cada feature vive en su propio checkout aislado.
2. **Solo se paraleliza lo independiente.** Si dos specs tocan los mismos archivos, van en serie.
3. **Cimientos primero, en serie.** Infra/base (repo, export, autoloads) antes de abrir tracks.
4. **Máximo 2–3 tracks vivos.** El cuello de botella es el review humano, no la generación.
5. **Spec antes de worktree.** Sin `spec.md` aprobado no se abre track (el agente improvisaría).

## Convención de nombres

- Rama: `feat/NNNN-nombre` (mismo `NNNN` que el spec).
- Worktree: `../TinyMont-NNNN-nombre/` (hermano del repo, fuera del árbol principal).

## Flujo manual (comandos)

```bash
# 1. Partir SIEMPRE de main actualizado y limpio (requiere B1 commiteado)
git switch main && git pull

# 2. Crear un worktree + rama para el track
git worktree add ../TinyMont-0005-save-system -b feat/0005-save-system

# 3. Trabajar ahí (abrir Godot/Claude apuntando a esa carpeta). Repetir para otros tracks.

# 4. Al terminar un track: commit, push y PR
cd ../TinyMont-0005-save-system
git add -A && git commit -m "[mvp-0.1.0] save system (spec 0005)"
git push -u origin feat/0005-save-system
gh pr create --fill

# 5. Tras mergear, limpiar el worktree
git worktree remove ../TinyMont-0005-save-system
git worktree prune
```

## Cómo encaja con los agentes (Claude Code)

- **Specs en paralelo (lectura/escritura independiente):** puedo generar varios `spec.md`
  a la vez en una sola sesión (no hay conflicto, son archivos distintos).
- **Implementación en paralelo (código):** cada track corre en su worktree aislado. Se puede
  lanzar un agente por worktree (`isolation: worktree`) o abrir sesiones separadas.
- **Orquestación estructurada:** si hay un lote grande de specs listos, se puede disparar un
  Workflow que fan-outee la implementación con verificación por track (opt-in, más tokens).

## Orden de ataque para `mvp-0.1.0`

```
SERIE (cimientos):   B1 (repo) ─► B2 (export web) ─► B3 (CI/CD)
                                                      │
PARALELO (features):                                 ├─ track 0004 (menú)   → PR
                                                      ├─ track 0005 (guardado) → PR
                                                      └─ track 0006 (transición) → PR
```

## Antes de mergear (checklist de integración)

- [ ] El PR pasa los criterios de aceptación de su spec.
- [ ] Rebase sobre `main` actual; resolver conflictos en el worktree, no en main.
- [ ] Corre en web (GL Compatibility) sin errores.
- [ ] `docs/memory/context.md` actualizado.
