extends Control
## HUD de pantalla (barra superior): avatar del player + mochila + progreso.
## Es procedural (draw_rect) y se alimenta del estado de GameManager.
## Vive como hijo del GameManager (autoload) -> una sola instancia, persiste entre mapas.
## Ocupa una franja RESERVADA arriba (la cámara del mundo baja su límite para no taparse).

const CharacterArt = preload("res://scripts/art/character_art.gd")
const ItemArt = preload("res://scripts/art/item_art.gd")
const BAR_H := 24.0
const SLOTS := 5          # espacios visibles en la mochila
const SLOT := 15.0        # ancho de cada slot


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.inventario_cambiado.connect(queue_redraw)
	GameManager.mision_cambiada.connect(queue_redraw)


func _draw() -> void:
	var w := size.x

	# Fondo verde de la barra + línea de acento (enmarca el mapa por arriba)
	draw_rect(Rect2(0, 0, w, BAR_H), Pal.UI_BG)
	draw_rect(Rect2(0, BAR_H - 1, w, 1), Pal.UI_ACCENT)

	# Avatar del player (icono del juego) a la izquierda
	CharacterArt.draw_on(self, CharacterArt.map_rects(CharacterArt.PROTAG), Vector2(3, 3), 1.1)

	# Mochila: fila de slots
	var mx := 28.0
	for i in range(SLOTS):
		var r := Rect2(mx + i * SLOT, 4, SLOT - 2, 16)
		draw_rect(r, Color(0, 0, 0, 0.20))                 # hueco del slot
		draw_rect(r, Pal.UI_ACCENT, false, 1.0)            # marco verde
		if i < GameManager.inventario.size():
			ItemArt.draw_on(self, GameManager.inventario[i], r)

	# Progreso de misiones (derecha)
	var font := ThemeDB.fallback_font
	if font:
		var prog := "Misiones %d" % GameManager.misiones_completadas()
		draw_string(font, Vector2(w - 52, 16), prog,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Pal.UI_TEXT)
