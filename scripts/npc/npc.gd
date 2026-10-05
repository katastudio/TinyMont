@tool
extends StaticBody2D
## Un personaje editable 100% en el editor de Godot.
## Seleccioná el nodo y editá sus rasgos en el Inspector (grupo "Aspecto"):
## menús para gorra/pelo/vello facial/marca/accesorio, checkbox de lentes y
## selectores de color. El sprite se actualiza EN VIVO en el editor.

const CharacterArt = preload("res://scripts/art/character_art.gd")

# Estados y rutinas
enum Rutina { QUIETO, DEAMBULAR, PATRULLAR, CEREBRO }
enum Estado { ESPERANDO, ELEGIR_DESTINO, CAMINANDO, EN_ACTIVIDAD }

@export var npc_name: String = "Vecino"
@export var dialog_lines: Array = ["¡Hola!"]

@export_group("Aspecto")
@export var piel: Color = Color("f4c29a")
@export_enum("short", "curly", "long", "slick", "bald") var pelo: String = "short"
@export var pelo_color: Color = Color("3a2a1a")
@export_enum("none", "cap", "fedora", "beanie", "headband") var gorra: String = "none"
@export var gorra_color: Color = Color("e03020")
@export_enum("none", "mustache", "beard", "stubble") var vello_facial: String = "none"
@export var lentes: bool = false
@export var camiseta: Color = Color("2f56d8")
@export_enum("none", "stripes", "badge") var marca: String = "none"
@export var marca_color: Color = Color("fcfcfc")
@export var pantalon: Color = Color("394a86")
@export_enum("none", "backpack") var accesorio: String = "none"

@export_group("Animación")
@export var respira: bool = true
@export var respira_amplitud: float = 1.0
@export var respira_velocidad: float = 2.0
@export var parpadea: bool = true
@export var parpadeo_cada: float = 4.0

# Misión data-driven. Un mismo NPC puede ser el que ENCARGA (giver) o un
# AYUDANTE (helper) que entrega un objeto. Si mision_id está vacío, es ambiental.
@export_group("Misión")
@export var mision_id: String = ""                 # vacío = NPC ambiental (solo dialog_lines)
@export var dialog_encargo: Array = []             # giver: al encargar (no_iniciada -> en_curso)
@export var dialog_recordatorio: Array = []        # misión en curso, aún sin cumplir
@export var dialog_entrega: Array = []             # giver: al cumplir; helper: al dar el objeto
@export var requisito_item: String = ""            # giver: objeto que pide para completar
@export var recompensa_item: String = ""           # giver: objeto que regala al completar
@export var otorga_item: String = ""               # helper: objeto que entrega durante la misión
## Requisitos opcionales del giver (spec 0008): progreso previo, contador o contrarreloj.
@export var requiere_completadas: int = 0          # misiones completadas necesarias para encargar
@export var dialog_bloqueada: Array = []           # qué dice si todavía no alcanza el progreso
@export var requisito_contador: int = 0            # vecinos distintos con los que hay que hablar
@export var linea_contacto: String = ""            # lo que dice cada vecino contactado (ej: invitación)
@export var limite_segundos: float = 0.0           # >0: contrarreloj (segundos reales, pausa en diálogos)
## Roles de ayudante en misiones ajenas: [{mision, item, lineas, recordatorio}].
@export var ayudas: Array = []

@export_group("Rutina")
@export var rutina: Rutina = Rutina.QUIETO
@export var radio_deambular: int = 3               # radio en tiles (Chebyshev) para DEAMBULAR
@export var waypoints: Array[Vector2i] = []        # celdas para PATRULLAR
@export var velocidad: float = 32.0                # px/s
@export var pausa_min: float = 1.0
@export var pausa_max: float = 3.0

@export_group("Cerebro")
@export var ficha_id: String = ""                  # vacío = derivado de npc_name (data/personajes/<id>.json)

