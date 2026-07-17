extends Control
## HUD de pantalla (barra superior): avatar del player + mochila + progreso.
## Es procedural (draw_rect) y se alimenta del estado de GameManager.
## Vive como hijo del GameManager (autoload) -> una sola instancia, persiste entre mapas.
## Barra sólida ARRIBA del mapa: la cámara del mundo reserva esta franja (limit_top).

const CharacterArt = preload("res://scripts/art/character_art.gd")
const ItemArt = preload("res://scripts/art/item_art.gd")
const BAR_H := 24.0
const SLOT := 12.0        # ancho de cada slot (los slots = una por misión, GameManager.TOTAL_MISIONES)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.inventario_cambiado.connect(queue_redraw)
	GameManager.mision_cambiada.connect(queue_redraw)


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

	# Mochila: fila de slots (uno por misión total), con relieve inset
	var mx := 24.0
	for i in range(GameManager.TOTAL_MISIONES):
		var r := Rect2(mx + i * SLOT, 4 + top, SLOT - 2, 16)
		draw_rect(r, Color("1a1a20"))                                          # hueco oscuro
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), Color(1, 1, 1, 0.08))  # highlight
		draw_rect(r, Color("14141a"), false, 1.0)                             # borde
		if i < GameManager.inventario.size():
			ItemArt.draw_on(self, GameManager.inventario[i], r)

	# Progreso de misiones (derecha). Al completar todas -> medalla + "¡Completo!".
	var font := ThemeDB.fallback_font
	if font:
		var comp := GameManager.misiones_completadas()
		var total := GameManager.TOTAL_MISIONES
		if comp >= total:
			ItemArt.draw_on(self, "medalla", Rect2(w - 60, 3 + top, 14, 16))
			draw_string(font, Vector2(w - 44, 15 + top), "¡Completo!",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("ffd23c"))
		else:
			draw_string(font, Vector2(w - 58, 16 + top), "Misiones %d/%d" % [comp, total],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("ecece4"))
