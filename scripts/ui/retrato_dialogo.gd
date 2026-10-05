extends Control
## Retrato del que habla en el cuadro de diálogo (roadmap C7).
## Dibuja CharacterArt.portrait_rects (grilla 24x24) a escala 1 con un marco fino.

const CharacterArt = preload("res://scripts/art/character_art.gd")
const LADO := 24.0

var descriptor: Dictionary = {}:
	set(v):
		descriptor = v
		queue_redraw()


func _draw() -> void:
	if descriptor.is_empty():
		return
	draw_rect(Rect2(0, 0, LADO + 2, LADO + 2), Color("14141a"))
	CharacterArt.draw_on(self, CharacterArt.portrait_rects(descriptor), Vector2(1, 1), 1.0)
