extends Node

signal dialog_started
signal dialog_ended
signal inventario_cambiado
signal mision_cambiada
signal encounter_ended

var is_dialog_active: bool = false
var dialog_box = null

var album_abierto: bool = false        # el álbum del barrio frena al player
var flags: Dictionary = {}              # progreso de la historia (ej: intro_vista), se guarda
var final: CanvasLayer = null           # pantalla final (spec 0008 R5)
var mapa_secundario: Node = null        # interior o barrio cargado encima del mapa principal
var transicion_inmediata: bool = false  # tests: sin fundido
var forzar_fundido: bool = false        # tests: fundido real aunque sea headless
var _vereda_retorno := Vector2i.ZERO    # celda del barrio donde reaparece Monti al volver
var _fundido: CanvasLayer = null
var en_transicion: bool = false         # una sola transición de mapa a la vez
signal victoria_lograda
signal logro_desbloqueado(id: String)

# --- Logros ---
const LOGROS := {
	"primer_encargo": {"nombre": "Primer encargo", "desc": "Completá una misión."},
	"medio_album": {"nombre": "Medio álbum", "desc": "Completá 10 misiones."},
	"vecino_de_ley": {"nombre": "Vecino de ley", "desc": "Completá el álbum del barrio."},
	"chismoso": {"nombre": "Chismoso del barrio", "desc": "Escuchá 5 rumores distintos."},
	"querido": {"nombre": "Querido por todos", "desc": "Hacete amigo de 3 vecinos."},
	"ciclista": {"nombre": "Ciclista", "desc": "Recorré 100 cuadras en bici."},
	"explorador": {"nombre": "Explorador", "desc": "Pasá por 15 lugares del barrio."},
	"noctambulo": {"nombre": "Noctámbulo", "desc": "Andá por el barrio a las 2 de la mañana."},
	"madrugador": {"nombre": "Madrugador", "desc": "Hablá con alguien antes de las 7."},
	"contra_reloj": {"nombre": "Contra reloj", "desc": "Ganá una carrera contra el tiempo."},
}
const AMIGO_DESDE := 5          # relación con el jugador para contar como amigo
var logros: Dictionary = {}     # id -> true
var progreso_logros: Dictionary = {"rumores": [], "amigos": [], "pedaleo": 0, "visitas": []}
signal final_cerrado
var album: CanvasLayer = null
var is_encounter_active: bool = false   # pantalla de encuentro abierta (frena al player)
var _encounter: CanvasLayer = null

# --- Estado del jugador / progreso ---
var jugador_nombre: String = "Monti"
var inventario: Array = []          # ids de objetos que Monti lleva en la mochila
var misiones: Dictionary = {}       # mision_id -> "no_iniciada" | "en_curso" | "completada"

var en_bici: bool = false           # Monti va montado en la bici (velocidad x1.7)
var bici_color: Color = Color("d83030")  # color de la bici que tomó (para dibujarla montado)


# --- Guardado (spec 0005 + spec 0010 F4) ---
const VERSION_GUARDADO := 1
var ruta_guardado: String = "user://partida.json"
var cargar_al_iniciar: bool = false   # el título pide continuar: el mundo carga la partida al iniciar
var mundo_activo: Node = null         # MonteGrande en juego (lo registra en su _ready)
var objetos_tomados: Array = []       # nombres de nodos Objeto que el jugador ya levantó

var _hud: CanvasLayer = null
var _touch: CanvasLayer = null


func _ready():
	WorldClock.hora_cambiada.connect(_on_hora_logros)
	WorldClock.tick.connect(_on_tick_autoguardado)
	inventario_cambiado.connect(autoguardar)
	logro_desbloqueado.connect(func(_id): autoguardar())
	_escuchar_pagina_web()
	_setup_input()
	_adaptar_pantalla()
	_add_hud()
	_add_touch_controls()
	mostrar_ui_juego(false)   # el título arranca sin HUD ni controles


