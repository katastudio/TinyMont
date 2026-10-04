extends Control
## Pantalla de bienvenida (después del boot splash). Postal del barrio: cielo, pasto,
## El Tanque y Monti; título, una explicación breve y un botón "Iniciar" (o "Continuar"
## si hay partida guardada, con un enlace para empezar una nueva) con play.
## 100% procedural. Al iniciar carga el juego (main.tscn).

const CharacterArt = preload("res://scripts/art/character_art.gd")
const TanqueArt = preload("res://scripts/art/tanque_art.gd")
const MuteButton = preload("res://scripts/ui/mute_button.gd")

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
var _hint_sonido := false   # web: falta el primer gesto para activar el audio
var _hay_partida := false   # hay partida guardada: el botón dice CONTINUAR
var _pressed_nueva := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MusicManager.play_music("tema_titulo")
	# En web el AudioContext arranca suspendido hasta el primer gesto:
	# se muestra un hint y al primer input se reinicia el tema del título.
	_hint_sonido = OS.has_feature("web")
	_hay_partida = GameManager.has_save()
	# Botón de mute abajo a la derecha (mismo widget que el HUD).
	var mute := MuteButton.new()
	add_child(mute)
	mute.anchor_left = 1.0
	mute.anchor_top = 1.0
	mute.anchor_right = 1.0
	mute.anchor_bottom = 1.0
	mute.offset_left = -22.0
	mute.offset_top = -22.0
	mute.offset_right = -6.0
	mute.offset_bottom = -6.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # anima la respiración de Monti


func _button_rect() -> Rect2:
	var w := size.x
	var bw := 140.0 if _hay_partida else 118.0
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

	# --- Hint de sonido (solo web, hasta el primer gesto) ---
	if _hint_sonido and font:
		draw_string(font, Vector2(0, _button_rect().position.y - 8),
			"Toca para activar el sonido", HORIZONTAL_ALIGNMENT_CENTER, w, 7,
			Color(Color("f2ead1"), 0.6))


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
	# Brillo superior (glossy, mismo lenguaje que los domos de los controles)
	draw_rect(Rect2(body.position.x + 2, body.position.y + 2, body.size.x - 4, body.size.y * 0.42), Color(1, 1, 1, 0.16))
	draw_rect(body, INK, false, 2.0)
	# Triángulo de play + etiqueta (nudge óptico +1)
	var cy := body.get_center().y
	var etiqueta := "CONTINUAR" if _hay_partida else "INICIAR"
	# Triángulo (11 px) + separación (7 px) + texto, centrados en el botón.
	var ancho_texto := font.get_string_size(etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x if font else 60.0
	var tx := body.get_center().x - (18.0 + ancho_texto) / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(tx, cy - 7), Vector2(tx, cy + 7), Vector2(tx + 11, cy),
	]), INK)
	if font:
		draw_string(font, Vector2(tx + 18, cy + 5), etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	if _hay_partida and font:
		var n := _nueva_rect()
		var col := INK if not _pressed_nueva else BTN_DK
		draw_string(font, Vector2(n.position.x, n.position.y + 9), "nueva partida", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
		draw_line(Vector2(n.position.x, n.position.y + 11), Vector2(n.position.x + n.size.x, n.position.y + 11), col, 1.0)


func _nueva_rect() -> Rect2:
	return Rect2(6.0, size.y - 16.0, 62.0, 12.0)


# ==================== INPUT ====================

func _input(event: InputEvent) -> void:
	if _hint_sonido:
		_primer_gesto_web(event)
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var is_press: bool = event.pressed
		if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
			return
		if is_press:
			_pressed = _button_rect().grow(6).has_point(event.position)
			_pressed_nueva = _hay_partida and _nueva_rect().grow(4).has_point(event.position)
			queue_redraw()
		else:
			if _pressed and _button_rect().grow(6).has_point(event.position):
				_start()
			elif _pressed_nueva and _nueva_rect().grow(4).has_point(event.position):
				_nueva_partida()
			_pressed = false
			_pressed_nueva = false
			queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z]:
			_start()
		elif event.keycode == KEY_N and _hay_partida:
			_nueva_partida()


# Primer gesto en web: el AudioContext ya se reanuda solo, pero el tema venía
# sonando "mudo" — se reinicia desde el principio, siempre. Si el gesto además
# dispara INICIAR, el fade a tema_pueblo lo pisa enseguida (inofensivo).
func _primer_gesto_web(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey):
		return
	if not event.pressed:
		return
	if event is InputEventKey and event.echo:
		return
	_hint_sonido = false
	queue_redraw()
	MusicManager.restart_music("tema_titulo")


func _start() -> void:
	set_process_input(false)
	GameManager.cargar_al_iniciar = _hay_partida
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Descarta la partida guardada y arranca de cero (el reloj vuelve al lunes 8:00).
func _nueva_partida() -> void:
	GameManager.borrar_partida()
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	WorldClock.reiniciar(WorldClock.semilla)
	_hay_partida = false
	_start()
