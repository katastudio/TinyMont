extends CanvasLayer
## Textbox estilo Game Boy con craft:
## - marco doble (frame oscuro + interior pergamino)
## - nameplate teñido con el color del personaje que habla (tinta de contraste auto)
## - jerarquía nombre/cuerpo + indicador de avance que parpadea

const TYPE_SPEED := 0.03

var current_lines: Array = []
var line_index: int = 0
var char_index: int = 0
var is_typing: bool = false
var full_text: String = ""
var shown_text: String = ""
var type_timer: float = 0.0
var speaker_color: Color = Pal.WHITE
var _blink: float = 0.0

var inner: Panel
var name_plate: Panel
var name_label: Label
var text_label: Label
var indicator: Label


func _ready():
	GameManager.dialog_box = self
	layer = 10
	_build_ui()
	visible = false


func _build_ui():
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Marco exterior (frame oscuro)
	var frame = Panel.new()
	frame.anchor_top = 1.0
	frame.anchor_bottom = 1.0
	frame.anchor_right = 1.0
	frame.offset_top = -48.0
	frame.offset_left = 3.0
	frame.offset_right = -3.0
	frame.offset_bottom = -3.0
	var fstyle = StyleBoxFlat.new()
	fstyle.bg_color = Pal.BLACK
	fstyle.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", fstyle)
	root.add_child(frame)

	# Interior pergamino (inset 2px -> marco doble)
	inner = Panel.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 2.0
	inner.offset_top = 2.0
	inner.offset_right = -2.0
	inner.offset_bottom = -2.0
	var istyle = StyleBoxFlat.new()
	istyle.bg_color = Pal.WALL_TAN
	istyle.set_corner_radius_all(3)
	istyle.set_content_margin_all(4)
	inner.add_theme_stylebox_override("panel", istyle)
	frame.add_child(inner)

	# Cuerpo de texto (tinta marrón sobre pergamino)
	text_label = Label.new()
	text_label.position = Vector2(5, 7)
	text_label.size = Vector2(146, 34)
	text_label.add_theme_color_override("font_color", Pal.BRICK_DK)
	text_label.add_theme_font_size_override("font_size", 7)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(text_label)

	# Indicador de avance (parpadea)
	indicator = Label.new()
	indicator.position = Vector2(140, 30)
	indicator.text = "▼"
	indicator.add_theme_color_override("font_color", Pal.BRICK_DK)
	indicator.add_theme_font_size_override("font_size", 7)
	indicator.visible = false
	inner.add_child(indicator)

	# Nameplate: tab coloreado con el color del hablante, montado sobre el marco
	name_plate = Panel.new()
	name_plate.anchor_top = 1.0
	name_plate.anchor_bottom = 1.0
	name_plate.offset_top = -59.0
	name_plate.offset_bottom = -47.0
	name_plate.offset_left = 6.0
	name_plate.offset_right = 60.0
	root.add_child(name_plate)

	name_label = Label.new()
	name_label.position = Vector2(4, 1)
	name_label.add_theme_font_size_override("font_size", 8)
	name_plate.add_child(name_label)


func _ink_for(c: Color) -> Color:
	# Tinta de contraste según luminancia del fondo
	var l = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
	return Pal.BLACK if l > 0.55 else Pal.WHITE


func show_dialog(speaker: String, lines: Array, color: Color = Pal.WHITE):
	current_lines = lines
	speaker_color = color
	line_index = 0
	visible = true

	# Nameplate teñido + ancho según el nombre
	var ink = _ink_for(color)
	var plate_style = StyleBoxFlat.new()
	plate_style.bg_color = color
	plate_style.border_color = Pal.BLACK
	plate_style.set_border_width_all(2)
	plate_style.set_corner_radius_all(2)
	plate_style.set_content_margin_all(2)
	name_plate.add_theme_stylebox_override("panel", plate_style)
	name_plate.offset_right = 6.0 + speaker.length() * 5.0 + 10.0
	name_label.text = speaker
	name_label.add_theme_color_override("font_color", ink)

	_show_line()


func _show_line():
	if line_index >= current_lines.size():
		_close()
		return
	full_text = current_lines[line_index]
	shown_text = ""
	char_index = 0
	is_typing = true
	type_timer = 0.0
	text_label.text = ""
	indicator.visible = false


func _process(delta):
	if not visible:
		return

	if is_typing:
		type_timer += delta
		while type_timer >= TYPE_SPEED and char_index < full_text.length():
			shown_text += full_text[char_index]
			char_index += 1
			type_timer -= TYPE_SPEED
		text_label.text = shown_text
		if char_index >= full_text.length():
			is_typing = false
		indicator.visible = false
	else:
		# Indicador de avance parpadeante
		_blink += delta
		indicator.visible = fmod(_blink, 0.7) < 0.45

	if Input.is_action_just_pressed("interact"):
		if is_typing:
			shown_text = full_text
			text_label.text = shown_text
			is_typing = false
		else:
			line_index += 1
			_show_line()


func _close():
	visible = false
	GameManager.end_dialog()
