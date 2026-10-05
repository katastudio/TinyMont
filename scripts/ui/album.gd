extends CanvasLayer
## Álbum del barrio (spec 0008 R3): un espacio por misión del catálogo, con el objeto icónico
## si ya lo conseguiste o una silueta si todavía no. 100% procedural. Lo abre GameManager.

const ItemArt = preload("res://scripts/art/item_art.gd")
const COLUMNAS := 4
const LADO := 22.0          # lado de cada espacio
const SEP_X := 34.0
const SEP_Y := 36.0
const FONDO := Color("2c2c38")
const MARCO := Color("14141a")
const TEXTO := Color("ecece4")
const DORADO := Color("ffd23c")

var _hoja: Control


func _ready() -> void:
	layer = 9
	_hoja = Control.new()
	_hoja.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hoja.mouse_filter = Control.MOUSE_FILTER_STOP
	_hoja.draw.connect(_dibujar)
	_hoja.gui_input.connect(_on_gui_input)
	add_child(_hoja)
	GameManager.inventario_cambiado.connect(_hoja.queue_redraw)
	GameManager.mision_cambiada.connect(_hoja.queue_redraw)


## Un espacio por misión del catálogo, en el orden de la escena.
func espacios() -> Array:
	var lista: Array = []
	for id in GameManager.catalogo:
		var e: Dictionary = GameManager.catalogo[id]
		var estado := GameManager.get_estado_mision(id)
		lista.append({
			"mision": id, "giver": str(e.giver), "recompensa": str(e.recompensa), "estado": estado,
			"conseguido": estado == "completada" and GameManager.tiene_item(str(e.recompensa)),
		})
	return lista


func texto_logros() -> String:
	return "Logros %d/%d" % [GameManager.logros.size(), GameManager.LOGROS.size()]


func texto_contador() -> String:
	var n := espacios().filter(func(e): return e.conseguido).size()
	return "%d/%d" % [n, GameManager.total_misiones()]


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("album") or event.is_action_pressed("interact"):
		GameManager.cerrar_album()
		get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.cerrar_album()
		get_viewport().set_input_as_handled()


func _dibujar() -> void:
	var s := _hoja.size
	var font := ThemeDB.fallback_font
	_hoja.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55))
	var ancho := COLUMNAS * SEP_X + 12.0
	var lista := espacios()
	var filas := ceili(lista.size() / float(COLUMNAS))
	var alto := 24.0 + filas * SEP_Y + 30.0
	var panel := Rect2((s.x - ancho) / 2.0, maxf(28.0, (s.y - alto) / 2.0), ancho, alto)
	_hoja.draw_rect(panel.grow(2), MARCO)
	_hoja.draw_rect(panel, FONDO)
	if font:
		_hoja.draw_string(font, panel.position + Vector2(8, 14), "Álbum del barrio", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXTO)
		_hoja.draw_string(font, panel.position + Vector2(ancho - 34, 14), texto_contador(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DORADO)
	for i in lista.size():
		var e: Dictionary = lista[i]
		var celda := panel.position + Vector2(10 + (i % COLUMNAS) * SEP_X, 22 + (i / COLUMNAS) * SEP_Y)
		var r := Rect2(celda, Vector2(LADO, LADO))
		_hoja.draw_rect(r, Color("1a1a20"))
		_hoja.draw_rect(r, MARCO, false, 1.0)
		if e.conseguido:
			ItemArt.draw_on(_hoja, e.recompensa, Rect2(celda + Vector2(4, 3), Vector2(14, 15)))
		else:
			# Silueta: el contorno del espacio con un signo de pregunta.
			if font:
				_hoja.draw_string(font, celda + Vector2(8, 15), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.25))
			if e.estado == "en_curso":
				_hoja.draw_rect(Rect2(celda + Vector2(LADO - 4, 1), Vector2(3, 3)), DORADO)
		if font:
			_hoja.draw_string(font, celda + Vector2(-4, LADO + 8), e.giver, HORIZONTAL_ALIGNMENT_CENTER, LADO + 8, 5, TEXTO if e.conseguido else Color(1, 1, 1, 0.45))
	# Logros: una estrella por logro (llena si está desbloqueado) y el contador.
	var y_logros := panel.position.y + 24.0 + filas * SEP_Y + 2.0
	if font:
		_hoja.draw_string(font, Vector2(panel.position.x + 8, y_logros + 8), texto_logros(), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, DORADO)
	var i := 0
	for id in GameManager.LOGROS:
		var c := Vector2(panel.position.x + 14 + i * ((ancho - 20) / GameManager.LOGROS.size()), y_logros + 20)
		_estrella(c, DORADO if GameManager.tiene_logro(id) else Color(1, 1, 1, 0.18))
		i += 1


func _estrella(c: Vector2, color: Color) -> void:
	_hoja.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -5), c + Vector2(1.5, -1.5), c + Vector2(5, -1), c + Vector2(2, 1.5),
		c + Vector2(3, 5), c + Vector2(0, 3), c + Vector2(-3, 5), c + Vector2(-2, 1.5),
		c + Vector2(-5, -1), c + Vector2(-1.5, -1.5),
	]), color)