# Variables de estado (solo en runtime)
var facing := Vector2.DOWN
var _t := 0.0
var _mundo = null  # Will be set to parent (must have ocupacion/camino/es_transitable_estatica methods)
var _rng: RandomNumberGenerator = null
var _estado: Estado = Estado.ESPERANDO
var _timer_pausa: float = 0.0
var _camino: Array[Vector2i] = []
var _indice_camino: int = 0
var _indice_waypoint: int = 0
var _celda_actual: Vector2i = Vector2i.ZERO
var _celda_spawn: Vector2i = Vector2i.ZERO
var _en_dialogo: bool = false
var _fallos_consecutivos: int = 0
var _pos_interlocutor := Vector2.ZERO
var _paso_activo: bool = false          # true mientras se desplaza hacia _celda_paso
var _celda_paso: Vector2i = Vector2i.ZERO
var _timer_bloqueo: float = 0.0          # espera tras encontrar la próxima celda ocupada
const ESPERA_BLOQUEO := 0.4              # segundos entre reintentos si la celda está ocupada
const MAX_FALLOS := 3

# Estado del cerebro (Rutina.CEREBRO, spec 0010)
var _cerebro: CerebroNPC = null
var _ficha: Dictionary = {}
var _opcion_actual: Dictionary = {}      # opción elegida (POI o lugar propio) hacia la que va o en la que está
var _minutos_actividad: int = 0          # minutos de juego restantes de la actividad en curso
var historial_pois: Array[String] = []   # ids de POIs donde completó una actividad (tests y depuración)

# Gestos puntuales (roadmap C8): nombre -> duración en segundos
const GESTOS := {"saltito": 0.5, "saludo": 1.0}
const ALTURA_SALTITO := 4.0
var _gesto: String = ""
var _t_gesto: float = 0.0

# Fiesta final en la plaza (spec 0008 R5)
const SIN_CONVOCATORIA := Vector2i(-1, -1)
var _convocatoria: Vector2i = SIN_CONVOCATORIA

# Vida social (spec 0010, F3)
const UMBRAL_SOCIAL := 20.0              # urgencia social mínima para buscar charla
const ALIVIO_CHARLA := 40.0              # cuánto baja la urgencia social una charla
var memoria: MemoriaNPC = null
var _minutos_charla: int = 0             # minutos de juego que le quedan a la charla en curso
var _interlocutor: Node2D = null


func _anim_cfg() -> Dictionary:
	return {
		respira = respira, respira_amp = respira_amplitud, respira_vel = respira_velocidad,
		parpadea = parpadea, parpadeo_cada = parpadeo_cada,
	}


## Descriptor para el retrato del cuadro de diálogo.
func retrato() -> Dictionary:
	return _descriptor()


func _descriptor() -> Dictionary:
	return {
		skin = piel, hair = pelo_color, hair_style = pelo,
		hat = gorra, hat_col = gorra_color,
		facial = vello_facial, glasses = lentes,
		shirt = camiseta, pants = pantalon,
		mark = marca, mark_col = marca_color, accessory = accesorio,
	}


func _ready():
	if Engine.is_editor_hint():
		return

	_mundo = get_parent()
	_celda_actual = _get_celda()
	_celda_spawn = _celda_actual

	# RNG determinística: semilla + índice del NPC
	if is_instance_valid(_mundo) and "semilla" in _mundo:
		_rng = RandomNumberGenerator.new()
		_rng.seed = _mundo.semilla + get_index()

	# Registrar en la grilla de ocupación
	if is_instance_valid(_mundo) and "ocupacion" in _mundo:
		_mundo.ocupacion.reservar(_celda_actual, self)

	# Conectar a señales de diálogo
	if not GameManager.dialog_ended.is_connected(_on_dialog_ended):
		GameManager.dialog_ended.connect(_on_dialog_ended)
	if not GameManager.encounter_ended.is_connected(_on_encounter_ended):
		GameManager.encounter_ended.connect(_on_encounter_ended)

	if rutina == Rutina.CEREBRO:
		_cargar_ficha()
	if rutina == Rutina.CEREBRO and not WorldClock.tick.is_connected(_on_world_clock_tick):
		WorldClock.tick.connect(_on_world_clock_tick)


func _process(delta):
	# Avanza la animación (respiración/parpadeo). Corre también en el editor (@tool).
	_t += delta
	if _gesto != "":
		_t_gesto += delta
		if _t_gesto >= GESTOS[_gesto]:
			_gesto = ""

	# Movimiento: solo en runtime, si el mundo existe
	if not Engine.is_editor_hint() and is_instance_valid(_mundo):
		_actualizar_movimiento(delta)

	queue_redraw()


