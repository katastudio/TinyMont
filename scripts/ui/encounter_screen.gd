extends CanvasLayer
## Pantalla de encuentro estilo Pokémon para hablar con los NPC.
## 100% procedural (_draw): personajes de cuerpo completo sobre elipses de pasto,
## menú 2x2 (HABLAR / MOCHILA / MISIONES / CHAU) con cursor, y franjas de
## transición estilo GB. Vive como hijo del GameManager (layer 8, debajo del
## diálogo que es 10: al HABLAR el textbox normal se dibuja encima).

const CharacterArt = preload("res://scripts/art/character_art.gd")
const ItemArt = preload("res://scripts/art/item_art.gd")

const FRAME := Color("14141a")
const BODY := Color("34343e")
const TEXTO := Color("ecece4")
const DORADO := Color("ffd23c")
const OPCIONES := ["HABLAR", "MOCHILA", "MISIONES", "CHAU"]
const POR_PAGINA := 4
const NOMBRES_ITEM := {
	vasitos = "Vasitos", cafecito = "Cafecito", trompeta = "Trompeta",
	pelota = "Pelota", recuerdo = "Recuerdo", microfono = "Micrófono",
	celular = "Celular", parlante = "Parlante", medalla = "Medalla",
	gato = "Mostaza", lente = "Lente",
}

var _npc = null
var _modo := "menu"      # menu | mochila | misiones | hablando | cerrando
var _col := 0            # celda seleccionada del menú 2x2
var _fila := 0
var _pagina := 0
var _blink := 0.0
var _cover := 0.0        # franjas de transición (1 = pantalla tapada)
var _fondo := Color("cfe0ff")
var _rects_npc: Array = []
var _rects_monti: Array = []
var _root: Control
var _tween: Tween
var _sb_frame: StyleBoxFlat
var _sb_inner: StyleBoxFlat


func _ready() -> void:
	layer = 8
	visible = false
	# Mismo marco doble que el diálogo (frame oscuro + cuerpo charcoal con bisel)
	_sb_frame = StyleBoxFlat.new()
	_sb_frame.bg_color = FRAME
	_sb_frame.set_corner_radius_all(6)
	_sb_frame.shadow_color = Color(0, 0, 0, 0.35)
	_sb_frame.shadow_size = 5
	_sb_frame.shadow_offset = Vector2(0, 3)
	_sb_inner = StyleBoxFlat.new()
	_sb_inner.bg_color = BODY
	_sb_inner.set_corner_radius_all(5)
	_sb_inner.border_width_top = 1
	_sb_inner.border_color = Color(1, 1, 1, 0.10)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_all)
	add_child(_root)
	GameManager.dialog_ended.connect(_on_dialog_ended)


func open(npc) -> void:
	_npc = npc
	_modo = "menu"
	_col = 0
	_fila = 0
	_pagina = 0
	_blink = 0.0
	# fondo derivado de la camiseta: cada encuentro tiene su color
	_fondo = (npc.camiseta as Color).lightened(0.55)
	_rects_npc = CharacterArt.full_rects(npc._descriptor())
	# PROTAG equivale al descriptor del player; espejado para variar la silueta
	_rects_monti = CharacterArt.flip_x(
			CharacterArt.full_rects(CharacterArt.PROTAG), CharacterArt.FULL_W)
	visible = true
	MusicManager.play_sfx("encuentro_inicio")
	MusicManager.play_music("tema_encuentro")
	_transicion(1.0, 0.0, 0.45)


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	_root.queue_redraw()


func _on_dialog_ended() -> void:
	# Al cerrar el diálogo de HABLAR vuelve el menú (también tras la victoria).
	if visible and _modo == "hablando":
		_modo = "menu"


# ==================== TRANSICIÓN (franjas estilo GB) ====================

func _transicion(desde: float, hasta: float, dur: float, fin := Callable()) -> void:
	if _tween:
		_tween.kill()
	_cover = desde
	_tween = create_tween()
	_tween.tween_property(self, "_cover", hasta, dur)
	if fin.is_valid():
		_tween.tween_callback(fin)


func _cerrar() -> void:
	_modo = "cerrando"
	_transicion(0.0, 1.0, 0.25, _al_cerrar)


func _al_cerrar() -> void:
	visible = false
	MusicManager.play_music("tema_pueblo")
	GameManager.end_encounter()


# ==================== LAYOUT ====================

