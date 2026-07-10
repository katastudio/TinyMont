# Spec 0008 — Historia principal y misiones (el álbum del barrio)

- **Estado:** draft
- **Milestone:** v0.3.0-beta
- **Autor:** Martín
- **Relacionado:** roadmap #D1, spec 0007 (personajes típicos), spec 0009 (autonomía de NPCs), ADR-0001 (render procedural)

## 1. Problema / motivación

El juego ya tiene un mundo reconocible y 15 vecinos con diálogo costumbrista, pero no hay
**objetivo de juego**: se camina y se conversa, y nada más. Queremos una historia principal
que le dé propósito a la exploración y convierta "conocer Monte Grande" en el gameplay
central, de forma divertida y entretenida.

## 2. Objetivo

Que el jugador, como **Monti** (el recién llegado), complete el juego recorriendo Monte
Grande: cada personaje emblemático le encarga una misión, al cumplirla le regala un
**objeto icónico**, y al coleccionar todos los objetos del roster definido Monti
completa su **álbum del barrio** y gana el juego. El roster se construye de forma
incremental, personaje a personaje.

## 3. Historia

Monti baja del tren en la estación de Monte Grande con su mochila y su gorra roja.
Es nuevo en la ciudad. A la salida de la estación lo recibe **Marcos**, el vendedor
de café de la estación de toda la vida, con un cafecito caliente. Marcos le cuenta
un poco de la historia de la ciudad, le adelanta qué personajes puede encontrarse
por el barrio y le da la consigna: *"Acá no sos vecino hasta que el barrio te
conoce"*. Ahí mismo le encarga la **primera misión**. Para ganarse el título de
vecino, Monti tiene que conocer a los personajes emblemáticos, ayudarlos con lo que
necesiten y juntar el recuerdo que cada uno le regala. Cuando el álbum está completo,
todos lo reciben en la Plaza Mitre y Monti se convierte en un vecino más de Monte
Grande (final del juego).

## 4. Roster de personajes (fase 1) — construcción incremental

El elenco reemplaza a los vecinos de prueba de la etapa anterior y se define
**personaje a personaje**: cada uno se diseña y valida individualmente antes de
sumarse al juego. Todas las misiones se resuelven **hablando y recorriendo el mapa**
(recados entre personajes, búsquedas de objetos en la vía pública). Ninguna requiere
entrar a edificios.

### 4.1 Personajes definidos

| # | Personaje | Referencia | Identidad | Rasgos visuales (sistema actual) | Misión (fase 1) | Objeto icónico |
|---|-----------|------------|-----------|----------------------------------|-----------------|----------------|
| 00 | Marcos | El vendedor de café de la estación (El Diario Sur, 2025) | Vende café y mate a la salida de la estación desde 2001. Sale de su casa a las 3 AM y vive a 20 cuadras. *"El café se toma todo el año, como el mate"*. Es el **guía inicial**: recibe a Monti al bajar del tren, le cuenta la historia de la ciudad, le adelanta qué personajes andan por el barrio y le encarga la primera misión | piel media, `mustache`, `beanie` de lana, camiseta marrón (color café) | Primera misión (tutorial): se le están acabando los vasitos y no puede dejar el puesto. Le pide el favor de ir a su otro puesto en Plaza Mitre, donde su compañera **Sandra** tiene vasos para compartirle, y volver con ellos | Cafecito de la estación |
| 01 | Sandra | La vendedora de la estación (El Diario Sur, 2025) | Compañera de Marcos, 8 años vendiendo café, té, mate cocido, chipá y facturas. Arranca a las 4:30 AM. Atiende el otro puesto, en Plaza Mitre. En la misión 00 le comparte los vasos a Monti | piel media, pelo `long` oscuro recogido, `beanie`, camiseta bordó | Por definir (participa en la misión 00 entregando los vasos; su misión propia se diseña después) | Por definir |

Notas:
- La misión de Marcos enseña el core loop: recibir un encargo, cruzar la ciudad hasta un
  punto del mapa (estación → Plaza Mitre), dialogar con otro personaje y volver.
- En ese primer recorrido Monti se cruza con más personajes y misiones disponibles
  (descubrimiento orgánico del mundo).
- El puesto de Marcos está en la celda de salida de la estación (spawn actual de Monti),
  así el encuentro es inevitable al empezar. El puesto de Sandra está en Plaza Mitre.

### 4.2 Candidatos a futuros personajes (pendientes de definición individual)

Backlog de **homenajes reconocibles** a figuras reales (6 nacidas en Monte Grande + 9
íconos nacionales), con nombre de guiño — nunca el nombre real completo (ver R7).
Cada fila se revisará y validará **una por una** con el autor antes de pasar a
"definidos"; misiones y objetos son propuestas iniciales.