func _draw():
	var st = CharacterArt.anim_state(_t, _anim_cfg(), _paso_activo, float(get_index()) * 0.6)
	var alto := altura_gesto()
	CharacterArt.draw_on(self, CharacterArt.map_rects(_descriptor(), st), Vector2(-8, -10 - st.bob - alto), 1.0)
	if _gesto == "saludo":
		# Mano que saluda al costado de la cabeza, alternando de lado a lado.
		var vaiven := 1.0 if int(_t_gesto * 8.0) % 2 == 0 else 0.0
		draw_rect(Rect2(7 + vaiven, -13 - st.bob, 2, 3), piel)
	if _minutos_charla > 0:
		_dibujar_globo()


func _dibujar_globo() -> void:
	draw_rect(Rect2(-6, -31, 12, 8), Pal.WHITE)
	draw_rect(Rect2(-6, -31, 12, 8), Pal.BLACK, false, 1.0)
	draw_rect(Rect2(-1, -23, 2, 2), Pal.WHITE)
	var fase := int(_t * 3.0) % 3
	for i in 3:
		draw_rect(Rect2(-4 + i * 3, -28 if i == fase else -27, 2, 2), Pal.BLACK)


# ==================== MOVIMIENTO ====================

func _get_celda() -> Vector2i:
	"""Convierte la posición actual a celda."""
	var t = 16  # TILE_SIZE
	return Vector2i(int(global_position.x) / t, int(global_position.y) / t)


func _pos_de_celda(celda: Vector2i) -> Vector2:
	"""Convierte celda a posición de centro de tile."""
	var t = 16
	return Vector2(celda.x * t + t / 2.0, celda.y * t + t / 2.0)


func _actualizar_movimiento(delta: float) -> void:
	"""Máquina de estado de movimiento. Un paso en curso siempre se completa,
	aunque el NPC entre en diálogo, para no quedar entre dos celdas."""
	if _paso_activo:
		_continuar_paso(delta)
		return
	if _en_dialogo or _minutos_charla > 0 or rutina == Rutina.QUIETO:
		return

	match _estado:
		Estado.ESPERANDO:
			_timer_pausa -= delta
			if _timer_pausa <= 0:
				_estado = Estado.ELEGIR_DESTINO
				_fallos_consecutivos = 0

		Estado.ELEGIR_DESTINO:
			_elegir_destino()
			if _estado == Estado.EN_ACTIVIDAD:
				pass  # ya estaba en el lugar elegido
			elif not _camino.is_empty():
				_estado = Estado.CAMINANDO
				_indice_camino = 0
			else:
				_volver_a_esperar()

		Estado.CAMINANDO:
			_avanzar_en_camino(delta)


func _volver_a_esperar() -> void:
	_soltar_opcion()
	_estado = Estado.ESPERANDO
	_camino = []
	_fallos_consecutivos = 0
	_timer_pausa = _rng.randf_range(pausa_min, pausa_max) if _rng else 2.0


func _elegir_destino() -> void:
	"""Elige el próximo destino según la rutina (la convocatoria a la fiesta tiene prioridad)."""
	if convocado():
		_elegir_destino_convocado()
		return
	match rutina:
		Rutina.QUIETO:
			_camino = []

		Rutina.DEAMBULAR:
			_elegir_destino_deambular()

		Rutina.PATRULLAR:
			_elegir_destino_patrullar()

		Rutina.CEREBRO:
			_elegir_destino_cerebro()


func _elegir_destino_deambular() -> void:
	"""Elige una celda aleatoria dentro del radio."""
	var intentos = 0
	var max_intentos = 8

	while intentos < max_intentos:
		var dx = _rng.randi_range(-radio_deambular, radio_deambular) if _rng else randi_range(-radio_deambular, radio_deambular)
		var dy = _rng.randi_range(-radio_deambular, radio_deambular) if _rng else randi_range(-radio_deambular, radio_deambular)
		var destino = _celda_spawn + Vector2i(dx, dy)

		if _mundo.es_transitable_estatica(destino) and _mundo.ocupacion.esta_libre(destino):
			_camino = _mundo.camino(_celda_actual, destino)
			return

		intentos += 1

	_camino = []


