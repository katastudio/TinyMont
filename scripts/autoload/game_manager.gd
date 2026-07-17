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

var en_bici: bool = false           # Monti va montado en la bici (velocidad x1.7)
var bici_color: Color = Color("d83030")  # color de la bici que tomó (para dibujarla montado)


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
const CONTROLS_H := 104.0
func bottom_reserve(view_h: float) -> float:
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
