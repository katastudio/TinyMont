extends CanvasLayer
## Pantalla final (spec 0008 R5): Monti ya es vecino. Créditos y descargo (R7).
## Se cierra con cualquier tecla o toque y se sigue paseando por el barrio.

const ItemArt = preload("res://scripts/art/item_art.gd")
const FONDO := Color("2c2c38")
const MARCO := Color("14141a")
const TEXTO := Color("ecece4")
const DORADO := Color("ffd23c")

var _hoja: Control
var _t := 0.0


func _ready() -> void:
	layer = 11
	_hoja = Control.new()
	_hoja.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hoja.mouse_filter = Control.MOUSE_FILTER_STOP
	_hoja.draw.connect(_dibujar)
	_hoja.gui_input.connect(_on_gui_input)
	add_child(_hoja)


func texto_titulo() -> String:
	return "¡Ya sos vecino de Monte Grande!"


func texto_creditos() -> String:
	return "\n".join([
		"Completaste el álbum: %d/%d." % [GameManager.misiones_completadas(), GameManager.total_misiones()],
		"TinyMont, hecho con cariño",
		"en Monte Grande por Kata Studio.",
		"Arte, música y vecinos por código.",
		"Personajes ficticios inspirados",
		"con cariño en ídolos populares.",
	])


func _process(delta: float) -> void:
	if visible:
		_t += delta
		_hoja.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _t > 1.0 and (event.is_action_pressed("interact") or event.is_action_pressed("menu")):
		GameManager.cerrar_final()
		get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void:
	if _t > 1.0 and (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.cerrar_final()
		get_viewport().set_input_as_handled()


func _dibujar() -> void:
	var s := _hoja.size
	var font := ThemeDB.fallback_font
	_hoja.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.6))
	var panel := Rect2(8, s.y * 0.22, s.x - 16, 142)
	_hoja.draw_rect(panel.grow(2), MARCO)
	_hoja.draw_rect(panel, FONDO)
	var brillo := 1.0 + sin(_t * 4.0) * 0.08
	ItemArt.draw_on(_hoja, "medalla", Rect2(panel.get_center().x - 7, panel.position.y + 8, 14 * brillo, 16 * brillo))
	if font == null:
		return
	_hoja.draw_string(font, Vector2(panel.position.x, panel.position.y + 38), texto_titulo(),
			HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 9, DORADO)
	var y := panel.position.y + 54
	for linea in texto_creditos().split("\n"):
		_hoja.draw_string(font, Vector2(panel.position.x + 6, y), linea, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 12, 6, TEXTO)
		y += 12
	if _t > 1.0 and fmod(_t, 1.0) < 0.7:
		_hoja.draw_string(font, Vector2(panel.position.x, panel.end.y - 6), "Tocá para seguir paseando",
				HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 6, Color(TEXTO, 0.7))