func _elegir_destino_patrullar() -> void:
	"""Elige el siguiente waypoint en el ciclo."""
	if waypoints.is_empty():
		_camino = []
		return

	var destino = waypoints[_indice_waypoint] as Vector2i
	_indice_waypoint = (_indice_waypoint + 1) % waypoints.size()

	_camino = _mundo.camino(_celda_actual, destino)


func _avanzar_en_camino(delta: float) -> void:
	"""Inicia el próximo paso del camino. La celda destino se reserva antes de
	moverse y la celda de origen se libera recién al llegar (ver _continuar_paso),
	así el NPC ocupa ambas celdas mientras está entre ellas."""
	if _indice_camino >= _camino.size():
		_volver_a_esperar()
		return

	if _timer_bloqueo > 0.0:
		_timer_bloqueo -= delta
		return

	var siguiente: Vector2i = _camino[_indice_camino]
	if not _mundo.ocupacion.reservar(siguiente, self):
		_fallos_consecutivos += 1
		_timer_bloqueo = ESPERA_BLOQUEO
		if _fallos_consecutivos >= MAX_FALLOS:
			_volver_a_esperar()
		elif _fallos_consecutivos == 1:
			# Algo quieto tapa el paso: recalcular el camino esquivando las celdas ocupadas.
			var rodeo: Array[Vector2i] = _mundo.camino(_celda_actual, _camino.back(), true)
			if rutina == Rutina.DEAMBULAR and rodeo.any(func(c): return maxi(absi(c.x - _celda_spawn.x), absi(c.y - _celda_spawn.y)) > radio_deambular):
				rodeo = []   # quien deambula no sale de su radio, ni para rodear
			if not rodeo.is_empty():
				_camino = rodeo
				_indice_camino = 0
		return

	_fallos_consecutivos = 0
	_indice_camino += 1
	_celda_paso = siguiente
	_paso_activo = true

	var dir := siguiente - _celda_actual
	if dir.x > 0:
		facing = Vector2.RIGHT
	elif dir.x < 0:
		facing = Vector2.LEFT
	elif dir.y > 0:
		facing = Vector2.DOWN
	elif dir.y < 0:
		facing = Vector2.UP


func _continuar_paso(delta: float) -> void:
	"""Desplaza al NPC hacia _celda_paso; al llegar libera la celda de origen."""
	var objetivo := _pos_de_celda(_celda_paso)
	global_position = global_position.move_toward(objetivo, velocidad * delta)
	if global_position.distance_to(objetivo) < 0.5:
		global_position = objetivo
		_mundo.ocupacion.liberar(_celda_actual, self)
		_celda_actual = _celda_paso
		_paso_activo = false
		if _en_dialogo:
			_mirar(_pos_interlocutor)

		if rutina == Rutina.CEREBRO and not _opcion_actual.is_empty() and _indice_camino >= _camino.size():
			_comenzar_actividad()


func _on_dialog_ended() -> void:
	"""Llamado cuando termina un diálogo."""
	_en_dialogo = false


func _on_encounter_ended() -> void:
	"""Llamado cuando termina un encuentro."""
	_en_dialogo = false


# ==================== INTERACCIÓN ====================

## Dispara un gesto puntual ("saltito" o "saludo"); los desconocidos se ignoran.
func gesto(nombre: String) -> void:
	if not GESTOS.has(nombre):
		return
	_gesto = nombre
	_t_gesto = 0.0
	queue_redraw()


func gesto_actual() -> String:
	return _gesto


## Altura actual del cuerpo por el gesto (el saltito es una parábola de ALTURA_SALTITO px).
func altura_gesto() -> float:
	if _gesto != "saltito":
		return 0.0
	return sin(PI * clampf(_t_gesto / GESTOS["saltito"], 0.0, 1.0)) * ALTURA_SALTITO


func interact(player_pos: Vector2):
	gesto("saludo")
	_en_dialogo = true
	_mirar(player_pos)
	_pos_interlocutor = player_pos
	GameManager.start_encounter(self)


# ==================== CEREBRO (spec 0010) ====================

## Id de ficha: el exportado o uno derivado del nombre ("Doña Rosa" -> "dona_rosa").
func id_ficha() -> String:
	if not ficha_id.is_empty():
		return ficha_id
	var id := npc_name.to_lower().strip_edges()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"], [" ", "_"]]:
		id = id.replace(par[0], par[1])
	return id


