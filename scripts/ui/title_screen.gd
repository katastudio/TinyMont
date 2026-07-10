extends Control
## Pantalla de bienvenida (después del boot splash). Postal del barrio: cielo, pasto,
## El Tanque y Monti; título, una explicación breve y un botón "Iniciar" con play.
## 100% procedural. Al iniciar carga el juego (main.tscn).

const CharacterArt = preload("res://scripts/art/character_art.gd")
const TanqueArt = preload("res://scripts/art/tanque_art.gd")

const INK := Color("241008")        # tinta oscura (texto del botón, contornos)
const BTN := Color("e8802a")        # acento único: naranja (como El Tanque)
const BTN_DK := Color("a8531a")     # sombra/hundido del botón
const TITLE_SHADOW := Color("22406e")

# Fuente de píxeles 8-bit PROPIA (5x7) para el título — dibujada por código, sin assets.
const WORDMARK := "TINYMONT"
const GLYPHS := {
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	"N": ["#...#", "##..#", "##..#", "#.#.#", "#..##", "#..##", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
}

var _t := 0.0
var _pressed := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # anima la respiración de Monti


func _button_rect() -> Rect2:
	var w := size.x
	var bw := 118.0
	return Rect2((w - bw) / 2.0, size.y - 46.0, bw, 30.0)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var horizon := h * 0.58

	# --- Cielo + nubes (arriba del título, para no tapar el texto) ---
	draw_rect(Rect2(0, 0, w, h), Pal.SKY)
	_cloud(w * 0.18, 11, 0.72)
	_cloud(w * 0.82, 8, 0.6)

	# --- Pasto ---
	draw_rect(Rect2(0, horizon, w, h - horizon), Pal.GRASS)
	draw_rect(Rect2(0, horizon, w, 2), Pal.GRASS_DK)
	for i in range(9):
		var gx := 12.0 + i * (w - 24.0) / 8.0
		draw_rect(Rect2(gx, horizon + 8 + (i % 3) * 6, 1, 5), Pal.GRASS_DK)

	# Los personajes se paran SOBRE el pasto (un poco debajo del horizonte).
	var ground := horizon + 32.0

	# --- El Tanque (landmark, derecha) ---
	TanqueArt.draw_on(self, w * 0.72, ground, 0.6)

	# --- Monti (izquierda), con respiración ---
	var st = CharacterArt.anim_state(_t, {
		respira = true, respira_amp = 1.0, respira_vel = 2.0,
		parpadea = true, parpadeo_cada = 4.0,
	}, false, 0.0)
	var s := 3.0
	CharacterArt.draw_on(self, CharacterArt.map_rects(CharacterArt.PROTAG, st),
		Vector2(w * 0.30 - 8 * s, ground - 18 * s - st.bob * s), s)

	# --- Título 8-bit (wordmark procedural, sin assets) ---
	# Centrado verticalmente entre las nubes y el cartel de explicación.
	_draw_wordmark(w / 2.0, 24)

	# --- Explicación en un CARTEL estilo estación del Roca ---
	var font := ThemeDB.fallback_font
	if font:
		var desc := "Sos Monti, el recien llegado a Monte Grande. Recorre la ciudad, cumple las misiones ayudando a la comunidad y ganate tu lugar como Montegrandense."
		var panel := Rect2(10, 56, w - 20, 60)
		_draw_cartel(panel)
		# Texto centrado vertical y horizontalmente dentro del cartel
		var fs := 7
		var tw := panel.size.x - 16.0
		var ts := font.get_multiline_string_size(desc, HORIZONTAL_ALIGNMENT_CENTER, tw, fs)
		var ty := panel.position.y + (panel.size.y - ts.y) / 2.0 + font.get_ascent(fs)
		draw_multiline_string(font, Vector2(panel.position.x + 8, ty), desc,
			HORIZONTAL_ALIGNMENT_CENTER, tw, fs, -1, Color("f2ead1"))

	# --- Botón Iniciar (foco de acción) ---
	_draw_button(font)


# Título 8-bit: dibuja "TINYMONT" con la fuente de píxeles propia (sombra + relleno).
func _draw_wordmark(cx: float, top: float) -> void:
	var sc := 3.4
	var gw := 6.0   # 5 de ancho + 1 de gap
	var total := WORDMARK.length() * gw * sc - sc
	var x0 := cx - total / 2.0
	_wordmark_pass(x0 + sc, top + sc, sc, gw, TITLE_SHADOW)   # sombra
	_wordmark_pass(x0, top, sc, gw, Color("fdf6e3"))          # relleno crema


func _wordmark_pass(x0: float, top: float, sc: float, gw: float, col: Color) -> void:
	var x := x0
	for ch in WORDMARK:
		var g = GLYPHS.get(ch)
		if g:
			for row in range(7):
				for c in range(5):
					if g[row][c] == "#":
						draw_rect(Rect2(x + c * sc, top + row * sc, sc, sc), col)
		x += gw * sc


# Cartel esmaltado estilo estación del Roca: campo verde ferroviario, doble
# marco crema y remaches en las esquinas.
func _draw_cartel(r: Rect2) -> void:
	var green := Color("123f1e")
	var frame := Color("d8cba0")
	draw_rect(Rect2(r.position.x, r.position.y + 3, r.size.x, r.size.y), Color(0, 0, 0, 0.18))  # sombra
	draw_rect(r, green)
	draw_rect(r, frame, false, 2.0)          # marco exterior
	draw_rect(r.grow(-4), frame, false, 1.0)  # línea interior
	for c in [Vector2(6, 6), Vector2(r.size.x - 6, 6), Vector2(6, r.size.y - 6), Vector2(r.size.x - 6, r.size.y - 6)]:
		draw_circle(r.position + c, 1.5, frame)  # remaches


func _cloud(cx: float, cy: float, sc: float) -> void:
	var c := Color("f2f6ff")
	draw_rect(Rect2(cx - 12 * sc, cy - 3 * sc, 24 * sc, 7 * sc), c)
	draw_rect(Rect2(cx - 7 * sc, cy - 7 * sc, 16 * sc, 7 * sc), c)
	draw_rect(Rect2(cx + 4 * sc, cy - 5 * sc, 9 * sc, 5 * sc), c)


func _draw_button(font: Font) -> void:
	var r := _button_rect()
	var down := 3.0 if _pressed else 0.0
	# Sombra (profundidad)
	draw_rect(Rect2(r.position.x, r.position.y + 3, r.size.x, r.size.y), BTN_DK)
	# Cuerpo (se hunde al apretar)
	var body := Rect2(r.position.x, r.position.y + down, r.size.x, r.size.y)
	draw_rect(body, BTN.darkened(0.12) if _pressed else BTN)
	draw_rect(body, INK, false, 2.0)
	# Triángulo de play + etiqueta (nudge óptico +1)
	var cy := body.get_center().y
	var tx := body.position.x + 26
	draw_colored_polygon(PackedVector2Array([
		Vector2(tx, cy - 7), Vector2(tx, cy + 7), Vector2(tx + 11, cy),
	]), INK)
	if font:
		draw_string(font, Vector2(tx + 18, cy + 5), "INICIAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)


# ==================== INPUT ====================

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var is_press: bool = event.pressed
		if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
			return
		if is_press:
			_pressed = _button_rect().grow(6).has_point(event.position)
			queue_redraw()
		else:
			if _pressed and _button_rect().grow(6).has_point(event.position):
				_start()
			_pressed = false
			queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z]:
			_start()


func _start() -> void:
	set_process_input(false)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
