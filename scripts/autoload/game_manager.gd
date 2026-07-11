extends Node

signal dialog_started
signal dialog_ended
signal inventario_cambiado
signal mision_cambiada

var is_dialog_active: bool = false
var dialog_box = null

# --- Estado del jugador / progreso ---
var jugador_nombre: String = "Monti"
var inventario: Array = []          # ids de objetos que Monti lleva en la mochila
var misiones: Dictionary = {}       # mision_id -> "no_iniciada" | "en_curso" | "completada"


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


# En mobile/touch llenamos la pantalla (expand); en PC se mantiene "keep"
# (handheld centrado, lo más grande posible sin distorsión).
func _adaptar_pantalla() -> void:
	if DisplayServer.is_touchscreen_available():
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


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


# ==================== INVENTARIO (mochila) ====================

func agregar_item(item: String) -> void:
	inventario.append(item)
	inventario_cambiado.emit()


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
	misiones[id] = estado
	mision_cambiada.emit()
	# Cierre de la beta: al completar todas, festejo (una sola vez, tras cerrar
	# el diálogo de la última entrega).
	if not _victoria and misiones_completadas() >= TOTAL_MISIONES:
		_victoria = true
		dialog_ended.connect(_mostrar_victoria, CONNECT_ONE_SHOT)


func _mostrar_victoria() -> void:
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