func _cargar_ficha() -> void:
	var ruta := "res://data/personajes/%s.json" % id_ficha()
	var datos = null
	if FileAccess.file_exists(ruta):
		datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not (datos is Dictionary):
		push_warning("Sin ficha válida para %s (%s): usa DEAMBULAR" % [npc_name, ruta])
		rutina = Rutina.DEAMBULAR
		radio_deambular = 2
		return
	_ficha = datos
	_cerebro = CerebroNPC.new()
	var semilla_mundo: int = _mundo.semilla if is_instance_valid(_mundo) and "semilla" in _mundo else 0
	var r := RandomNumberGenerator.new()
	r.seed = hash(id_ficha()) ^ semilla_mundo
	_cerebro.rng = r
	_cerebro.cargar_ficha(_ficha)
	memoria = MemoriaNPC.new()
	memoria.sembrar(_ficha.get("rumores_semilla", []), WorldClock.minutos, npc_name)


## Opciones disponibles: los POIs del mundo más el lugar propio (la celda de origen del NPC).
func _opciones() -> Array:
	var opciones: Array = []
	if is_instance_valid(_mundo) and "pois" in _mundo:
		for poi in _mundo.pois:
			opciones.append(poi.como_opcion())
	var propio: Dictionary = _ficha.get("lugar_propio", {})
	opciones.append({
		"id": "propio",
		"satisface": propio.get("satisface", {"energia": 70}),
		"celda": _celda_spawn,
		"desde": 0,
		"hasta": 24,
		"duracion": int(propio.get("duracion", 60)),
		"lleno": false,
	})
	return opciones


func _elegir_destino_cerebro() -> void:
	_camino = []
	if _cerebro == null:
		return
	var contexto := {"hora": WorldClock.hora(), "dia_semana": WorldClock.dia_semana(), "celda": _celda_actual}
	var opcion := _cerebro.elegir(_opciones(), contexto)
	if opcion.is_empty():
		return
	var destino := _celda_libre_cerca(opcion["celda"])
	if destino == Vector2i(-1, -1):
		return
	_opcion_actual = opcion
	var nodo = opcion.get("nodo")
	if nodo:
		nodo.entrar(self)
	if destino == _celda_actual:
		_comenzar_actividad()
		return
	_camino = _mundo.camino(_celda_actual, destino)
	if _camino.is_empty():
		_soltar_opcion()


## La celda pedida si está libre (o es la propia); si no, la libre más cercana a distancia <= radio_max.
func _celda_libre_cerca(celda: Vector2i, radio_max: int = 2) -> Vector2i:
	for radio in range(radio_max + 1):
		for dy in range(-radio, radio + 1):
			for dx in range(-radio, radio + 1):
				if absi(dx) + absi(dy) != radio:
					continue
				var c := celda + Vector2i(dx, dy)
				if not _mundo.es_transitable_estatica(c):
					continue
				if c == _celda_actual or _mundo.ocupacion.esta_libre(c):
					return c
	return Vector2i(-1, -1)


func _comenzar_actividad() -> void:
	_estado = Estado.EN_ACTIVIDAD
	_camino = []
	_minutos_actividad = maxi(1, int(_opcion_actual.get("duracion", 30)))


func _terminar_actividad() -> void:
	if _cerebro and not _opcion_actual.is_empty():
		_cerebro.aplicar(_opcion_actual)
		historial_pois.append(str(_opcion_actual.get("id", "")))
	_volver_a_esperar()


func _soltar_opcion() -> void:
	var nodo = _opcion_actual.get("nodo")
	if nodo and is_instance_valid(nodo):
		nodo.salir(self)
	_opcion_actual = {}


func _on_world_clock_tick(minutos: int) -> void:
	if _cerebro == null:
		return
	_cerebro.actualizar(minutos)
	if _minutos_charla > 0:
		_minutos_charla -= minutos
		if _minutos_charla <= 0:
			_interlocutor = null
	if memoria:
		memoria.olvidar_viejos(WorldClock.minutos)
	if _estado == Estado.EN_ACTIVIDAD:
		_minutos_actividad -= minutos
		if _minutos_actividad <= 0:
			_terminar_actividad()


