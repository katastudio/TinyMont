extends Node
## Rutinas de respaldo de spec 0009 (DEAMBULAR y PATRULLAR), hoy sin NPCs que las usen en escena.
## Correr: godot --headless --path . res://tests/test_rutinas_simples.tscn

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
	WorldClock.reiniciar(11, 8)
	var m = load("res://scenes/main.tscn").instantiate()
	var tito = m.get_node("Npc12Tito")
	var walter = m.get_node("Npc10Walter")
	tito.rutina = 1      # DEAMBULAR
	tito.radio_deambular = 2
	walter.rutina = 2    # PATRULLAR
	add_child(m)
	for n in m.get_children():
		n.set_process(false)
		n.set_physics_process(false)

	var spawn_tito: Vector2i = tito.celda_logica()
	var waypoints: Array = walter.waypoints
	_check(waypoints.size() >= 2, "Walter tiene waypoints para patrullar")
	for w in waypoints:
		_check(m.es_transitable_estatica(w), "el waypoint %s es transitable" % w)

	var celdas_tito := {}
	var visitados := {}
	var fuera_de_radio := 0
	var npcs: Array = m.get_children().filter(func(n): return "npc_name" in n)
	for f in 60 * 180:
		WorldClock._process(DT)
		for n in npcs:
			n._process(DT)
		var c: Vector2i = tito.celda_logica()
		celdas_tito[c] = true
		if maxi(absi(c.x - spawn_tito.x), absi(c.y - spawn_tito.y)) > 2:
			fuera_de_radio += 1
		var cw: Vector2i = walter.celda_logica()
		if cw in waypoints:
			visitados[cw] = true
	_check(celdas_tito.size() >= 3, "Tito deambula por al menos 3 celdas (%d)" % celdas_tito.size())
	_check(fuera_de_radio == 0, "Tito nunca sale de su radio de 2 celdas")
	_check(visitados.size() == waypoints.size(), "Walter recorre todos sus waypoints (%d de %d)" % [visitados.size(), waypoints.size()])
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
