extends Control
## Botón de mute reutilizable (HUD y título): parlante procedural estilo
## charcoal, sin assets. Tap/click togglea MusicManager.set_enabled(); el
## estado vive en MusicManager (no acá) y la señal enabled_changed redibuja
## también cuando se mutea con la tecla M.

const TAM := 16.0
const CUERPO := Color("3a3a48")
const BORDE := Color("14141a")
const MARCA := Color("ecece4")


func _ready() -> void:
	custom_minimum_size = Vector2(TAM, TAM)
	size = Vector2(TAM, TAM)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # el hit-test es manual en _input
	# Diferido: este widget puede instanciarse antes de que exista el autoload
	# MusicManager (el HUD se crea durante el _ready de GameManager).
	_conectar.call_deferred()


func _conectar() -> void:
	MusicManager.enabled_changed.connect(func(_v: bool) -> void: queue_redraw())


func _draw() -> void:
	var on: bool = MusicManager.is_enabled()
	# domo charcoal (mismo lenguaje que la barra del HUD)
	draw_rect(Rect2(1, 1, 14, 14), CUERPO)
	draw_rect(Rect2(2, 2, 12, 1), Color(1, 1, 1, 0.10))   # highlight superior
	draw_rect(Rect2(1, 1, 14, 14), BORDE, false, 1.0)
	# parlante: caja + cono
	draw_rect(Rect2(4, 6.5, 2, 3), MARCA)
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, 6.5), Vector2(8.5, 4), Vector2(8.5, 12), Vector2(6, 9.5)]), MARCA)
	if on:
		# ondas de sonido
		draw_arc(Vector2(9, 8), 2.2, -PI / 3.0, PI / 3.0, 6, MARCA, 1.0)
		draw_arc(Vector2(9, 8), 4.0, -PI / 3.0, PI / 3.0, 8, MARCA, 1.0)
	else:
		# tachado diagonal
		draw_line(Vector2(3.5, 3.5), Vector2(12.5, 12.5), MARCA, 1.2)


# Input manual (no _gui_input): el padre suele tener mouse_filter IGNORE y en
# mobile los touch llegan como InputEventScreenTouch sin emulación de mouse.
# Solo consume el evento cuando cae dentro del botón.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var es_touch := event is InputEventScreenTouch
	if not es_touch and not (event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not get_global_rect().grow(4).has_point(event.position):
		return   # no es para este botón: que siga al juego de abajo
	if event.pressed:
		MusicManager.set_enabled(not MusicManager.is_enabled())
	get_viewport().set_input_as_handled()