## Texto de depuración: actividad o destino actual.
func actividad_actual() -> String:
	return str(_opcion_actual.get("id", "")) if not _opcion_actual.is_empty() else ""


## true si el NPC puede atender una charla (no está hablando con el jugador ni con otro).
## Puede estar caminando: termina el paso en curso y se frena.
func disponible_para_charlar() -> bool:
	return _cerebro != null and memoria != null and not _en_dialogo and _minutos_charla <= 0


## true si además tiene ganas de charlar (urgencia social sobre el umbral).
func quiere_charlar() -> bool:
	return disponible_para_charlar() and _cerebro.necesidades["social"] >= UMBRAL_SOCIAL


func celda_logica() -> Vector2i:
	return _celda_actual


## Lo llama el mundo al juntar a dos vecinos: se frena, lo mira y se le alivia lo social.
func iniciar_charla(otro: Node2D, minutos: int) -> void:
	_minutos_charla = minutos
	_interlocutor = otro
	gesto("saludo")
	_mirar(otro.global_position)
	_cerebro.necesidades["social"] = maxf(0.0, _cerebro.necesidades["social"] - ALIVIO_CHARLA)
	queue_redraw()


func charlando() -> bool:
	return _minutos_charla > 0


## Suma una charla con el jugador y devuelve la relación que tenían antes.
func _registrar_charla_jugador() -> int:
	if memoria == null:
		return 0
	var previa := memoria.relacion_con("jugador")
	memoria.ajustar_relacion("jugador", 1)
	if memoria.relacion_con("jugador") >= GameManager.AMIGO_DESDE:
		GameManager.registrar_amigo(npc_name)
	if WorldClock.hora() >= 5 and WorldClock.hora() < 7:
		GameManager.desbloquear_logro("madrugador")
	return previa


const UMBRAL_HUMOR := 70.0       # urgencia a partir de la cual una necesidad marca el ánimo
const UMBRAL_CONTENTO := 35.0    # todas las necesidades por debajo: contento
const HUMOR_POR_NECESIDAD := [["hambre", "hambriento"], ["energia", "cansado"], ["ocio", "aburrido"], ["social", "solo"]]


## Convoca al vecino a un punto (la fiesta final): deja lo que hace y va para allá.
func convocar(celda: Vector2i) -> void:
	_convocatoria = celda
	if not _paso_activo:
		_volver_a_esperar()
		_timer_pausa = 0.0


func convocado() -> bool:
	return _convocatoria != SIN_CONVOCATORIA


func liberar_convocatoria() -> void:
	_convocatoria = SIN_CONVOCATORIA
	if _estado == Estado.EN_ACTIVIDAD and actividad_actual() == "fiesta":
		_volver_a_esperar()


func _elegir_destino_convocado() -> void:
	_camino = []
	var destino := _celda_libre_cerca(_convocatoria, 6)
	if destino == Vector2i(-1, -1):
		return
	_opcion_actual = {"id": "fiesta", "satisface": {"social": 100}, "celda": destino, "duracion": 600, "lleno": false}
	if destino == _celda_actual:
		_comenzar_actividad()
		return
	_camino = _mundo.camino(_celda_actual, destino)
	if _camino.is_empty():
		_soltar_opcion()


## Ánimo actual según las necesidades: hambriento, cansado, aburrido, solo, contento o "".
func humor() -> String:
	if _cerebro == null:
		return ""
	var nec: Dictionary = _cerebro.necesidades
	for par in HUMOR_POR_NECESIDAD:
		if nec.get(par[0], 0.0) >= UMBRAL_HUMOR:
			return par[1]
	for n in nec:
		if nec[n] >= UMBRAL_CONTENTO:
			return ""
	return "contento"


## Una línea de la ficha para el ánimo actual; rota según cuántas veces hablaron.
func _linea_de_humor(relacion: int) -> String:
	var h := humor()
	if h == "":
		return ""
	var opciones: Array = _ficha.get("dialogos_por_humor", {}).get(h, [])
	if opciones.is_empty():
		return ""
	return str(opciones[relacion % opciones.size()])