# La caja inferior va en el MISMO lugar que el diálogo (bottom_reserve): al
# HABLAR, el textbox la tapa exacto. El campo es lo que queda arriba.
func _layout() -> Dictionary:
	var s: Vector2 = _root.size
	var reserve: float = GameManager.bottom_reserve(s.y)
	# En pantallas muy bajas (web mobile apaisado) la reserva táctil no entra:
	# la caja se ancla abajo aunque pise los controles (visible desde s.y >= 53).
	var box_y: float = s.y - reserve - 52.0
	if box_y < 4.0:
		box_y = maxf(4.0, s.y - 55.0)
	var box := Rect2(3.0, box_y, s.x - 6.0, 49.0)
	var top: float = GameManager.safe_top_frac() * s.y
	return {s = s, box = box, campo = Rect2(0.0, top, s.x, maxf(box.position.y - top, 0.0))}


func _celda(box: Rect2, col: int, fila: int) -> Rect2:
	return Rect2(box.end.x - 124.0 + col * 60.0, box.position.y + 7.0 + fila * 19.0, 58.0, 17.0)


func _paginas() -> int:
	return maxi(1, ceili(GameManager.inventario.size() / float(POR_PAGINA)))


# ==================== DIBUJO ====================

func _draw_all() -> void:
	if _npc == null:
		return
	var lay := _layout()
	_dibujar_fondo(lay)
	_dibujar_npc(lay)
	_dibujar_monti(lay)
	# mientras el NPC habla, el textbox (layer 10) reemplaza a la caja del menú
	if _modo != "hablando" and not GameManager.is_dialog_active:
		_dibujar_caja(lay)
	_dibujar_franjas(lay)


func _dibujar_fondo(lay: Dictionary) -> void:
	# degradé simple en 3 franjas, derivado del color del encuentro
	var s: Vector2 = lay.s
	_root.draw_rect(Rect2(0, 0, s.x, s.y), _fondo.darkened(0.45))
	_root.draw_rect(Rect2(0, s.y * 0.30, s.x, s.y * 0.30), _fondo.darkened(0.22))
	_root.draw_rect(Rect2(0, s.y * 0.60, s.x, s.y * 0.40), _fondo.darkened(0.05))


# draw_ellipse no existe: círculo escalado en Y con draw_set_transform.
func _elipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	_root.draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	_root.draw_circle(Vector2.ZERO, rx, col)
	_root.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _panel(r: Rect2) -> void:
	_root.draw_style_box(_sb_frame, r)
	_root.draw_style_box(_sb_inner, r.grow(-2.0))


func _dibujar_npc(lay: Dictionary) -> void:
	var campo: Rect2 = lay.campo
	var font := ThemeDB.fallback_font

	# elipse de pasto arriba a la derecha, con el cuerpo completo parado encima
	# (pies en el centro de la elipse; escala reducida si el campo es bajo)
	var c := Vector2(lay.s.x - 46.0, campo.position.y + minf(campo.size.y * 0.52, 118.0))
	_elipse(c, 40.0, 13.0, Pal.GRASS_DK)
	_elipse(c + Vector2(0, -1), 37.0, 11.0, Pal.GRASS)
	var esc := minf(2.4, maxf((c.y - campo.position.y - 4.0) / CharacterArt.FULL_H, 0.0))
	var o := Vector2(c.x - CharacterArt.FULL_W * 0.5 * esc, c.y - CharacterArt.FULL_H * esc)
	CharacterArt.draw_on(_root, _rects_npc, o, esc)

	# panel del NPC arriba a la izquierda: chip de camiseta + nombre + estado de misión
	var p := Rect2(4.0, campo.position.y + 6.0, 96.0, 20.0)
	_panel(p)
	_root.draw_rect(Rect2(p.position.x + 5.0, p.position.y + 6.0, 3.0, 8.0), _npc.camiseta)
	_root.draw_string(font, p.position + Vector2(11.0, 14.0), _npc.npc_name,
			HORIZONTAL_ALIGNMENT_LEFT, p.size.x - 30.0, 8, TEXTO)
	if _npc.mision_id != "":
		_icono_estado(p.position + Vector2(p.size.x - 15.0, 6.0),
				GameManager.get_estado_mision(_npc.mision_id))


func _icono_estado(pos: Vector2, estado: String) -> void:
	match estado:
		"no_iniciada":
			_root.draw_string(ThemeDB.fallback_font, pos + Vector2(2.0, 8.0), "?",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9, DORADO)
		"en_curso":
			for i in 3:
				_root.draw_rect(Rect2(pos.x + i * 3.0, pos.y + 6.0, 2.0, 2.0), DORADO)
		"completada":
			# tilde dibujado (el glifo ✓ no existe en la fuente web)
			_root.draw_line(pos + Vector2(1.0, 4.0), pos + Vector2(4.0, 7.0), Color("7ae06a"), 2.0)
			_root.draw_line(pos + Vector2(4.0, 7.0), pos + Vector2(9.0, 1.0), Color("7ae06a"), 2.0)


