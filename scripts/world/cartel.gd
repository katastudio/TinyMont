@tool
extends Node2D
class_name Cartel
## Cartel de calle/lugar editable VISUALMENTE en el editor de Godot.
## Arrastralo a la posición que quieras y escribí el texto en el Inspector.
## Se dibuja igual en el editor y en el juego (WYSIWYG).

@export var texto: String = "CARTEL":
	set(value):
		texto = value
		queue_redraw()


func _draw():
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var tw := texto.length() * 4 + 4
	draw_rect(Rect2(-2, -8, tw + 2, 11), Pal.WHITE)
	draw_rect(Rect2(-3, -9, tw + 4, 13), Pal.BLACK, false, 1.0)
	draw_string(font, Vector2(0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Pal.BLACK)