# El HUD y los controles solo se ven durante el juego (no en el título).
func mostrar_ui_juego(v: bool) -> void:
	if _hud:
		_hud.visible = v
	if _touch:
		_touch.visible = v


func _adaptar_pantalla() -> void:
	# Llenar la pantalla en todos lados (más mapa visible, personajes al mismo tamaño):
	# mobile/web-mobile a lo alto, web-desktop a lo ancho. Sin barras negras.
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


# Safe area (notch/cámara arriba, home-indicator abajo) como FRACCIÓN de la pantalla.
# Cada consumidor la multiplica por su propio alto lógico. En desktop = 0.
func safe_top_frac() -> float:
	if not DisplayServer.is_touchscreen_available():
		return 0.0
	var wh := DisplayServer.window_get_size().y
	return (DisplayServer.get_display_safe_area().position.y / float(wh)) if wh > 0 else 0.0


func safe_bottom_frac() -> float:
	if not DisplayServer.is_touchscreen_available():
		return 0.0
	var wh := DisplayServer.window_get_size().y
	if wh <= 0:
		return 0.0
	var safe := DisplayServer.get_display_safe_area()
	return maxf(0.0, wh - (safe.position.y + safe.size.y)) / float(wh)


# Alto (px lógicos) que ocupan los controles flotantes desde el borde inferior,
# para que el diálogo se apoye encima sin taparlos. `view_h` = alto lógico actual.
# Sin pantalla táctil (desktop / web-desktop) no hay controles: margen mínimo.
const CONTROLS_H := 124.0
func bottom_reserve(view_h: float) -> float:
	if not DisplayServer.is_touchscreen_available():
		return 6.0
	return CONTROLS_H + safe_bottom_frac() * view_h


func _setup_input():
	_add_key_action("move_up", KEY_UP)
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_DOWN)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("interact", KEY_Z)
	_add_key_action("interact", KEY_ENTER)
	_add_key_action("interact", KEY_SPACE)
	_add_key_action("menu", KEY_X)
	_add_key_action("menu", KEY_ESCAPE)
	_add_key_action("album", KEY_TAB)


