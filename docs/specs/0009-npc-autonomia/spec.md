# Spec 0009 — Autonomía de NPCs (rutinas por vecino)

- **Estado:** draft
- **Milestone:** v0.3.0-beta
- **Autor:** Martín
- **Relacionado:** roadmap #D2, spec 0008 (historia principal), ADR-0001 (render procedural)

## 1. Problema / motivación

Los NPCs están clavados en su celda: el barrio se ve vivo pero se siente estático.
Para que Monte Grande respire, los vecinos tienen que **moverse por la ciudad y hacer
sus cosas**: Tito camina hasta la plaza a jugar a las bochas, un vecino pasea al perro,
Walter recorre su línea. La autonomía además potencia la historia principal (spec 0008):
encontrar a un vecino en movimiento hace que recorrer el mapa sea parte del juego.

## 2. Objetivo

Que cada NPC pueda moverse por la ciudad y ejecutar una rutina propia, configurable
por nodo en el Inspector, sin romper la interacción de diálogo.

## 3. Alcance

**Incluye:**
- Movimiento grid-based de NPCs respetando `is_walkable`, sin atravesar al player,
  a otros NPCs ni a entidades interactuables.
- Rutinas data-driven por NPC, editables en el Inspector (misma filosofía que los
  rasgos visuales): deambular por una zona, patrullar puntos (waypoints), quedarse
  quieto, o una acción personalizada (ej: bochas, pasear al perro).
- Interacción estable: al hablarle, el NPC se detiene, mira al player y dialoga;
  al cerrar el diálogo retoma su rutina donde estaba.
- Al menos 3 rutinas personalizadas visibles en el mapa como ejemplo (Tito → bochas
  en la plaza; Walter → recorre "su línea"; un vecino → pasea al perro, con perro
  dibujado procedural).

**No incluye (out of scope):**
- Horarios / ciclo día-noche (backlog futuro).
- Pathfinding complejo entre puntos lejanos (alcanza con pasos grid y evasión simple).
- Entrar/salir de edificios.

## 4. Requisitos

- R1. La rutina de cada NPC se define como datos exportados en el nodo (tipo de rutina,
  zona/waypoints, velocidad, pausas), sin tocar código para configurarla.
- R2. El NPC nunca ocupa una celda no caminable ni la celda del player; dos NPCs no
  comparten celda.
- R3. Durante `is_dialog_active` del propio NPC, éste queda quieto y orientado hacia
  el player; el resto de los NPCs sigue su rutina.
- R4. La animación de caminata existente (spec de animación procedural) se reutiliza
  para el movimiento autónomo.
- R5. Un NPC en movimiento sigue siendo interactuable con la misma tecla y radio que
  uno quieto.
- R6. El movimiento autónomo no debe degradar el rendimiento en web (15+ NPCs activos).

## 5. Criterios de aceptación (verificables)

- [ ] CA1. Dado el mapa cargado, cuando pasan unos segundos, entonces al menos un NPC
  visible cambió de celda por su rutina.
- [ ] CA2. Dado un NPC en movimiento, cuando el player le habla, entonces el NPC se
  detiene, lo mira, dialoga, y al cerrar el diálogo retoma su rutina.
- [ ] CA3. Dado cualquier momento de juego, ningún NPC pisa celdas no caminables ni
  se superpone con el player u otro NPC.
- [ ] CA4. Tito, Walter y el vecino del perro ejecutan rutinas distintas y reconocibles
  configuradas sólo desde el Inspector.
- [ ] CA5. Corre en web (GL Compatibility) sin caídas de rendimiento perceptibles.

## 6. Restricciones (de la constitución)

- Paleta / 160×144 / GL Compatibility / GDScript / grid-based.
- El perro (u otras entidades de rutina) se dibuja por código. ✔ no requiere ADR.

## 7. Preguntas abiertas

- ¿Los NPCs con misión pendiente deberían quedarse cerca de su zona "canónica" para
  que el jugador los encuentre fácil? (propuesta: sí, deambular en radio corto).
- ¿El perro es interactuable (ladra) o decorativo?
