extends Control
## Control DEFINITIVO: PALANCA FIJA pulida (base hundida con relieve + perilla con
## domo y brillo + sombra) y botones A/B con volumen. Sobre el mapa, abajo-izquierda.
## La base NO se mueve; la perilla sigue al dedo (feel analógico), y el movimiento
## sigue por grilla según el eje dominante (sintetiza move_* del InputMap).
## Procedural, multitouch; en desktop responde al mouse.

const ALPHA := 0.92
const JOY_R := 28.0        # radio de la base
const KNOB_R := 13.0       # radio de la perilla
const MAX_OFFSET := 15.0   # JOY_R - KNOB_R: la perilla no se sale del aro
const DEADZONE := 0.34     # fracción del recorrido antes de registrar dirección
const KNOB_COL := Color("4f7bf0")

var _index := -999
var _dir := ""
var _touch_action := {}
var _knob_offset := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1, 1, 1, ALPHA)
	# Solo en dispositivos táctiles (celu / web mobile). En desktop y web-desktop se
	# juega con teclado (flechas/WASD + Z/Espacio + B) y no tapamos el mapa.
	if not DisplayServer.is_touchscreen_available():
		hide()
		set_process_input(false)


# cuánto subimos los controles del borde inferior (+ home-indicator del celu)
func _lift() -> float:
	return 28.0 + GameManager.safe_bottom_frac() * size.y


func _default_center() -> Vector2:
	return Vector2(JOY_R + 14.0, size.y - JOY_R - 16.0 - _lift())


func _center() -> Vector2:
	return _default_center()   # FIJA: la base no se mueve


func _ab_defs() -> Array:
	var w := size.x
	var cy := size.y - 40.0 - _lift()
	return [
		{action = "toggle_bici", rect = Rect2(w - 66, cy + 12, 26, 26), kind = "B"},
		{action = "interact", rect = Rect2(w - 34, cy - 14, 26, 26), kind = "A"},
	]


# ==================== DIBUJO ====================

func _draw() -> void:
	_draw_joystick()
	_draw_ab()


func _draw_joystick() -> void:
	var c := _center()
	draw_circle(c + Vector2(0, 3), JOY_R, Color(0, 0, 0, 0.25))       # sombra
	draw_circle(c, JOY_R, Color("20202a"))                           # aro exterior oscuro
	draw_circle(c, JOY_R - 2, Color("3a3a48"))                       # base
	draw_circle(c, JOY_R - 6, Color("2c2c38"))                       # dish hundido
	draw_arc(c, JOY_R - 3, 0, TAU, 32, Color(1, 1, 1, 0.10), 1.0)    # highlight del borde
	for a in [0.0, 90.0, 180.0, 270.0]:                             # guías de dirección
		var v := Vector2.from_angle(deg_to_rad(a)) * (JOY_R - 9)
		draw_circle(c + v, 1.4, Color(1, 1, 1, 0.18))
	_dome(c + _knob_offset, KNOB_R, KNOB_COL, _dir != "")            # perilla


func _dome(bc: Vector2, rad: float, base: Color, pressed: bool) -> void:
	draw_circle(bc + Vector2(0, 2.5), rad, Color(0, 0, 0, 0.28))          # sombra
	draw_circle(bc, rad, Color("14141a"))                                # borde
	draw_circle(bc, rad - 1.5, base.darkened(0.22))
	draw_circle(bc + Vector2(0, -1.5), rad - 3, base.lightened(0.18) if pressed else base)
	draw_circle(bc + Vector2(0, -rad * 0.35), rad * 0.5, base.lightened(0.22))  # gradiente
	draw_circle(bc + Vector2(-rad * 0.3, -rad * 0.4), rad * 0.34, Color(1, 1, 1, 0.38))  # brillo


func _draw_ab() -> void:
	var font := ThemeDB.fallback_font
	for d in _ab_defs():
		var r: Rect2 = d.rect
		var bc := r.get_center()
		var on: bool = Input.is_action_pressed(d.action)
		var col: Color = Pal.UI_A if d.kind == "A" else Pal.UI_B
		_dome(bc, r.size.x / 2.0, col, on)
		if font:
			draw_string(font, bc + Vector2(-3, 3), d.kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Pal.UI_LIGHT)


# ==================== INPUT ====================

func _in_zone(pos: Vector2) -> bool:
	# área FIJA alrededor de la palanca (con tolerancia para el pulgar)
	return pos.distance_to(_default_center()) <= JOY_R + 26.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: _press(event.index, event.position)
		else: _release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press(-1, event.position)
		else: _release(-1)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_drag(-1, event.position)


func _press(index: int, pos: Vector2) -> void:
	if _in_zone(pos):
		_index = index
		_update(pos)
		get_viewport().set_input_as_handled()
		return
	for d in _ab_defs():
		if (d.rect as Rect2).has_point(pos):
			_touch_action[index] = d.action
			_send(d.action, true)
			get_viewport().set_input_as_handled()
			queue_redraw()
			return


func _drag(index: int, pos: Vector2) -> void:
	if index == _index:
		_update(pos)


func _release(index: int) -> void:
	if index == _index:
		_release_move()
		return
	if _touch_action.has(index):
		_send(_touch_action[index], false)
		_touch_action.erase(index)
		queue_redraw()


func _update(pos: Vector2) -> void:
	var delta := pos - _center()
	if delta.length() > MAX_OFFSET:
		delta = delta.normalized() * MAX_OFFSET
	_knob_offset = delta
	var nd := ""
	if delta.length() >= MAX_OFFSET * DEADZONE:
		if absf(delta.x) > absf(delta.y):
			nd = "move_right" if delta.x > 0 else "move_left"
		else:
			nd = "move_down" if delta.y > 0 else "move_up"
	if nd != _dir:
		if _dir != "":
			_send(_dir, false)
		if nd != "":
			_send(nd, true)
		_dir = nd
	queue_redraw()


func _release_move() -> void:
	if _dir != "":
		_send(_dir, false)
	_dir = ""
	_knob_offset = Vector2.ZERO
	_index = -999
	queue_redraw()


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