## Envuelve las líneas ambientales con saludo según relación, hambre y el último chisme.
func _ambiente(base: Array, relacion: int) -> Array:
	if memoria == null:
		return base
	var lineas: Array = []
	if relacion >= 5:
		lineas.append("¡Otra vez por acá! Ya sos del barrio, %s." % GameManager.jugador_nombre)
	elif relacion >= 2:
		lineas.append("¡Hola de nuevo, %s!" % GameManager.jugador_nombre)
	lineas.append_array(base)
	var linea_humor := _linea_de_humor(relacion)
	if linea_humor != "":
		lineas.append(linea_humor)
	var rumor := memoria.ultimo_rumor_ajeno()
	if not rumor.is_empty():
		lineas.append("¿Te enteraste? %s" % rumor.texto)
		GameManager.registrar_rumor_escuchado(rumor.texto)
	return lineas


# ==================== GUARDADO (spec 0010, F4) ====================

static func _v2i(v: Vector2i) -> Array:
	return [v.x, v.y]


static func _a_v2i(a) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


## Estado completo del NPC para el guardado. Los estados de RNG van como texto
## porque JSON no preserva enteros de 64 bits.
func a_dict() -> Dictionary:
	var camino: Array = []
	for c in _camino:
		camino.append(_v2i(c))
	return {
		"celda": _v2i(_celda_actual),
		"pos": [global_position.x, global_position.y],
		"facing": [facing.x, facing.y],
		"estado": int(_estado),
		"timer_pausa": _timer_pausa,
		"timer_bloqueo": _timer_bloqueo,
		"fallos": _fallos_consecutivos,
		"paso_activo": _paso_activo,
		"celda_paso": _v2i(_celda_paso),
		"camino": camino,
		"indice_camino": _indice_camino,
		"indice_waypoint": _indice_waypoint,
		"opcion": str(_opcion_actual.get("id", "")),
		"minutos_actividad": _minutos_actividad,
		"minutos_charla": _minutos_charla,
		"historial": historial_pois.duplicate(),
		"rng": str(_rng.state) if _rng else "",
		"cerebro_rng": str(_cerebro.rng.state) if _cerebro and _cerebro.rng else "",
		"necesidades": _cerebro.necesidades.duplicate() if _cerebro else {},
		"memoria": memoria.a_dict() if memoria else {},
	}


## Libera las celdas que ocupa (paso previo a restaurar a todos los NPCs).
func soltar_celdas() -> void:
	_soltar_opcion()
	for c in _mundo.ocupacion.celdas_de(self):
		_mundo.ocupacion.liberar(c, self)


## Restaura el estado guardado. El mundo llama antes a soltar_celdas() en todos los NPCs.
func restaurar(d: Dictionary) -> void:
	_celda_actual = _a_v2i(d.celda)
	global_position = Vector2(float(d.pos[0]), float(d.pos[1]))
	facing = Vector2(float(d.facing[0]), float(d.facing[1]))
	_estado = int(d.estado) as Estado
	_timer_pausa = float(d.timer_pausa)
	_timer_bloqueo = float(d.timer_bloqueo)
	_fallos_consecutivos = int(d.fallos)
	_paso_activo = bool(d.paso_activo)
	_celda_paso = _a_v2i(d.celda_paso)
	_camino.clear()
	for c in d.camino:
		_camino.append(_a_v2i(c))
	_indice_camino = int(d.indice_camino)
	_indice_waypoint = int(d.indice_waypoint)
	_minutos_actividad = int(d.minutos_actividad)
	_minutos_charla = int(d.minutos_charla)
	_interlocutor = null
	_en_dialogo = false
	historial_pois.clear()
	for h in d.historial:
		historial_pois.append(str(h))
	if _rng and str(d.rng) != "":
		_rng.state = int(str(d.rng))
	if _cerebro:
		if _cerebro.rng and str(d.cerebro_rng) != "":
			_cerebro.rng.state = int(str(d.cerebro_rng))
		for n in d.necesidades:
			_cerebro.necesidades[n] = float(d.necesidades[n])
	if memoria and d.memoria is Dictionary and not d.memoria.is_empty():
		memoria = MemoriaNPC.desde_dict(d.memoria)
	_mundo.ocupacion.reservar(_celda_actual, self)
	if _paso_activo:
		_mundo.ocupacion.reservar(_celda_paso, self)
	_opcion_actual = {}
	var id := str(d.opcion)
	if id != "":
		for op in _opciones():
			if op.id == id:
				_opcion_actual = op
				if op.get("nodo"):
					op.nodo.entrar(self)
				break
	queue_redraw()