func _dibujar_monti(lay: Dictionary) -> void:
	var box: Rect2 = lay.box
	var font := ThemeDB.fallback_font

	# Monti abajo a la izquierda, cuerpo completo parado sobre su elipse
	# (más chico que el NPC porque está "adelante"; se achica si no entra)
	var c := Vector2(42.0, box.position.y - 6.0)
	_elipse(c, 36.0, 12.0, Pal.GRASS_DK)
	_elipse(c + Vector2(0, -1), 33.0, 10.0, Pal.GRASS)
	var campo: Rect2 = lay.campo
	var esc := minf(1.9, maxf((c.y - campo.position.y - 4.0) / CharacterArt.FULL_H, 0.0))
	var o := Vector2(c.x - CharacterArt.FULL_W * 0.5 * esc, c.y - CharacterArt.FULL_H * esc)
	CharacterArt.draw_on(_root, _rects_monti, o, esc)

	# panel de Monti abajo a la derecha: nombre + contador + mini mochila (patrón del HUD)
	var p := Rect2(lay.s.x - 100.0, box.position.y - 48.0, 96.0, 44.0)
	_panel(p)
	_root.draw_string(font, p.position + Vector2(6.0, 13.0), GameManager.jugador_nombre,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXTO)
	_root.draw_string(font, p.position + Vector2(48.0, 13.0), "Mis. %d/%d" %
			[GameManager.misiones_completadas(), GameManager.total_misiones()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, DORADO)
	for i in range(GameManager.total_misiones()):
		var r := Rect2(p.position.x + 5.0 + i * 11.0, p.position.y + 20.0, 10.0, 18.0)
		_root.draw_rect(r, Color("1a1a20"))
		_root.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1.0), Color(1, 1, 1, 0.08))
		_root.draw_rect(r, FRAME, false, 1.0)
		if i < GameManager.inventario.size():
			ItemArt.draw_on(_root, GameManager.inventario[i], r)


func _dibujar_caja(lay: Dictionary) -> void:
	var box: Rect2 = lay.box
	_panel(box)
	match _modo:
		"mochila":
			_dibujar_mochila(box)
		"misiones":
			_dibujar_misiones(box)
		_:
			_dibujar_menu(box)


