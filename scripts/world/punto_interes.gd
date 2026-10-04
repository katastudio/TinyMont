@tool
class_name PuntoInteres
extends Node2D
## Punto de interés (spec 0010): lugar del mapa donde los NPCs satisfacen necesidades.
## Se coloca como nodo hijo de MonteGrande y se edita desde el Inspector.
## La celda de uso es la celda donde está el nodo; debe ser transitable.

@export var poi_id: String = ""
@export var nombre: String = ""
## Necesidad -> puntos de urgencia que descuenta la actividad (hambre, energia, social, ocio, deber).
@export var satisface: Dictionary = {}
@export var capacidad: int = 3
## Franja horaria preferida [hora_desde, hora_hasta). Si desde > hasta, cruza la medianoche.
@export_range(0, 24) var hora_desde: int = 0
@export_range(0, 24) var hora_hasta: int = 24
## Duración de la actividad en minutos de juego.
@export var duracion_min: int = 30

var _usuarios: Array = []


func celda() -> Vector2i:
	return Vector2i(int(position.x) / 16, int(position.y) / 16)


func lleno() -> bool:
	_usuarios = _usuarios.filter(func(u): return is_instance_valid(u))
	return _usuarios.size() >= capacidad


func entrar(quien: Object) -> void:
	if not (quien in _usuarios):
		_usuarios.append(quien)


func salir(quien: Object) -> void:
	_usuarios.erase(quien)


## Representación que consume CerebroNPC.
func como_opcion() -> Dictionary:
	return {
		"id": poi_id,
		"satisface": satisface,
		"celda": celda(),
		"desde": hora_desde,
		"hasta": hora_hasta,
		"duracion": duracion_min,
		"lleno": lleno(),
		"nodo": self,
	}


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(-6, -6, 12, 12), Color(1, 0, 1, 0.8), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-6, -8), poi_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 0, 1))