# Máquina de misión: aplica los efectos (items/estados) y devuelve las líneas
# a decir. La usa la pantalla de encuentro (opción HABLAR).
func dialogo_lines() -> Array:
	var relacion := _registrar_charla_jugador()
	# Misiones de contador ajenas: este vecino cuenta como contactado (ej: recibe una invitación).
	var extra: Array = GameManager.registrar_contacto(npc_name)
	return _lineas_de_mision(relacion) + extra


func _lineas_de_mision(relacion: int) -> Array:
	# Roles de ayudante en misiones ajenas: entrega el recado una vez mientras siga en curso.
	for ay in ayudas:
		var item := str(ay.get("item", ""))
		if GameManager.get_estado_mision(str(ay.get("mision", ""))) == "en_curso" and item != "" \
				and not GameManager.tiene_item(item):
			GameManager.agregar_item(item)
			return Array(ay.get("lineas", []))

	# NPC ambiental (sin misión propia): diálogo simple con lo que pasa en el barrio.
	if mision_id == "":
		for ay in ayudas:
			if GameManager.tiene_item(str(ay.get("item", ""))) and not Array(ay.get("recordatorio", [])).is_empty():
				return Array(ay.recordatorio)
		return _ambiente(dialog_lines, relacion)

	var estado := GameManager.get_estado_mision(mision_id)

	# AYUDANTE clásico: entrega su objeto mientras la misión está en curso (ej: Sandra da los vasitos).
	if otorga_item != "":
		if estado == "en_curso" and not GameManager.tiene_item(otorga_item):
			GameManager.agregar_item(otorga_item)
			return _lineas(dialog_entrega)
		elif estado == "en_curso":
			return _lineas(dialog_recordatorio)   # ya lo tenés, llevalo
		return _ambiente(dialog_lines, relacion)  # ambiental (antes/después de la misión)

	# GIVER: encarga, recuerda y completa la misión (ej: Marcos).
	match estado:
		"no_iniciada":
			if GameManager.misiones_completadas() < requiere_completadas:
				return _lineas(dialog_bloqueada)
			GameManager.set_estado_mision(mision_id, "en_curso")
			if requisito_contador > 0:
				GameManager.iniciar_contador(mision_id, npc_name, requisito_contador, linea_contacto)
			if limite_segundos > 0.0:
				GameManager.iniciar_cuenta(mision_id, limite_segundos, requisito_item)
			if _sin_requisitos():
				_completar_mision()
				return _lineas(dialog_encargo) + dialog_entrega
			return _lineas(dialog_encargo)
		"en_curso":
			if _requisito_cumplido():
				_completar_mision()
				return _lineas(dialog_entrega)
			return _lineas(dialog_recordatorio)
	return _ambiente(dialog_lines, relacion)      # misión completada: charla post-misión


func _sin_requisitos() -> bool:
	return requisito_item == "" and requisito_contador <= 0


func _requisito_cumplido() -> bool:
	if requisito_item != "" and not GameManager.tiene_item(requisito_item):
		return false
	if requisito_contador > 0 and GameManager.contador_de(mision_id) < requisito_contador:
		return false
	return true


## Cierra la misión: consume el requisito, da la recompensa y se vuelve noticia del barrio.
func _completar_mision() -> void:
	if requisito_item != "":
		GameManager.quitar_item(requisito_item)
	GameManager.set_estado_mision(mision_id, "completada")
	if recompensa_item != "":
		GameManager.agregar_item(recompensa_item)
	gesto("saltito")
	if limite_segundos > 0.0:
		GameManager.desbloquear_logro("contra_reloj")
	if memoria:
		memoria.sembrar(["%s le dio una mano a %s." % [GameManager.jugador_nombre, npc_name]], WorldClock.minutos, npc_name)


func _mirar(player_pos: Vector2) -> void:
	var dir = (player_pos - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		facing = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if dir.y > 0 else Vector2.UP


func _lineas(l: Array) -> Array:
	return l if not l.is_empty() else dialog_lines