func _add_key_action(action_name: String, key: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	InputMap.action_add_event(action_name, event)


## `retrato`: descriptor de CharacterArt del que habla; vacío = sin retrato.
func start_dialog(speaker_name: String, lines: Array, color: Color = Color.WHITE, retrato: Dictionary = {}):
	is_dialog_active = true
	dialog_started.emit()
	if dialog_box:
		dialog_box.show_dialog(speaker_name, lines, color, retrato)


func end_dialog():
	is_dialog_active = false
	dialog_ended.emit()


# ==================== ENCUENTRO (pantalla estilo Pokémon) ====================
# Al interactuar con un NPC se abre la pantalla de encuentro (una sola
# instancia, hija del autoload como el HUD). El resto de los interactuables
# sigue con diálogo directo.

func start_encounter(npc) -> void:
	if _encounter == null:
		_encounter = preload("res://scenes/ui/encounter_screen.tscn").instantiate()
		add_child(_encounter)
	is_encounter_active = true
	_encounter.open(npc)


func end_encounter() -> void:
	is_encounter_active = false
	encounter_ended.emit()


# ==================== INVENTARIO (mochila) ====================

func agregar_item(item: String) -> void:
	inventario.append(item)
	inventario_cambiado.emit()
	MusicManager.play_sfx("campanita_objeto")


func quitar_item(item: String) -> bool:
	if item in inventario:
		inventario.erase(item)
		inventario_cambiado.emit()
		return true
	return false


func tiene_item(item: String) -> bool:
	return item in inventario


# ==================== MAPAS SECUNDARIOS (spec 0006, ADR-0005) ====================
# El mapa principal nunca se destruye: se oculta y sigue simulando (el barrio sigue vivo).

func ir_a_mapa(escena: String, vereda: Vector2i) -> void:
	# Con la flecha apretada contra la puerta, esto se llama en cada frame del fundido:
	# sólo la primera llamada transiciona (antes se cargaban varios interiores).
	if en_transicion or mapa_secundario != null or mundo_activo == null:
		return
	en_transicion = true
	_vereda_retorno = vereda
	autoguardar()
	await _fundir(true)
	var jugador = mundo_activo.get_node_or_null("Player")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_unhandled_input(false)
		jugador.get_node("Camera2D").enabled = false
	mundo_activo.visible = false
	mapa_secundario = load(escena).instantiate()
	mundo_activo.get_parent().add_child(mapa_secundario)
	await _fundir(false)
	en_transicion = false


func volver_al_barrio() -> void:
	# Mismo cuidado al salir: antes la segunda llamada encontraba el mapa ya liberado,
	# fallaba a mitad de camino y la pantalla quedaba en negro.
	if en_transicion or mapa_secundario == null:
		return
	en_transicion = true
	await _fundir(true)
	mapa_secundario.get_parent().remove_child(mapa_secundario)
	mapa_secundario.queue_free()
	mapa_secundario = null
	if mundo_activo:
		mundo_activo.visible = true
		var jugador = mundo_activo.get_node_or_null("Player")
		if jugador:
			jugador.colocar_en(_vereda_retorno)
			jugador.set_physics_process(true)
			jugador.set_process_unhandled_input(true)
			var cam: Camera2D = jugador.get_node("Camera2D")
			cam.enabled = true
			cam.make_current()
	await _fundir(false)
	en_transicion = false
	autoguardar()


func opacidad_fundido() -> float:
	return _fundido.get_child(0).color.a if _fundido else 0.0


## Fundido a negro entre mapas (en tests, inmediato).
func _fundir(a_negro: bool) -> void:
	if transicion_inmediata or (DisplayServer.get_name() == "headless" and not forzar_fundido):
		return
	if _fundido == null:
		_fundido = CanvasLayer.new()
		_fundido.layer = 20
		var r := ColorRect.new()
		r.color = Color(0, 0, 0, 0)
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fundido.add_child(r)
		add_child(_fundido)
	var rect: ColorRect = _fundido.get_child(0)
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 1.0 if a_negro else 0.0, 0.2)
	await tw.finished


# ==================== ÁLBUM DEL BARRIO ====================

func abrir_album() -> void:
	if album == null:
		album = CanvasLayer.new()
		album.set_script(preload("res://scripts/ui/album.gd"))
		add_child(album)
	album.visible = true
	album_abierto = true


func cerrar_album() -> void:
	if album:
		album.visible = false
	album_abierto = false


## X (menú) o Tab abren el álbum mientras se camina; dentro de diálogos o encuentros no.
func _unhandled_input(event: InputEvent) -> void:
	if album_abierto or is_dialog_active or is_encounter_active or mundo_activo == null:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("album"):
		abrir_album()
		get_viewport().set_input_as_handled()


# ==================== MISIONES ====================

func get_estado_mision(id: String) -> String:
	return misiones.get(id, "no_iniciada")


const TOTAL_MISIONES := 8   # respaldo si todavía no hay catálogo (ej: tests sin mundo)
var _victoria := false

# ==================== LOGROS ====================

func tiene_logro(id: String) -> bool:
	return logros.has(id)


func desbloquear_logro(id: String) -> void:
	if logros.has(id) or not LOGROS.has(id):
		return
	logros[id] = true
	logro_desbloqueado.emit(id)


func _revisar_logros_de_misiones() -> void:
	var n := misiones_completadas()
	if n >= 1:
		desbloquear_logro("primer_encargo")
	if n >= 10:
		desbloquear_logro("medio_album")
	if n >= total_misiones() and not catalogo.is_empty():
		desbloquear_logro("vecino_de_ley")


