@tool
class_name Portal
extends Node2D
## Puerta a otro mapa (spec 0006, ADR-0005). Se coloca sobre la celda de la puerta de un
## edificio (no transitable): caminar contra ella lleva a `destino`.

@export_file("*.tscn") var destino: String = ""
@export var etiqueta: String = ""


func celda() -> Vector2i:
	return Vector2i(int(position.x) / 16, int(position.y) / 16)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-7, -7, 14, 14), Color(0.2, 0.8, 1.0, 0.8), false, 1.0)
