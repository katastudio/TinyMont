extends Node
## Test headless de GrillaOcupacion: reservar/liberar/mover/idempotency/conflict
## Correr: godot --headless --path . res://tests/test_grilla_ocupacion.tscn

const GrillaOcupacionScript = preload("res://scripts/world/grilla_ocupacion.gd")

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	var g = GrillaOcupacionScript.new()
	var obj1 = Object.new()
	var obj2 = Object.new()

	# Reservar
	_check(g.reservar(Vector2i(0, 0), obj1), "reservar: celda libre")
	_check(not g.esta_libre(Vector2i(0, 0)), "reservar: celda ya no está libre")
	_check(g.ocupante(Vector2i(0, 0)) == obj1, "ocupante: devuelve quien reservó")

	# Idempotencia
	_check(g.reservar(Vector2i(0, 0), obj1), "reservar: idempotente para el mismo ocupante")
	_check(not g.reservar(Vector2i(0, 0), obj2), "reservar: falla si otro ocupante intenta reservar")

	# Múltiples celdas
	_check(g.reservar(Vector2i(1, 0), obj1), "reservar: obj1 puede ocupar otra celda")
	_check(g.reservar(Vector2i(1, 1), obj2), "reservar: obj2 puede ocupar su propia celda")
	var celdas_obj1 = g.celdas_de(obj1)
	_check(celdas_obj1.size() == 2, "celdas_de: obj1 ocupa 2 celdas")
	_check(Vector2i(0, 0) in celdas_obj1, "celdas_de: (0,0) está en celdas_de(obj1)")
	_check(Vector2i(1, 0) in celdas_obj1, "celdas_de: (1,0) está en celdas_de(obj1)")

	# Liberar
	g.liberar(Vector2i(0, 0), obj1)
	_check(g.esta_libre(Vector2i(0, 0)), "liberar: celda se vuelve libre")
	_check(g.ocupante(Vector2i(0, 0)) == null, "liberar: ocupante es null después de liberar")

	# Liberar solo si es el ocupante
	g.liberar(Vector2i(1, 1), obj1)  # intenta liberar celda de obj2 con obj1
	_check(not g.esta_libre(Vector2i(1, 1)), "liberar: no libera si no es el ocupante")

	# Mover
	_check(g.mover(Vector2i(1, 0), Vector2i(2, 0), obj1), "mover: success")
	_check(g.esta_libre(Vector2i(1, 0)), "mover: libera origen")
	_check(not g.esta_libre(Vector2i(2, 0)), "mover: ocupa destino")
	_check(g.ocupante(Vector2i(2, 0)) == obj1, "mover: ocupante es obj1")

	# Mover a celda ocupada falla
	_check(not g.mover(Vector2i(2, 0), Vector2i(1, 1), obj1), "mover: falla si destino ocupado por otro")
	_check(not g.esta_libre(Vector2i(2, 0)), "mover: origen sigue ocupado si falla")
	_check(not g.esta_libre(Vector2i(1, 1)), "mover: destino sigue ocupado por obj2")

	# Mover a celda ocupada por el mismo (idempotente?)
	_check(g.mover(Vector2i(2, 0), Vector2i(2, 0), obj1), "mover: idempotente para el mismo ocupante")

	# Un ocupante liberado de memoria (ej: un objeto que el jugador levantó) no bloquea su celda.
	var efimero := Node.new()
	_check(g.reservar(Vector2i(9, 9), efimero), "reservar: objeto efímero")
	efimero.free()
	_check(g.esta_libre(Vector2i(9, 9)), "una celda cuyo ocupante ya no existe queda libre")
	_check(g.ocupante(Vector2i(9, 9)) == null, "ocupante: null si el ocupante ya no existe")
	_check(g.reservar(Vector2i(9, 9), obj2), "se puede reservar la celda del ocupante eliminado")

	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
