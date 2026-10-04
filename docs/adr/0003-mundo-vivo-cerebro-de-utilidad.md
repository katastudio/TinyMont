# ADR 0003 — Mundo vivo: cerebro de utilidad + fichas offline + WorldClock

- **Estado:** aceptado
- **Fecha:** 2026-10-02
- **Relacionado:** spec 0009 (F1: movimiento), spec 0010 (F2–F4: mundo vivo), constitución §2

## Contexto

Con los NPCs moviéndose (spec 0009, F1), el siguiente paso es hacerlos **agentes
inteligentes** que tomen decisiones realistas: Tito va a jugar bochas cuando le entra
hambre y ocio; Walter recorre su línea respetando un horario. Hay varias arquitecturas
posibles para IA de NPCs en juegos 2D pequeños, cada una con trade-offs distintos.

Fuerzas en juego:
- **Determinismo:** el juego es offline y debe ser reproducible (mismo archivo guardado
  = mismo futuro).
- **Rendimiento:** 23+ NPCs en web sin caídas perceptibles respecto al framerate de referencia.
- **Mantenibilidad:** fichas de personaje deben ser editables sin recompilar.
- **Escala:** hoy 23 vecinos; en futuro, podrían ser más.
- **Riqueza de comportamiento:** cada NPC debe parecer único, con vida propia.

## Decisión

Implementamos un **sistema de utility-based AI (IA de utilidad) en runtime, alimentado
por fichas de personaje generadas offline con asistencia LLM**.

### Componentes

1. **WorldClock autoload**: emite ticks lentos (~0.5 s real = 1 minuto de juego).
   RNG seeded en reloj para reproducibilidad.

2. **Fichas de personaje (JSON, generadas offline)**: cada NPC tiene un archivo JSON con:
   - Pesos de afinidad por necesidad (hambre, energía, social, ocio, deber).
   - Rutina semanal (actividades esperables por día/hora).
   - Hechos semilla (rumores iniciales).
   - Relaciones iniciales con otros NPCs.
   
   **Clave:** el LLM se usa UNA SOLA VEZ, offline, por personaje. Cero llamadas a runtime.

3. **Grilla de ocupación**: O(1) lookup de "quién ocupa dónde", evita colisiones dinámicas.

4. **Cerebro de utilidad por NPC (cada tick del reloj):**
   ```
   Para cada POI/acción candidata:
     utilidad = urgencia(necesidad) × afinidad(necesidad)
              × encaje_horario(POI) / (1 + distancia/8)
              + ruido_sembrado
   ejecutar acción con máxima utilidad
   ```
   
   Ventaja: barato computacionalmente, fácil de debuggear, determinista.

5. **Emergencia social (F3):** dos NPCs adyacentes charlan, intercambian hechos, mejoran
   relación. Propagación de rumores emerge automáticamente.

## Alternativas consideradas

### A. Horarios fijos (estilo Stardew Valley / Majora's Mask)

Cada NPC tiene un guión per-día: "9:00 AM: ir a plaza", "11:30 AM: kiosco", etc.

**Pros:**
- Súper predecible y debuggeable.
- Mínima CPU (lookup en array).

**Contras:**
- NPCs son robots, sin flexibilidad ni emergencia.
- No aprenden ni evolucionan.
- Misma vida cada día; aburridor a largo plazo.
- Difícil de expandir a más personajes sin editar cada rutina manualmente.

❌ **Rechazada:** no deja espacio para que el mundo "respire".

### B. GOAP (Goal-Oriented Action Planning) / Behaviour Trees

Sistema genérico donde cada NPC planifica acciones para lograr un goal, con backtracking
si falla. Ej: comportamiento "comer en kiosco" se descompone en "ir a kiosco" + "esperar
hasta que haya espacio" + "come" + "vuelve a casa".

**Pros:**
- Flexible y jerárquico.
- Muchas gemas Godot lo soportan (tilemancer, beehive, ...)
- Bueno para comportamientos complejos (entrar/salir, multi-paso).

**Contras:**
- Complejidad: requiere definir task network o tree para cada acción.
- Overhead de planeamiento: O(n) por NPC por tick, potencialmente más.
- Terceras dependencias (ADR requerido por constitución).
- Overkill para 23 vecinos con necesidades simples.
- Debugging de estado compartido es difícil (condiciones globales).

❌ **Rechazada:** complejidad innecesaria para el scope actual. Podría revisarse en futuro
si los NPCs necesitan comportamientos multi-paso elaborados (entrar en edificio, esperar,
salir, etc.).

