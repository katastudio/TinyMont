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
## Misión que lo desbloquea. Vacío = la deduce el mapa (la misión cuyo giver pide este item).
## Hasta que esa misión se encarga, el objeto no se ve, no se agarra y no tapa su celda.
@export var mision_id: String = ""

var _t := 0.0
var _colocado := false    # visible y registrado en la grilla


## true si el jugador ya puede encontrarlo (su misión fue encargada).
func disponible() -> bool:
	return mision_id == "" or GameManager.get_estado_mision(mision_id) != "no_iniciada"


## Aparece o desaparece según su misión. Si al aparecer su celda está ocupada, espera.
func sincronizar(mundo: Node) -> void:
	var celda: Vector2i = mundo.celda_de(position)
	if disponible():
		if not _colocado and mundo.ocupacion.reservar(celda, self):
			_colocado = true
	elif _colocado:
		mundo.ocupacion.liberar(celda, self)
		_colocado = false
	if not Engine.is_editor_hint():
		visible = _colocado


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # flota (bob)


func _draw() -> void:
	var bob := sin(_t * 3.0) * 1.5
	draw_circle(Vector2(0, 7), 4.0, Color(0, 0, 0, 0.18))       # sombra en el piso
	ItemArt.draw_on(self, item, Rect2(-7, -10 + bob, 14, 14))


func interact(_player_pos: Vector2) -> void:
	if not _colocado:
		return    # todavía nadie te pidió buscarlo
	GameManager.agregar_item(item)
	GameManager.registrar_objeto_tomado(name)
	if nombre != "":
		var monti = get_parent().get_node_or_null("Player") if get_parent() else null
		var cara: Dictionary = monti.retrato() if monti and monti.has_method("retrato") else {}
		GameManager.start_dialog("Monti", ["¡Encontre " + nombre + "!"], Color("547ff3"), cara)
	queue_free()   # ya lo tenés