func registrar_rumor_escuchado(texto: String) -> void:
	var r: Array = progreso_logros.rumores
	if not (texto in r):
		r.append(texto)
	if r.size() >= 5:
		desbloquear_logro("chismoso")


func registrar_amigo(nombre: String) -> void:
	var a: Array = progreso_logros.amigos
	if not (nombre in a):
		a.append(nombre)
	if a.size() >= 3:
		desbloquear_logro("querido")


func registrar_pedaleo() -> void:
	progreso_logros.pedaleo = int(progreso_logros.pedaleo) + 1
	if progreso_logros.pedaleo >= 100:
		desbloquear_logro("ciclista")


func registrar_visita(poi_id: String) -> void:
	var v: Array = progreso_logros.visitas
	if not (poi_id in v):
		v.append(poi_id)
	if v.size() >= 15:
		desbloquear_logro("explorador")


func _on_hora_logros(hora: int) -> void:
	if hora == 2 and mundo_activo != null:
		desbloquear_logro("noctambulo")


## Catálogo de misiones del mundo: mision_id -> {giver, recompensa}. Lo carga MonteGrande
## desde los NPCs de la escena; el total y el álbum se derivan de acá (spec 0008 R3).
var catalogo: Dictionary = {}
## Misiones de contador en curso: mision_id -> {giver, objetivo, linea, contactos: [nombres]}
var contadores: Dictionary = {}
## Misiones contrarreloj en curso: mision_id -> {restante: segundos, item: recado que se pierde}
var cuentas: Dictionary = {}

signal cuenta_vencida(mision_id: String)


func total_misiones() -> int:
	return catalogo.size() if not catalogo.is_empty() else TOTAL_MISIONES


## Registra una misión de contador al encargarse (ej: repartir 3 invitaciones).
func iniciar_contador(mision_id: String, giver: String, objetivo: int, linea: String) -> void:
	contadores[mision_id] = {"giver": giver, "objetivo": objetivo, "linea": linea, "contactos": []}


func contador_de(mision_id: String) -> int:
	return contadores.get(mision_id, {}).get("contactos", []).size()


## El jugador habló con `nombre`: suma en cada misión de contador en curso donde todavía no
## lo contó (salvo quien la encargó). Devuelve las líneas de agradecimiento a agregar.
func registrar_contacto(nombre: String) -> Array:
	var lineas: Array = []
	for id in contadores:
		var c: Dictionary = contadores[id]
		if get_estado_mision(id) != "en_curso" or c.giver == nombre or nombre in c.contactos:
			continue
		if c.contactos.size() >= int(c.objetivo):
			continue
		c.contactos.append(nombre)
		if str(c.linea) != "":
			lineas.append(str(c.linea))
	return lineas


## Arranca la cuenta regresiva de una misión contrarreloj (spec 0008 R8).
func iniciar_cuenta(mision_id: String, segundos: float, item_recado: String) -> void:
	cuentas[mision_id] = {"restante": segundos, "item": item_recado}


## Segundos que le quedan a la misión, o -1 si no tiene cuenta activa.
func tiempo_restante(mision_id: String) -> float:
	return float(cuentas[mision_id].restante) if cuentas.has(mision_id) else -1.0


func detener_cuenta(mision_id: String) -> void:
	cuentas.erase(mision_id)


## El tiempo de las contrarreloj sólo corre mientras el jugador puede moverse.
func _process(delta: float) -> void:
	if cuentas.is_empty() or is_dialog_active or is_encounter_active:
		return
	for id in cuentas.keys():
		cuentas[id].restante = float(cuentas[id].restante) - delta
		if cuentas[id].restante <= 0.0:
			_vencer_cuenta(id)


