extends Node
## Rodeo de obstáculos dinámicos: si un vecino quieto tapa el camino, se recalcula esquivándolo.
## Correr: godot --headless --path . res://tests/test_rodeo.tscn

const DT := 1.0 / 60.0

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	for n in m.get_children():
		n.set_process(false)
		n.set_physics_process(false)
	# Camino recto por la fila 41 (toda transitable): un bloqueo en el medio obliga a rodear.
	var desde := Vector2i(5, 41)
	var hasta := Vector2i(12, 41)
	var recto: Array = m.camino(desde, hasta)
	_check(recto.size() == 7 and Vector2i(8, 41) in recto, "sin obstáculos el camino es recto")
	var bloqueo := Node.new()
	add_child(bloqueo)
	m.ocupacion.reservar(Vector2i(8, 41), bloqueo)
	var rodeo: Array = m.camino(desde, hasta, true)
	_check(not rodeo.is_empty() and not (Vector2i(8, 41) in rodeo), "esquivando ocupadas el camino rodea el bloqueo")
	_check(rodeo.back() == hasta, "el rodeo llega al mismo destino")
	_check(m.camino(desde, hasta) == recto, "el A* queda como estaba: la ocupación no se le pega")

	# Un NPC con el paso tapado rodea y llega en vez de abandonar.
	var tito = m.get_node("Npc12Tito")
	tito.rutina = 2    # PATRULLAR hacia un único punto: destino controlado, sin cerebro
	var puntos: Array[Vector2i] = [hasta]
	tito.waypoints = puntos
	tito._celda_spawn = desde
	m.ocupacion.liberar(tito.celda_logica(), tito)
	tito._celda_actual = desde
	tito.global_position = m.pos_de(desde)
	m.ocupacion.reservar(desde, tito)
	tito._camino = m.camino(desde, hasta)
	tito._indice_camino = 0
	tito._estado = 2   # CAMINANDO
	for f in 60 * 20:
		tito._process(DT)
		if tito.celda_logica() == hasta:
			break
	_check(tito.celda_logica() == hasta, "el vecino rodea el bloqueo y llega (%s)" % tito.celda_logica())
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