func _dibujar_menu(box: Rect2) -> void:
	var font := ThemeDB.fallback_font
	_root.draw_string(font, box.position + Vector2(8.0, 18.0), "¿Qué",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXTO)
	_root.draw_string(font, box.position + Vector2(8.0, 30.0), "hacés?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXTO)
	_root.draw_rect(Rect2(box.end.x - 130.0, box.position.y + 6.0, 1.0, box.size.y - 12.0),
			Color(1, 1, 1, 0.10))
	for fila in 2:
		for col in 2:
			var r := _celda(box, col, fila)
			var sel := col == _col and fila == _fila
			_root.draw_string(font, r.position + Vector2(9.0, 12.0), OPCIONES[fila * 2 + col],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DORADO if sel else TEXTO)
			# cursor ▶ procedural parpadeante (sin glifo de fuente)
			if sel and fmod(_blink, 0.8) < 0.55:
				var q := r.position + Vector2(1.0, 5.0)
				_root.draw_colored_polygon(PackedVector2Array([
					q, q + Vector2(0.0, 7.0), q + Vector2(5.0, 3.5),
				]), TEXTO)


func _dibujar_mochila(box: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var items: Array = GameManager.inventario
	if items.is_empty():
		_root.draw_string(font, box.position + Vector2(10.0, 22.0), "La mochila está vacía.",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXTO)
		return
	for fila in 2:
		for col in 2:
			var idx := _pagina * POR_PAGINA + fila * 2 + col
			if idx >= items.size():
				break
			var cel := box.position + Vector2(8.0 + col * 92.0, 6.0 + fila * 19.0)
			ItemArt.draw_on(_root, items[idx], Rect2(cel, Vector2(13.0, 15.0)))
			_root.draw_string(font, cel + Vector2(16.0, 11.0), _nombre_item(items[idx]),
					HORIZONTAL_ALIGNMENT_LEFT, 72.0, 7, TEXTO)
	if _paginas() > 1:
		_root.draw_string(font, Vector2(box.end.x - 26.0, box.end.y - 8.0),
				"%d/%d" % [_pagina + 1, _paginas()], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, DORADO)


func _nombre_item(id: String) -> String:
	return NOMBRES_ITEM.get(id, id.capitalize())


func _dibujar_misiones(box: Rect2) -> void:
	var font := ThemeDB.fallback_font
	_root.draw_string(font, box.position + Vector2(8.0, 16.0), "Misiones completadas: %d/%d" %
			[GameManager.misiones_completadas(), GameManager.total_misiones()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXTO)
	var linea: String
	if _npc.mision_id == "":
		linea = "%s no tiene encargos." % _npc.npc_name
	else:
		match GameManager.get_estado_mision(_npc.mision_id):
			"en_curso":
				linea = "Encargo de %s: en curso." % _npc.npc_name
			"completada":
				linea = "Encargo de %s: ¡listo!" % _npc.npc_name
			_:
				linea = "%s tiene un encargo." % _npc.npc_name
	_root.draw_string(font, box.position + Vector2(8.0, 32.0), linea,
			HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 16.0, 7, TEXTO)


func _dibujar_franjas(lay: Dictionary) -> void:
	if _cover <= 0.0:
		return
	var s: Vector2 = lay.s
	var bh := s.y / 3.0
	var w := s.x * clampf(_cover, 0.0, 1.0)
	for i in 3:
		var x := 0.0 if i % 2 == 0 else s.x - w
		_root.draw_rect(Rect2(x, i * bh, w, bh + 1.0), FRAME)


# ==================== INPUT ====================
# Todo por evento y consumido con set_input_as_handled para que no llegue al
# player. Mientras el diálogo de HABLAR está abierto, el textbox (layer 10)
# maneja su propio input y acá no se toca nada.

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _modo == "cerrando" or GameManager.is_dialog_active:
		return
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_tap(event.position)
		return
	if event.is_action_pressed("menu"):
		_volver()
		get_viewport().set_input_as_handled()
		return
	match _modo:
		"menu":
			_input_menu(event)
		"mochila", "misiones":
			_input_sub(event)


# X/Escape: en el menú cierra (= CHAU); en una sub-pantalla vuelve al menú.
func _volver() -> void:
	if _modo == "menu":
		_cerrar()
	else:
		_modo = "menu"
		MusicManager.play_sfx("menu_move")


func _input_menu(event: InputEvent) -> void:
	var col := _col
	var fila := _fila
	if event.is_action_pressed("move_left"):
		col = 0
	elif event.is_action_pressed("move_right"):
		col = 1
	elif event.is_action_pressed("move_up"):
		fila = 0
	elif event.is_action_pressed("move_down"):
		fila = 1
	elif event.is_action_pressed("interact"):
		_activar(_fila * 2 + _col)
		get_viewport().set_input_as_handled()
		return
	else:
		return
	if col != _col or fila != _fila:
		_col = col
		_fila = fila
		_blink = 0.0
		MusicManager.play_sfx("menu_move")
	get_viewport().set_input_as_handled()


func _input_sub(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") and _modo == "mochila":
		_cambiar_pagina(-1)
	elif event.is_action_pressed("move_right") and _modo == "mochila":
		_cambiar_pagina(1)
	elif event.is_action_pressed("interact"):
		# A pasa de página; en la última (o en MISIONES) vuelve al menú,
		# así en touch (sin tecla X) nunca quedás encerrado.
		if _modo == "mochila" and _pagina < _paginas() - 1:
			_cambiar_pagina(1)
		else:
			_volver()
	else:
		return
	get_viewport().set_input_as_handled()


func _cambiar_pagina(d: int) -> void:
	var nueva := clampi(_pagina + d, 0, _paginas() - 1)
	if nueva != _pagina:
		_pagina = nueva
		MusicManager.play_sfx("menu_move")


func _activar(idx: int) -> void:
	match idx:
		0:  # HABLAR: máquina de misión del NPC, mostrada con el diálogo normal
			_modo = "hablando"
			GameManager.start_dialog(_npc.npc_name, _npc.dialogo_lines(), _npc.camiseta, _npc.retrato())
		1:
			_modo = "mochila"
			_pagina = 0
		2:
			_modo = "misiones"
		3:
			_cerrar()


func _tap(pos: Vector2) -> void:
	var box: Rect2 = _layout().box
	if _modo == "menu":
		for fila in 2:
			for col in 2:
				if _celda(box, col, fila).grow(4.0).has_point(pos):
					_col = col
					_fila = fila
					_activar(fila * 2 + col)
					get_viewport().set_input_as_handled()
					return
	elif box.grow(6.0).has_point(pos):
		# tocar la caja pasa de página / vuelve al menú
		if _modo == "mochila" and _pagina < _paginas() - 1:
			_cambiar_pagina(1)
		else:
			_volver()
		get_viewport().set_input_as_handled()
