extends Control
## HUD de pantalla (barra superior): avatar del player + mochila + progreso.
## Es procedural (draw_rect) y se alimenta del estado de GameManager.
## Vive como hijo del GameManager (autoload) -> una sola instancia, persiste entre mapas.
## Barra sólida ARRIBA del mapa: la cámara del mundo reserva esta franja (limit_top).

const CharacterArt = preload("res://scripts/art/character_art.gd")
const ItemArt = preload("res://scripts/art/item_art.gd")
const MuteButton = preload("res://scripts/ui/mute_button.gd")
const BAR_H := 24.0
const SLOT := 12.0        # ancho de cada slot (los slots = una por misión, GameManager.total_misiones())

var _mute: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.inventario_cambiado.connect(queue_redraw)
	GameManager.mision_cambiada.connect(queue_redraw)
	_mute = MuteButton.new()
	add_child(_mute)
	resized.connect(_ubicar_mute)
	_ubicar_mute()


# Botón de mute dentro de la barra, a la izquierda del contador de misiones.
func _ubicar_mute() -> void:
	var top := GameManager.safe_top_frac() * size.y
	_mute.position = Vector2(size.x - 78, 4 + top)


func _draw() -> void:
	var w := size.x
	# safe area: bajamos el contenido para que el notch/cámara no lo tape.
	var top := GameManager.safe_top_frac() * size.y
	var bar_h := top + BAR_H

	# Barra sólida charcoal ARRIBA del mapa (cubre también la franja del notch) + borde/highlight
	draw_rect(Rect2(0, 0, w, bar_h), Color("2c2c38"))
	draw_rect(Rect2(0, bar_h - 1, w, 1), Color("14141a"))     # borde inferior
	draw_rect(Rect2(0, 0, w, 1), Color(1, 1, 1, 0.08))        # highlight superior

	# Avatar del player (icono del juego) a la izquierda
	CharacterArt.draw_on(self, CharacterArt.map_rects(CharacterArt.PROTAG), Vector2(3, 3 + top), 1.1)

	# Mochila: lo que Monti lleva encima (las recompensas viven en el álbum).
	# Con una contrarreloj en curso, la cuenta regresiva ocupa ese lugar.
	var mx := 24.0
	var cuenta := texto_cuenta()
	var font := ThemeDB.fallback_font
	if cuenta != "" and font:
		var parpadeo := fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.7
		draw_string(font, Vector2(mx, 16 + top), "Tiempo " + cuenta, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
				Color("ff6a5a") if parpadeo else Color("ecece4"))
	else:
		var lugares := int(maxf(0.0, (w - 24.0 - 110.0) / SLOT))
		var lleva := mochila()
		for i in range(mini(lugares, maxi(lleva.size(), 3))):
			var r := Rect2(mx + i * SLOT, 4 + top, SLOT - 2, 16)
			draw_rect(r, Color("1a1a20"))
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), Color(1, 1, 1, 0.08))
			draw_rect(r, Color("14141a"), false, 1.0)
			if i < lleva.size():
				ItemArt.draw_on(self, lleva[i], r)

	# Hora del barrio, a la izquierda del botón de mute.
	if font:
		draw_string(font, Vector2(w - 104, 15 + top), texto_hora(), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("ecece4"))

	# Botón del álbum (derecha). Al completarlo -> medalla + "¡Completo!".
	var b := boton_album_rect()
	draw_rect(b, Color("3a3a48"))
	draw_rect(b, Color("14141a"), false, 1.0)
	if font:
		var comp := GameManager.misiones_completadas()
		var total := GameManager.total_misiones()
		if comp >= total:
			ItemArt.draw_on(self, "medalla", Rect2(b.position.x + 1, b.position.y, 14, 16))
			draw_string(font, b.position + Vector2(16, 11), "¡Completo!", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("ffd23c"))
		else:
			draw_string(font, b.position + Vector2(4, 11), "Álbum %d/%d" % [comp, total],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("ecece4"))


func texto_hora() -> String:
	return WorldClock.texto_hora()


## Objetos que lleva encima: el inventario sin las recompensas del catálogo.
func mochila() -> Array:
	var premios := {}
	for id in GameManager.catalogo:
		premios[str(GameManager.catalogo[id].recompensa)] = true
	return GameManager.inventario.filter(func(it): return not premios.has(it))


func boton_album_rect() -> Rect2:
	var top := GameManager.safe_top_frac() * size.y
	return Rect2(size.x - 58, 4 + top, 54, 16)


## Cuenta regresiva de la contrarreloj más urgente ("m:ss"), o "" si no hay ninguna.
func texto_cuenta() -> String:
	if GameManager.cuentas.is_empty():
		return ""
	var minimo := INF
	for id in GameManager.cuentas:
		minimo = minf(minimo, float(GameManager.cuentas[id].restante))
	var seg := ceili(maxf(0.0, minimo))
	return "%d:%02d" % [seg / 60, seg % 60]


func _process(_delta: float) -> void:
	queue_redraw()   # cuenta regresiva y reloj del barrio


## Tocar el botón del álbum lo abre (mobile; en teclado: X o Tab).
func _input(event: InputEvent) -> void:
	if not visible or GameManager.album_abierto or GameManager.is_dialog_active or GameManager.is_encounter_active:
		return
	var toque: bool = (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed
	if toque and boton_album_rect().grow(4).has_point(event.position):
		GameManager.abrir_album()
		get_viewport().set_input_as_handled()
