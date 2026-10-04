extends Node

signal dialog_started
signal dialog_ended
signal inventario_cambiado
signal mision_cambiada
signal encounter_ended

var is_dialog_active: bool = false
var dialog_box = null

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


func _add_key_action(action_name: String, key: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	InputMap.action_add_event(action_name, event)


func start_dialog(speaker_name: String, lines: Array, color: Color = Color.WHITE):
	is_dialog_active = true
	dialog_started.emit()
	if dialog_box:
		dialog_box.show_dialog(speaker_name, lines, color)


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


# ==================== MISIONES ====================

func get_estado_mision(id: String) -> String:
	return misiones.get(id, "no_iniciada")


const TOTAL_MISIONES := 8   # total de misiones de la beta (para el contador y el cierre)
var _victoria := false


func set_estado_mision(id: String, estado: String) -> void:
	var antes := get_estado_mision(id)
	misiones[id] = estado
	mision_cambiada.emit()
	if estado == "completada" and antes != "completada":
		MusicManager.play_sfx("jingle_mision")
	# Cierre de la beta: al completar todas, festejo (una sola vez, tras cerrar
	# el diálogo de la última entrega).
	if not _victoria and misiones_completadas() >= TOTAL_MISIONES:
		_victoria = true
		dialog_ended.connect(_mostrar_victoria, CONNECT_ONE_SHOT)


func _mostrar_victoria() -> void:
	MusicManager.play_sfx("fanfarria_victoria")
	start_dialog("Monte Grande", [
		"¡Felicitaciones, Monti!",
		"Ayudaste a todo\nel barrio de\nMonte Grande.",
		"Ya sos un\nMontegrandense\nde ley. ¡Bienvenido!",
	], Color("ffd23c"))


func misiones_completadas() -> int:
	var n := 0
	for k in misiones:
		if misiones[k] == "completada":
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
			"misiones": misiones.duplicate(), "bici_color": bici_color.to_html()},
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
	_victoria = misiones_completadas() >= TOTAL_MISIONES
	inventario_cambiado.emit()
	return datos


func borrar_partida() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_guardado))
	objetos_tomados.clear()


## Autoguardado: sólo en juego real (no en tests headless) y con un mundo activo.
func autoguardar() -> void:
	if DisplayServer.get_name() == "headless":
		return
	save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		autoguardar()
