extends Control
## Controles estilo handheld (Game Boy): d-pad + botones A/B en una franja INFERIOR
## opaca, separada del mapa (la cámara reserva esa franja abajo, ver limit_bottom).
## Sintetiza InputEventAction (parse_input_event) para alimentar el MISMO InputMap que el
## teclado -> no toca la lógica del juego (movimiento por polling, interact por evento).
## Procedural, multitouch. Siempre visible (parte del layout); en desktop responde al mouse.

const BOTTOM_BAR := 48.0

var _touch_action := {}   # index del dedo/puntero -> action que mantiene apretada


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# Botones dentro de la franja inferior (misma fuente para dibujar y para el hit-test).
func _button_defs() -> Array:
	var w := size.x
	var cy := size.y - BOTTOM_BAR / 2.0   # centro vertical de la franja
	var cx := 30.0
	var b := 13.0
	return [
		{action = "move_up",    rect = Rect2(cx - b / 2, cy - b - b / 2, b, b), kind = "up"},
		{action = "move_down",  rect = Rect2(cx - b / 2, cy + b / 2, b, b), kind = "down"},
		{action = "move_left",  rect = Rect2(cx - b - b / 2, cy - b / 2, b, b), kind = "left"},
		{action = "move_right", rect = Rect2(cx + b / 2, cy - b / 2, b, b), kind = "right"},
		{action = "menu",     rect = Rect2(w - 51, cy - 5, 18, 18), kind = "B"},
		{action = "interact", rect = Rect2(w - 29, cy - 13, 18, 18), kind = "A"},
	]


func _draw() -> void:
	var w := size.x
	var top := size.y - BOTTOM_BAR
	draw_rect(Rect2(0, top, w, BOTTOM_BAR), Pal.UI_BG)         # franja verde
	draw_rect(Rect2(0, top, w, 1), Pal.UI_ACCENT)             # acento verde (enmarca el mapa)

	var font := ThemeDB.fallback_font
	for d in _button_defs():
		var r: Rect2 = d.rect
		var on: bool = Input.is_action_pressed(d.action)
		match d.kind:
			"A":
				_circle(r, Pal.UI_A, on, "A", font)
			"B":
				_circle(r, Pal.UI_B, on, "B", font)
			_:
				var col: Color = Pal.UI_DPAD.lightened(0.35) if on else Pal.UI_DPAD
				draw_rect(r, col)
				draw_rect(r, Pal.UI_EDGE, false, 1.0)
				_arrow(r.get_center(), d.kind)


func _circle(r: Rect2, base: Color, on: bool, label: String, font) -> void:
	var c := r.get_center()
	var col: Color = base.lightened(0.35) if on else base
	draw_circle(c, r.size.x / 2.0, col)
	draw_arc(c, r.size.x / 2.0, 0, TAU, 20, Pal.UI_EDGE, 1.0)
	if font:
		draw_string(font, c + Vector2(-3, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Pal.UI_LIGHT)


func _arrow(c: Vector2, dir: String) -> void:
	var s := 3.0
	var pts: PackedVector2Array
	match dir:
		"up":    pts = [c + Vector2(0, -s), c + Vector2(-s, s), c + Vector2(s, s)]
		"down":  pts = [c + Vector2(0, s), c + Vector2(-s, -s), c + Vector2(s, -s)]
		"left":  pts = [c + Vector2(-s, 0), c + Vector2(s, -s), c + Vector2(s, s)]
		"right": pts = [c + Vector2(s, 0), c + Vector2(-s, -s), c + Vector2(-s, s)]
	draw_colored_polygon(pts, Pal.UI_LIGHT)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-1, event.position)
		else:
			_release(-1)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_drag(-1, event.position)


func _button_at(pos: Vector2) -> String:
	for d in _button_defs():
		if (d.rect as Rect2).has_point(pos):
			return d.action
	return ""


func _press(index: int, pos: Vector2) -> void:
	var action := _button_at(pos)
	if action == "":
		return
	_touch_action[index] = action
	_send(action, true)
	get_viewport().set_input_as_handled()
	queue_redraw()


# Deslizar el dedo entre botones del d-pad (soltar el anterior, apretar el nuevo).
func _drag(index: int, pos: Vector2) -> void:
	var now := _button_at(pos)
	var current: String = _touch_action.get(index, "")
	if now == current:
		return
	if current != "":
		_send(current, false)
		_touch_action.erase(index)
	if now.begins_with("move_"):   # A/B son tap, no se enganchan arrastrando
		_touch_action[index] = now
		_send(now, true)
	queue_redraw()


func _release(index: int) -> void:
	if _touch_action.has(index):
		_send(_touch_action[index], false)
		_touch_action.erase(index)
		queue_redraw()


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