| # | Personaje | Referencia | Identidad | Rasgos visuales (sistema actual) | Misión (fase 1) | Objeto icónico |
|---|-----------|------------|-----------|----------------------------------|-----------------|----------------|
| — | Don Salina | Luis Salinas | El guitarrista de manos mágicas, nacido acá | pelo `bald`, barba gris, `fedora` marrón, camiseta marrón | Escuchar su historia del barrio y avisarle a Gille que lo espera para zapar en la plaza | Púa de madera |
| 01 | Gille | Gillespie (Sumo) | El trompetista de la banda de leyenda, de Monte Grande | pelo `short` canoso, `fedora` negra, `lentes`, `mustache`, camiseta roja | Encontrar su trompeta, olvidada en la plaza después del ensayo | Trompeta de bolsillo |
| 02 | Tiaguito | Tiago PZK | El pibe del trap nacido acá, orgullo del barrio | piel media, pelo `curly` negro, `beanie` negro, camiseta negra | Encontrar su libreta de rimas perdida cerca de la estación | Rima manuscrita |
| 03 | Rodri | Rodrigo Tapari | La voz de la cumbia, nacido en Monte Grande | pelo `slick` negro, `stubble`, camiseta violeta con `badge` | Repartir 3 invitaciones para su show de cumbia en el Teatro | CD de cumbia |
| 04 | Juli Noticias | María Julia Oliván | La periodista del barrio, siempre detrás de la nota | pelo `long` rubio, `lentes`, camiseta blanca con `badge` | Dar la entrevista del "recién llegado" (requiere 5 misiones completadas) | Portada del diario del barrio |
| 05 | Caby | Horacio Cabak | El conductor elegante de la TV, de la zona | pelo `slick` blanco, camiseta celeste clara | Avisarle a Juli Noticias que el móvil de TV sale desde la plaza | Corbata elegante |
| 06 | El Diez | Lionel Messi | El mejor del mundo, de visita en el barrio | pelo `short` castaño, `beard`, camiseta celeste con `stripes` blancas | Encontrar la pelota que se le fue a los árboles de la plaza | Pelota dorada |
| 07 | El Atajatodo | Dibu Martínez | El arquero campeón que ataja todo | pelo `short` rubio, camiseta verde de arquero con `badge` | Encontrar sus guantes de la suerte, perdidos cerca del club | Guantes dorados |
| 08 | Franquito | Franco Colapinto | El piloto argentino que corre en el mundo | pelo `short` castaño, `cap` azul con `badge`, camiseta azul | Entrega contrarreloj: llevar su mensaje de la estación al club antes de que se acabe el tiempo | Casco de carrera |
| 09 | El Duko | Duki | La estrella del trap, el número uno | pelo `curly` platinado, `lentes`, camiseta negra | Invitar a Tiaguito al freestyle de la estación | Cadena brillante |
| 10 | Emi | Emilia Mernes | La estrella pop de fama internacional | pelo `long` castaño claro, `headband` rosa, camiseta rosa | Encontrar su vincha con brillos, perdida cerca de la fuente | Vincha con brillos |
| 11 | El Biza | Bizarrap | El productor misterioso de las sesiones famosas | `cap` negra, `lentes`, camiseta negra | Preguntarle a Gille cuál es la nota secreta del barrio y volver a contársela | Lentes del productor |
| 12 | La Nena | María Becerra | La voz pop del país | pelo `long` celeste, camiseta celeste | Llevarle a Emi la propuesta de grabar un dueto | Micrófono rosa |
| 13 | El Luki | Luck Ra | El cuartetero del hit que todos cantan | pelo `curly` azul, camiseta azul con `stripes` | Invitar a 3 personajes al karaoke de cuarteto en la plaza | Entrada al baile |
| 14 | Román | Juan Román Riquelme | El ídolo eterno, ahora dirige el club | pelo `short` negro, camiseta azul con `badge` amarillo | Avisarle al Atajatodo que mañana hay práctica en el club | Camiseta azul y oro |

Notas de diseño:
- Las misiones forman **cadenas cortas entre personajes** (Don Salina → Gille,
  El Duko → Tiaguito, La Nena → Emi, Caby → Juli, Román → El Atajatodo, El Biza → Gille)
  para obligar a recorrer distintos puntos de la ciudad.
- El orden es **libre**, salvo la de Juli Noticias que pide progreso previo (funciona
  como checkpoint de mitad de juego: la nota sobre Monti sólo sale cuando el barrio
  ya lo conoce).
- La trompeta, la libreta de rimas, la pelota, los guantes y la vincha son **entidades
  buscables en el mapa**, dibujadas procedural (sin assets).
