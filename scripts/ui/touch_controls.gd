extends Control
## Overlay táctil estilo emulador de GBA: d-pad de 4 flechas sueltas en rombo
## (abajo-izquierda) + botones A/B redondos (abajo-derecha), todo gris monocromo
## translúcido flotando sobre el juego. Una sola dirección activa a la vez;
## deslizar el dedo entre flechas cambia la dirección (sintetiza move_* del
## InputMap). Procedural, multitouch; en desktop responde al mouse.

const ALPHA := 0.62
const KEY := 24.0    # lado de cada tecla del d-pad
const GAP := 2.0     # separación entre tecla y centro del rombo
const AB_R := 17.0   # radio de los botones A/B

# grises del overlay (monocromo, independiente de Pal)
const COL_BODY := Color(0.78, 0.78, 0.80)      # cuerpo gris claro
const COL_BODY_ON := Color(0.52, 0.52, 0.56)   # cuerpo presionado (hundido)
const COL_EDGE := Color(0.32, 0.32, 0.36)      # borde gris oscuro
const COL_MARK := Color(0.30, 0.30, 0.34)      # chevrons y letras grabadas
const COL_SHADOW := Color(0, 0, 0, 0.25)

# chevron apuntando hacia arriba, relativo al centro de la tecla (se rota por dirección)
const CHEV: PackedVector2Array = [Vector2(-4.5, 2), Vector2(0, -2.5), Vector2(4.5, 2)]

var _index := -999
var _dir := ""
var _touch_action := {}
var _sb_body: StyleBoxFlat
var _sb_body_on: StyleBoxFlat
var _sb_shadow: StyleBoxFlat


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1, 1, 1, ALPHA)
	_sb_body = _make_sb(COL_BODY, true)
	_sb_body_on = _make_sb(COL_BODY_ON, true)
	_sb_shadow = _make_sb(COL_SHADOW, false)
	# Solo en dispositivos táctiles (celu / web mobile). En desktop y web-desktop se
	# juega con teclado (flechas/WASD + Z/Espacio + B) y no tapamos el mapa.
	if not DisplayServer.is_touchscreen_available():
		hide()
		set_process_input(false)


func _make_sb(col: Color, bordered: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(5)
	if bordered:
		sb.border_color = COL_EDGE
		sb.set_border_width_all(1)
	return sb


# cuánto subimos los controles del borde inferior (+ home-indicator del celu)
func _lift() -> float:
	return 28.0 + GameManager.safe_bottom_frac() * size.y


func _dpad_center() -> Vector2:
	var half := KEY * 1.5 + GAP   # medio rombo (tecla y media + gap)
	return Vector2(half + 14.0, size.y - half - 16.0 - _lift())


func _dpad_keys() -> Array:
	var c := _dpad_center()
	var off := KEY + GAP   # del centro del rombo al centro de cada tecla
	var half := KEY / 2.0
	return [
		{action = "move_up", rect = Rect2(c + Vector2(-half, -off - half), Vector2(KEY, KEY)), ang = 0.0},
		{action = "move_down", rect = Rect2(c + Vector2(-half, off - half), Vector2(KEY, KEY)), ang = PI},
		{action = "move_left", rect = Rect2(c + Vector2(-off - half, -half), Vector2(KEY, KEY)), ang = -PI / 2},
		{action = "move_right", rect = Rect2(c + Vector2(off - half, -half), Vector2(KEY, KEY)), ang = PI / 2},
	]


func _ab_defs() -> Array:
	var w := size.x
	var cy := size.y - 40.0 - _lift()
	return [
		{action = "toggle_bici", rect = Rect2(w - 72.0, cy - 3.0, AB_R * 2, AB_R * 2), kind = "B"},
		{action = "interact", rect = Rect2(w - 40.0, cy - 23.0, AB_R * 2, AB_R * 2), kind = "A"},
	]


# ==================== DIBUJO ====================

func _draw() -> void:
	for k in _dpad_keys():
		_draw_key(k)
	_draw_ab()


func _draw_key(k: Dictionary) -> void:
	var r: Rect2 = k.rect
	var ang: float = k.ang
	var pressed: bool = _dir == k.action
	draw_style_box(_sb_shadow, Rect2(r.position + Vector2(0, 2), r.size))
	draw_style_box(_sb_body_on if pressed else _sb_body, r)
	if not pressed:
		draw_line(r.position + Vector2(5, 2.5), Vector2(r.end.x - 5, r.position.y + 2.5), Color(1, 1, 1, 0.35), 1.0)
	var kc := r.get_center() + (Vector2(0, 1) if pressed else Vector2.ZERO)
	var pts := PackedVector2Array()
	for p in CHEV:
		pts.append(kc + p.rotated(ang))
	draw_polyline(pts, COL_MARK, 3.0)


func _draw_ab() -> void:
	var font := ThemeDB.fallback_font
	for d in _ab_defs():
		var bc := (d.rect as Rect2).get_center()
		var on: bool = Input.is_action_pressed(d.action)
		draw_circle(bc + Vector2(0, 2), AB_R, COL_SHADOW)
		draw_circle(bc, AB_R, COL_EDGE)
		draw_circle(bc, AB_R - 1.5, COL_BODY_ON if on else COL_BODY)
		if not on:
			draw_arc(bc, AB_R - 3.5, deg_to_rad(200), deg_to_rad(340), 16, Color(1, 1, 1, 0.35), 1.5)
		if font:
			var lp := bc + Vector2(-8, 4)
			draw_string(font, lp + Vector2(0, 1), d.kind, HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color(1, 1, 1, 0.30))
			draw_string(font, lp, d.kind, HORIZONTAL_ALIGNMENT_CENTER, 16, 11, COL_MARK)


# ==================== INPUT ====================

func _dpad_hit(pos: Vector2) -> bool:
	for k in _dpad_keys():
		if (k.rect as Rect2).grow(4.0).has_point(pos):
			return true
	return false


func _dir_at(pos: Vector2) -> String:
	var hits: Array = []
	for k in _dpad_keys():
		if (k.rect as Rect2).grow(4.0).has_point(pos):
			hits.append(k.action)
	if hits.is_empty():
		return ""
	if hits.size() == 1:
		return hits[0]
	# zona ambigua entre dos flechas: gana el eje dominante
	var delta := pos - _dpad_center()
	if absf(delta.x) > absf(delta.y):
		return "move_right" if delta.x > 0 else "move_left"
	return "move_down" if delta.y > 0 else "move_up"


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
	if _dpad_hit(pos):
		_index = index
		_update(pos)
		get_viewport().set_input_as_handled()
		return
	# los margenes de tolerancia de A y B se solapan: gana el centro mas cercano
	var best: Dictionary = {}
	var best_d := AB_R + 4.0
	for d in _ab_defs():
		var dist := (d.rect as Rect2).get_center().distance_to(pos)
		if dist <= best_d:
			best = d
			best_d = dist
	if not best.is_empty():
		_touch_action[index] = best.action
		_send(best.action, true)
		get_viewport().set_input_as_handled()
		queue_redraw()


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
	var nd := _dir_at(pos)
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
	_index = -999
	queue_redraw()


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
