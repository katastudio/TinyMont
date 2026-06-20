extends CanvasLayer


const TYPE_SPEED := 0.03

var current_lines: Array = []
var line_index: int = 0
var char_index: int = 0
var is_typing: bool = false
var full_text: String = ""
var shown_text: String = ""
var type_timer: float = 0.0

var panel: Panel
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

	panel = Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -46.0
	panel.offset_left = 2.0
	panel.offset_right = -2.0
	panel.offset_bottom = -2.0

	var style = StyleBoxFlat.new()
	style.bg_color = Pal.WALL_TAN
	style.border_color = Pal.BLACK
	style.set_border_width_all(2)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	name_label = Label.new()
	name_label.position = Vector2(4, 2)
	name_label.add_theme_color_override("font_color", Pal.BLACK)
	name_label.add_theme_font_size_override("font_size", 8)
	panel.add_child(name_label)

	text_label = Label.new()
	text_label.position = Vector2(4, 13)
	text_label.size = Vector2(148, 28)
	text_label.add_theme_color_override("font_color", Pal.BRICK_DK)
	text_label.add_theme_font_size_override("font_size", 7)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(text_label)

	indicator = Label.new()
	indicator.position = Vector2(142, 30)
	indicator.text = "▼"
	indicator.add_theme_color_override("font_color", Pal.BLACK)
	indicator.add_theme_font_size_override("font_size", 7)
	indicator.visible = false
	panel.add_child(indicator)


func show_dialog(speaker: String, lines: Array):
	current_lines = lines
	line_index = 0
	visible = true
	name_label.text = speaker
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
			indicator.visible = true

	if Input.is_action_just_pressed("interact"):
		if is_typing:
			# Show full text immediately
			shown_text = full_text
			text_label.text = shown_text
			is_typing = false
			indicator.visible = true
		else:
			line_index += 1
			_show_line()


func _close():
	visible = false
	GameManager.end_dialog()
