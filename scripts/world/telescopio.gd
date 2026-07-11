@tool
extends Node2D
## Telescopio casero (prop del astrónomo de Plaza Mitre) — 100% procedural.
## Decorativo: identifica a Don Jorge. Bloquea su celda. Editable: arrastralo en el editor.

const T := 16

@export var color: Color = Color("8890a0"):
	set(v):
		color = v
		queue_redraw()


func _snap() -> Vector2:
	return Vector2(floor(position.x / T) * T - position.x, floor(position.y / T) * T - position.y)


func _draw() -> void:
	var o := _snap()
	var cx := o.x + T / 2.0
	var gy := o.y + T
	var dk := Color("2a2a30")
	var apex := Vector2(cx, gy - 13)

	# Trípode
	draw_line(apex, Vector2(cx - 5, gy), dk, 2.0)
	draw_line(apex, Vector2(cx + 5, gy), dk, 2.0)
	draw_line(apex, Vector2(cx + 1, gy), dk, 2.0)
	draw_rect(Rect2(apex.x - 2, apex.y - 1, 4, 3), dk)     # montura

	# Tubo apuntando al cielo (arriba-derecha)
	var lo := Vector2(cx - 3, gy - 10)
	var hi := Vector2(cx + 8, gy - 24)
	draw_line(lo, hi, color, 5.0)
	draw_line(lo, hi, color.lightened(0.28), 1.5)          # brillo
	draw_circle(lo, 1.6, dk)                               # ocular
	draw_circle(hi, 2.8, color.darkened(0.25))            # borde de la lente
	draw_circle(hi, 1.8, Color("bcd8ea"))                 # vidrio


func bloquea(tx: int, ty: int) -> bool:
	return tx == int(floor(position.x / T)) and ty == int(floor(position.y / T))