## Vencida: la misión vuelve a no iniciada y se pierde el objeto del recado (reintentable).
func _vencer_cuenta(mision_id: String) -> void:
	var item := str(cuentas[mision_id].item)
	cuentas.erase(mision_id)
	if item != "" and tiene_item(item):
		quitar_item(item)
	misiones[mision_id] = "no_iniciada"
	mision_cambiada.emit()
	cuenta_vencida.emit(mision_id)
	if dialog_box:
		start_dialog("Monti", ["¡Se acabó el tiempo!", "Puedo volver a intentarlo hablando de nuevo."], Color("547ff3"))


func set_estado_mision(id: String, estado: String) -> void:
	var antes := get_estado_mision(id)
	misiones[id] = estado
	mision_cambiada.emit()
	if estado == "completada" and antes != "completada":
		MusicManager.play_sfx("jingle_mision")
	# Cierre de la beta: al completar todas, festejo (una sola vez, tras cerrar
	# el diálogo de la última entrega).
	if estado == "completada":
		detener_cuenta(id)
		_revisar_logros_de_misiones()
	if not _victoria and misiones_completadas() >= total_misiones():
		_victoria = true
		dialog_ended.connect(_mostrar_victoria, CONNECT_ONE_SHOT)


func _mostrar_victoria() -> void:
	MusicManager.play_sfx("fanfarria_victoria")
	start_dialog("Monte Grande", [
		"¡Completaste el álbum del barrio, %s!" % jugador_nombre,
		"Todo Monte Grande te espera en la Plaza Mitre.",
	], Color("ffd23c"))
	victoria_lograda.emit()


## Pantalla final con créditos y descargo; al cerrarla se sigue paseando.
func mostrar_final() -> void:
	if final == null:
		final = CanvasLayer.new()
		final.set_script(preload("res://scripts/ui/final.gd"))
		add_child(final)
	final.visible = true
	is_dialog_active = true      # frena a Monti mientras está la pantalla


func cerrar_final() -> void:
	if final:
		final.visible = false
	is_dialog_active = false
	final_cerrado.emit()


## Misiones completadas del catálogo (o todas, si todavía no hay catálogo).
func misiones_completadas() -> int:
	var n := 0
	for k in misiones:
		if misiones[k] == "completada" and (catalogo.is_empty() or catalogo.has(k)):
			n += 1
	return n


# ==================== HUD ====================

func _add_hud() -> void:
	_hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(_hud)


func _add_touch_controls() -> void:
	_touch = preload("res://scenes/ui/touch_controls.tscn").instantiate()
	add_child(_touch)



# ==================== GUARDADO ====================

func registrar_objeto_tomado(nombre: String) -> void:
	if not (nombre in objetos_tomados):
		objetos_tomados.append(nombre)


func has_save() -> bool:
	return FileAccess.file_exists(ruta_guardado)


