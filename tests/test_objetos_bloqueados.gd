extends Node
## Los objetos de una misión aparecen recién cuando la misión se encarga.
## Antes no se ven, no se pueden agarrar y no tapan su celda.
## Correr: godot --headless --path . res://tests/test_objetos_bloqueados.tscn

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	for n in m.get_children():
		n.set_process(false)
		n.set_physics_process(false)

	# Cada objeto de misión conoce su misión: es lo que pide quien la encarga.
	var givers := {}
	for n in m.get_children():
		if "npc_name" in n and n.requisito_item != "":
			givers[n.requisito_item] = n
	var objetos: Array = m.get_children().filter(func(n): return n.has_method("disponible"))
	_check(objetos.size() >= 9, "hay objetos de misión en el mapa (%d)" % objetos.size())
	for o in objetos:
		var g = givers.get(o.item)
		_check(g != null and o.mision_id == g.mision_id, "%s pertenece a la misión de %s" % [o.name, g.npc_name if g else "?"])
		var c: Vector2i = m.celda_de(o.position)
		_check(not o.visible, "%s: antes del encargo no se ve" % o.name)
		_check(m.get_npc_at(o.position) == null, "%s: antes del encargo no se puede agarrar" % o.name)
		_check(m.ocupacion.ocupante(c) != o, "%s: antes del encargo no tapa su celda" % o.name)
		var antes := GameManager.inventario.size()
		o.interact(Vector2.ZERO)
		_check(GameManager.inventario.size() == antes and is_instance_valid(o), "%s: interactuar antes del encargo no hace nada" % o.name)

	# Al encargar la misión, el objeto aparece y se puede agarrar.
	var trompeta = m.get_node("Trompeta")
	var gille = givers["trompeta"]
	gille.dialogo_lines()
	_check(trompeta.visible, "con la misión encargada la trompeta aparece")
	_check(m.get_npc_at(trompeta.position) == trompeta, "y se puede agarrar")
	trompeta.interact(Vector2.ZERO)
	GameManager.end_dialog()
	_check(GameManager.tiene_item("trompeta"), "Monti la levanta")

	# Si un vecino está parado en la celda cuando se encarga, aparece cuando se corre.
	var pelota = m.get_node("Pelota")
	var c_pelota: Vector2i = m.celda_de(pelota.position)
	var tapon := Node.new()
	add_child(tapon)
	m.ocupacion.reservar(c_pelota, tapon)
	givers["pelota"].dialogo_lines()
	_check(not m.get_npc_at(pelota.position) == pelota, "con la celda ocupada todavía no se puede agarrar")
	m.ocupacion.liberar(c_pelota, tapon)
	WorldClock.avanzar(1)
	_check(pelota.visible and m.get_npc_at(pelota.position) == pelota, "cuando la celda se libera, la pelota aparece")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
