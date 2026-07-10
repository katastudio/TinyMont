extends CanvasLayer
## Textbox estilo Game Boy con craft:
## - marco doble (frame oscuro + interior pergamino)
## - nameplate teñido con el color del personaje que habla (tinta de contraste auto)
## - jerarquía nombre/cuerpo + indicador de avance que parpadea

const TYPE_SPEED := 0.03
const CTRL_H := 48.0   # alto de la franja de controles abajo: el diálogo se apoya encima

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
var indicator: Control


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
	frame.offset_top = -52.0 - CTRL_H
	frame.offset_left = 3.0
	frame.offset_right = -3.0
	frame.offset_bottom = -3.0 - CTRL_H
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

	# Cuerpo de texto: tinta negra sobre pergamino (contraste alto = legible).
	# Rellena TODO el interior y recorta (clip_text) para no salirse nunca del marco.
	text_label = Label.new()
	text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_label.offset_left = 4.0
	text_label.offset_top = 3.0
	text_label.offset_right = -4.0
	text_label.offset_bottom = -3.0
	text_label.add_theme_color_override("font_color", Pal.BLACK)
	text_label.add_theme_font_size_override("font_size", 8)
	text_label.add_theme_constant_override("line_spacing", 0)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.clip_text = true
	inner.add_child(text_label)

	# Indicador de avance (parpadea), anclado abajo a la derecha del interior
	# Flechita ▼ dibujada por código (no depende de la fuente; en web el glyph
	# "▼" no existía y se veía como un cuadrado con basura).
	indicator = Control.new()
	indicator.set_script(preload("res://scripts/ui/arrow_indicator.gd"))
	indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	indicator.offset_left = -9.0
	indicator.offset_top = -8.0
	indicator.offset_right = -2.0
	indicator.offset_bottom = -2.0
	indicator.visible = false
	inner.add_child(indicator)

	# Nameplate: tab coloreado con el color del hablante, montado sobre el marco
	name_plate = Panel.new()
	name_plate.anchor_top = 1.0
	name_plate.anchor_bottom = 1.0
	name_plate.offset_top = -63.0 - CTRL_H
	name_plate.offset_bottom = -51.0 - CTRL_H
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


# El input de avance se maneja por evento (no polling) y se marca como consumido,
# para que la MISMA tecla que cierra el diálogo no la lea también el player.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		if is_typing:
			shown_text = full_text
			text_label.text = shown_text
			is_typing = false
		else:
			line_index += 1
			_show_line()
		get_viewport().set_input_as_handled()


func _close():
	visible = false
	GameManager.end_dialog()