- La contrarreloj de Franquito requiere un **temporizador simple** visible (ver R8);
  si falla, la carrera se puede reintentar hablándole de nuevo.
- Todos los rasgos visuales usan el sistema data-driven actual. Extensiones **opcionales**
  para reforzar siluetas (no bloquean): guantes en manos (Atajatodo), colgante/cadena
  (El Duko), micrófono en mano (cantantes).

## 5. Alcance

**Incluye:**
- Protagonista con nombre: **Monti** (nameplate propio en diálogos si corresponde).
- Sistema de estado de misiones (no iniciada / en curso / completada) por NPC.
- Diálogo condicional según estado de misión (el NPC cambia lo que dice).
- Inventario/álbum del barrio: UI procedural que muestra los objetos coleccionados.
- Entidades buscables en el mapa según las misiones definidas.
- Secuencia de victoria al completar todos los objetos del roster (cierre en Plaza Mitre).
- Reemplazo incremental de los vecinos de prueba de `scenes/main.tscn` a medida que
  se definen personajes del roster.

**No incluye (out of scope — fase 2):**
- Entrar a edificios/Lugares y cumplir misiones adentro (ej: misión en el McDonald's).
- Elecciones ramificadas en el diálogo (choices).
- Horarios / ciclo día-noche.
- Guardado de progreso (lo cubre spec 0005; esta spec define QUÉ estado hay que guardar).

## 6. Requisitos

- R1. `GameManager` debe mantener flags de progreso por misión (estado + contadores,
  ej: volantes repartidos 2/3) consultables desde cualquier NPC.
- R2. Cada NPC debe soportar **líneas de diálogo condicionales** por estado de su misión
  (presentación → encargo → recordatorio → agradecimiento + entrega del objeto),
  editables como datos en el Inspector (misma filosofía data-driven que los rasgos).
- R3. El álbum del barrio debe ser accesible en cualquier momento (tecla/botón), mostrar
  un espacio por personaje definido (silueta si falta el objeto, dibujo si está) y
  renderizarse 100% procedural. La cantidad de espacios se deriva de los datos, no
  se hardcodea.
- R4. Las entidades buscables deben ubicarse en celdas caminables y ser interactuables
  con la misma tecla que los NPCs.
- R5. Al obtener el último objeto del roster definido debe dispararse la secuencia de
  victoria en Plaza Mitre.
- R6. Todo el texto de diálogo en rioplatense, coherente con la identidad de cada
  personaje (el músico habla de música, el piloto de velocidad, etc.).
- R7. **Personajes como homenaje/parodia**: nombres de guiño, nunca el nombre real
  completo de la figura, sin afirmaciones sobre la persona real ni uso de su imagen
  (mitigación de derecho a la imagen, art. 53 CCyC). El juego incluye un descargo
  ("personajes ficticios inspirados con cariño en ídolos populares").
- R8. La misión contrarreloj de Franquito requiere un temporizador simple visible
  durante la carrera, reintentable sin penalidad.

## 7. Criterios de aceptación (verificables)

- [ ] CA1. Dado un juego nuevo, cuando Monti habla con un NPC por primera vez, entonces
  el NPC se presenta y le encarga su misión (estado pasa a "en curso").
- [ ] CA2. Dado una misión en curso, cuando el jugador vuelve a hablar con el NPC sin
  cumplirla, entonces recibe una línea de recordatorio (no se repite la presentación).
- [ ] CA3. Dado el requisito de una misión cumplido, cuando el jugador habla con el NPC,
  entonces recibe el objeto icónico y el álbum lo refleja.
- [ ] CA4. Dado el álbum abierto, entonces se ve un espacio por personaje definido con
  silueta/objeto y un contador (ej: 7/N).
- [ ] CA5. Dado todos los objetos del roster coleccionados, entonces se reproduce la
  secuencia de victoria en Plaza Mitre y el juego marca el final.
- [ ] CA6. La misión de Juli Noticias sólo se habilita con 5 misiones completadas.
- [ ] CA7. Corre en web (GL Compatibility) sin errores.

## 8. Restricciones (de la constitución)

- Paleta / 160×144 / GL Compatibility / GDScript / grid-based.
- Objetos del álbum y entidades buscables dibujados por código. ✔ no requiere ADR.

## 9. Preguntas abiertas

- ¿El álbum muestra una frase de recuerdo por objeto (mini enciclopedia del barrio)?
- ¿La secuencia de victoria reúne físicamente a los 15 NPCs en la plaza (depende de
  spec 0009) o es una pantalla dedicada?
- ¿Algunos vecinos de prueba actuales quedan como NPCs ambientales sin misión
  (para que la ciudad no quede poblada sólo por famosos)?
