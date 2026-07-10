@tool
extends Node2D
## Objeto buscable en el mapa: se ve, flota, y se recoge con A (entra a la mochila).
## Reusa el sistema de interacción de los NPC: al tener interact(), bloquea su celda
## y el player lo "toma" mirándolo y apretando A. Editable 100% en el editor:
## arrastralo y elegí qué objeto es (item) en el Inspector.

const ItemArt = preload("res://scripts/art/item_art.gd")

@export var item: String = "generico":
	set(v):
		item = v
		queue_redraw()
@export var nombre: String = ""   # ej: "la trompeta" -> feedback al recogerlo

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # flota (bob)


func _draw() -> void:
	var bob := sin(_t * 3.0) * 1.5
	draw_circle(Vector2(0, 7), 4.0, Color(0, 0, 0, 0.18))       # sombra en el piso
	ItemArt.draw_on(self, item, Rect2(-7, -10 + bob, 14, 14))


func interact(_player_pos: Vector2) -> void:
	GameManager.agregar_item(item)
	if nombre != "":
		GameManager.start_dialog("Monti", ["¡Encontre " + nombre + "!"], Color("547ff3"))
	queue_free()   # ya lo tenés