### C. Utilidad + fichas offline (elegida)

Cada NPC tiene un cerebro simple que toma decisiones basadas en:
- Necesidades que decaen en tiempo.
- Afinidades personales (pesos).
- Rutina semanal (bias hacia lugares esperables).
- Distancia a POIs.

Fichas se generan offline (una sola vez) con LLM, nunca en runtime.

**Pros:**
- ✔ Determinista y reproducible (misma seed = mismo comportamiento).
- ✔ Barato computacionalmente: O(n) por NPC, una suma + comparación por POI.
- ✔ Emergencia: rutinas + necesidades = comportamiento "vivo" sin hardcode.
- ✔ Offline LLM: sin latencia, sin costo por jugador, offline-first.
- ✔ Data-driven: fichas editables sin recompilar.
- ✔ Extensible: nuevos NPCs = copiar JSON + llenar campos.
- ✔ Responsable y auditable: el uso del LLM es transparente en el repo (fichas versionadas).

**Contras:**
- ⚠ Menos flexible para acciones multi-paso (eso es spec 0011+).
- ⚠ Requiere herramientas: generador de fichas asistido por LLM y validador (scripts, no gameplay).
- ⚠ Si una ficha está mal, un NPC puede comportarse raro (pero debuggeable: basta
  revisar el JSON).

✅ **Elegida:** mejor balance de complejidad, rendimiento y mantenibilidad para v0.6.0.

## Consecuencias

### Positivas

- **Emergencia vs. hardcode:** el mundo se siente "vivo" sin escribir 23 scripts distintos.
  Dos NPCs charlan espontáneamente; rumores se propagan; relaciones evolucionan.
- **Reproducibilidad:** save/load + seed garantizan que el mundo evoluciona igual.
  Crítico para testeo y debugging.
- **Offline-first:** funciona sin internet. Crítico para web y Play Store.
- **Expansibilidad:** pasar de 23 a 50+ NPCs es cuestión de generar más JSONs; lógica
  de IA es genérica.
- **Responsabilidad:** LLM se usó offline, una vez. No es "magic box" en runtime;
  es herramienta asistente.

### Negativas / costos

- **Setup inicial:** requiere escribir un generador de fichas y un validador (scripts de
  herramienta, 100–200 líneas cada uno).
- **Validez de fichas:** si una ficha es inconsistente (ej: rutina que referencia un POI
  que no existe), el NPC puede comportarse mal. Necesita validador en `_ready()` del NPC.
- **Límites de la utilidad:** funciona bien para decisiones "¿dónde quiero ir?". Si un NPC
  necesita planificar secuencias (ej: robar a alguien, crear conflicto), utility puro es
  insuficiente. Eso es spec 0011 (si llega).
- **Ajuste empírico:** los pesos de utilidad son números. Si Tito nunca va a bochas, habrá
  que ajustar `ocio_afinidad` o `horarios_preferidos` manualmente. Requiere playtesting.

### Impacto en la constitución

Enmienda: **ninguna**. La decisión respeta todos los principios:
- §1 (identidad): NPCs siguen siendo costumbristas, locales, con voz propia.
- §2 (restricciones técnicas): GDScript, GL Compatibility, cero addons (LLM es offline tool,
  no addon); fichas JSON son datos, no assets binarios.
- §3 (proceso SDD): esta decisión está documentada en ADR + specs 0009/0010. Código respeta
  TDD (tests headless verifican CA*).
- §4 (higiene): fichas se versionan. Reproducibilidad garantizada.

Abre **uno nuevo** potencial (futura enmienda): "Generación de contenido con IA offline
es permitida siempre y cuando sea auditable y no ejecute runtime."

## Implementación esperada

1. Script `scripts/tools/generate_personaje.gd`: herramienta que, dado un prompt LLM,
   valida y guarda JSON.
2. Clase `class_name PuntoInteres`: nodos editable en escena con capacidad, necesidades,
   horarios.
3. Clase `class_name CerebroNPC`: realiza cálculo de utilidad cada tick del reloj.
4. Script `scripts/tools/validate_personajes.gd`: ejecuta pre-game, valida todas las fichas.
5. Test headless `tests/test_mundo_vivo.tscn`: verifica CA1–CA7 de spec 0010.

## Aceptación y fecha

Diseño aprobado internamente: **2026-10-02**. Listo para fase F1 (spec 0009, movimiento)
que es prerequisito de F2–F4.
