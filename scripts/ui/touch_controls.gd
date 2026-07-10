extends Control
## Controles handheld: PALANCA virtual (estilo joystick) + botones A/B, en una franja
## inferior opaca separada del mapa. La palanca da feel fluido; el movimiento sigue por
## grilla (mapea a las 4 direcciones del InputMap según el eje dominante).
## Sintetiza InputEventAction (parse_input_event) -> no toca la lógica del juego.
## Procedural, multitouch. Siempre visible; en desktop responde al mouse.

const BOTTOM_BAR := 48.0
const JOY_CX := 40.0        # centro X de la palanca (izquierda de la franja)
const JOY_RADIUS := 20.0    # radio de la base
const KNOB_RADIUS := 11.0   # radio de la perilla
const DEADZONE := 0.34      # fracción del radio antes de registrar dirección

var _joy_index := -999      # dedo/puntero que controla la palanca (-999 = ninguno)
var _joy_offset := Vector2.ZERO   # desplazamiento de la perilla (para dibujar)
var _joy_dir := ""          # move action actualmente presionada
var _touch_action := {}     # index -> action (para A/B)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _joy_center() -> Vector2:
	return Vector2(JOY_CX, size.y - BOTTOM_BAR / 2.0)


func _ab_defs() -> Array:
	var w := size.x
	var cy := size.y - BOTTOM_BAR / 2.0
	return [
		{action = "menu", rect = Rect2(w - 54, cy - 4, 20, 20), kind = "B"},
		{action = "interact", rect = Rect2(w - 30, cy - 16, 20, 20), kind = "A"},
	]


func _draw() -> void:
	var w := size.x
	var top := size.y - BOTTOM_BAR
	draw_rect(Rect2(0, top, w, BOTTOM_BAR), Pal.UI_BG)         # franja gris (Game Boy)
	draw_rect(Rect2(0, top, w, 1), Pal.UI_ACCENT)             # acento (enmarca el mapa)

	# --- Palanca ---
	var c := _joy_center()
	draw_circle(c, JOY_RADIUS, Pal.UI_BG.darkened(0.16))       # base hundida
	draw_arc(c, JOY_RADIUS, 0, TAU, 32, Pal.UI_EDGE, 1.5)      # aro de la base
	var knob := c + _joy_offset
	var kcol: Color = Pal.UI_DPAD.lightened(0.28) if _joy_dir != "" else Pal.UI_DPAD
	draw_circle(knob, KNOB_RADIUS, kcol)                       # perilla
	draw_arc(knob, KNOB_RADIUS, 0, TAU, 24, Pal.UI_EDGE, 1.0)

	# --- Botones A/B ---
	var font := ThemeDB.fallback_font
	for d in _ab_defs():
		var r: Rect2 = d.rect
		var bc := r.get_center()
		var on: bool = Input.is_action_pressed(d.action)
		var col: Color = (Pal.UI_A if d.kind == "A" else Pal.UI_B)
		draw_circle(bc, r.size.x / 2.0, col.lightened(0.3) if on else col)
		draw_arc(bc, r.size.x / 2.0, 0, TAU, 24, Pal.UI_EDGE, 1.0)
		if font:
			draw_string(font, bc + Vector2(-3, 3), d.kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Pal.UI_LIGHT)


func _in_joystick(pos: Vector2) -> bool:
	return pos.y >= size.y - BOTTOM_BAR and pos.x < size.x * 0.5


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


func _press(index: int, pos: Vector2) -> void:
	if _in_joystick(pos):
		_joy_index = index
		_joy_update(pos)
		get_viewport().set_input_as_handled()
		return
	# Botones A/B
	for d in _ab_defs():
		if (d.rect as Rect2).has_point(pos):
			_touch_action[index] = d.action
			_send(d.action, true)
			get_viewport().set_input_as_handled()
			queue_redraw()
			return


func _drag(index: int, pos: Vector2) -> void:
	if index == _joy_index:
		_joy_update(pos)


func _release(index: int) -> void:
	if index == _joy_index:
		_joy_release()
		return
	if _touch_action.has(index):
		_send(_touch_action[index], false)
		_touch_action.erase(index)
		queue_redraw()


# --- Palanca: actualizar posición de la perilla y la dirección ---
func _joy_update(pos: Vector2) -> void:
	var delta := pos - _joy_center()
	if delta.length() > JOY_RADIUS:
		delta = delta.normalized() * JOY_RADIUS
	_joy_offset = delta

	var new_dir := ""
	if delta.length() >= JOY_RADIUS * DEADZONE:
		if absf(delta.x) > absf(delta.y):
			new_dir = "move_right" if delta.x > 0 else "move_left"
		else:
			new_dir = "move_down" if delta.y > 0 else "move_up"
	if new_dir != _joy_dir:
		if _joy_dir != "":
			_send(_joy_dir, false)
		if new_dir != "":
			_send(new_dir, true)
		_joy_dir = new_dir
	queue_redraw()


func _joy_release() -> void:
	if _joy_dir != "":
		_send(_joy_dir, false)
	_joy_dir = ""
	_joy_offset = Vector2.ZERO
	_joy_index = -999
	queue_redraw()


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