## Guarda el progreso del jugador y la foto del mundo vivo en JSON legible.
func save_game(mundo: Node = null) -> bool:
	if mundo == null:
		mundo = mundo_activo
	if mundo == null or not is_instance_valid(mundo) or not mundo.has_method("snapshot"):
		return false
	var datos := {
		"version": VERSION_GUARDADO,
		"jugador": {"nombre": jugador_nombre, "inventario": inventario.duplicate(),
			"misiones": misiones.duplicate(), "bici_color": bici_color.to_html(),
			"contadores": contadores.duplicate(true), "cuentas": cuentas.duplicate(true),
			"flags": flags.duplicate(true), "logros": logros.keys(),
			"progreso_logros": progreso_logros.duplicate(true)},
		"objetos_tomados": objetos_tomados.duplicate(),
		"mundo": mundo.snapshot(),
	}
	var f := FileAccess.open(ruta_guardado, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida en %s" % ruta_guardado)
		return false
	f.store_string(JSON.stringify(datos, "\t", true, true))  # precisión completa: determinismo al cargar
	f.close()
	return true


## Lee la partida y restaura el progreso del jugador. Devuelve los datos (o {} si no hay).
func leer_partida() -> Dictionary:
	if not has_save():
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta_guardado))
	if not (datos is Dictionary):
		push_warning("Partida guardada ilegible: se ignora")
		return {}
	var j: Dictionary = datos.get("jugador", {})
	inventario = j.get("inventario", []).duplicate()
	misiones.clear()
	var m: Dictionary = j.get("misiones", {})
	for k in m:
		misiones[str(k)] = str(m[k])
	var color_guardado := str(j.get("bici_color", ""))
	if Color.html_is_valid(color_guardado):
		bici_color = Color.html(color_guardado)
	en_bici = false
	objetos_tomados = datos.get("objetos_tomados", []).duplicate()
	flags = Dictionary(j.get("flags", {})).duplicate(true)
	logros = {}
	for id in j.get("logros", []):
		logros[str(id)] = true
	var pl: Dictionary = j.get("progreso_logros", {})
	progreso_logros = {"rumores": Array(pl.get("rumores", [])), "amigos": Array(pl.get("amigos", [])),
		"pedaleo": int(pl.get("pedaleo", 0)), "visitas": Array(pl.get("visitas", []))}
	contadores = {}
	var cs: Dictionary = j.get("contadores", {})
	for id in cs:
		var c: Dictionary = cs[id]
		contadores[str(id)] = {"giver": str(c.get("giver", "")), "objetivo": int(c.get("objetivo", 0)),
			"linea": str(c.get("linea", "")), "contactos": Array(c.get("contactos", [])).map(func(x): return str(x))}
	cuentas = {}
	var ct: Dictionary = j.get("cuentas", {})
	for id in ct:
		cuentas[str(id)] = {"restante": float(ct[id].get("restante", 0.0)), "item": str(ct[id].get("item", ""))}
	_victoria = misiones_completadas() >= total_misiones()
	inventario_cambiado.emit()
	return datos


func borrar_partida() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_guardado))
	objetos_tomados.clear()
	flags.clear()
	logros.clear()
	progreso_logros = {"rumores": [], "amigos": [], "pedaleo": 0, "visitas": []}
	contadores.clear()
	cuentas.clear()
	_victoria = false


## Autoguardado: sólo en juego real (no en tests headless) y con un mundo activo.
## Autoguardado: sólo con un mundo activo y fuera de los tests headless (salvo que el test lo pida).
var autoguardado_habilitado: bool = DisplayServer.get_name() != "headless"
var restaurando: bool = false           # cargando una partida: no autoguardar
const MINUTOS_ENTRE_GUARDADOS := 10      # minutos de juego (unos 10 segundos reales)
var _minutos_sin_guardar: int = 0
var _js_callbacks: Array = []           # referencias vivas a los callbacks de la web


func autoguardar() -> void:
	if not autoguardado_habilitado or en_transicion or restaurando:
		return
	if save_game():
		_minutos_sin_guardar = 0


func _on_tick_autoguardado(minutos: int) -> void:
	_minutos_sin_guardar += minutos
	if _minutos_sin_guardar >= MINUTOS_ENTRE_GUARDADOS:
		autoguardar()


## Web: guardar cuando la pestaña se oculta o se cierra (el navegador no avisa al cerrar).
func _escuchar_pagina_web() -> void:
	if not OS.has_feature("web"):
		return
	var cb := JavaScriptBridge.create_callback(_on_pagina_oculta)
	_js_callbacks.append(cb)
	var documento = JavaScriptBridge.get_interface("document")
	var ventana = JavaScriptBridge.get_interface("window")
	documento.addEventListener("visibilitychange", cb)
	ventana.addEventListener("pagehide", cb)


func _on_pagina_oculta(_args = null) -> void:
	if OS.has_feature("web"):
		var estado = JavaScriptBridge.eval("document.visibilityState", true)
		if str(estado) == "visible":
			return
	autoguardar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		autoguardar()
