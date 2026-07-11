@tool
extends Node2D
## Bicicleta estacionada (100% procedural). Colocala cerca de la estación.
## Monti se sube/baja con el botón B (ver player.gd). NO bloquea su celda:
## el jugador puede pararse encima para tomarla. Editable: color.

const T := 16
const BiciArt = preload("res://scripts/art/bici_art.gd")

@export var color: Color = Color("d83030"):
	set(v):
		color = v
		queue_redraw()

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # animación idle (leve balanceo + rayos vivos)


func _snap_off() -> Vector2:
	return Vector2(floor(position.x / T) * T - position.x, floor(position.y / T) * T - position.y)


func _draw() -> void:
	var o := _snap_off()
	var base := Vector2(o.x + T / 2.0, o.y + T - 2)
	var idle := sin(_t * 2.0) * 0.6                     # balanceo suave
	BiciArt.draw_on(self, base + Vector2(0, idle), _t * 0.8, color)


func es_bici() -> bool:
	return true


func tile() -> Vector2i:
	return Vector2i(int(floor(position.x / T)), int(floor(position.y / T)))
