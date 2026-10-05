class_name GrillaOcupacion extends RefCounted
## Grilla de ocupación: diccionario O(1) de celdas ocupadas.
## API: reservar, liberar, ocupante, esta_libre, mover, celdas_de.

var _grilla: Dictionary = {}  # Vector2i -> Object (el ocupante)


func reservar(celda: Vector2i, quien: Object) -> bool:
	"""Reserva una celda. Devuelve true si se pudo (celda libre o ya ocupada por quien).
	Devuelve false si está ocupada por otro."""
	_purgar(celda)
	if _grilla.has(celda):
		return _grilla[celda] == quien
	_grilla[celda] = quien
	return true


func liberar(celda: Vector2i, quien: Object) -> void:
	"""Libera una celda, pero solo si está ocupada por quien."""
	if _grilla.get(celda) == quien:
		_grilla.erase(celda)


func ocupante(celda: Vector2i):
	"""Devuelve el ocupante de una celda, o null si está libre."""
	_purgar(celda)
	return _grilla.get(celda)


func esta_libre(celda: Vector2i) -> bool:
	"""Devuelve true si la celda está desocupada."""
	_purgar(celda)
	return not _grilla.has(celda)


func _purgar(celda: Vector2i) -> void:
	"""Una celda cuyo ocupante fue liberado de memoria (ej: un objeto levantado) queda libre."""
	if _grilla.has(celda) and not is_instance_valid(_grilla[celda]):
		_grilla.erase(celda)


func mover(desde: Vector2i, hacia: Vector2i, quien: Object) -> bool:
	"""Mueve un ocupante: reserva 'hacia', luego libera 'desde'.
	Devuelve true si tuvo éxito, false si 'hacia' está ocupada por otro."""
	if not reservar(hacia, quien):
		return false
	liberar(desde, quien)
	return true


func celdas_ocupadas() -> Array:
	"""Todas las celdas con un ocupante vivo."""
	return _grilla.keys().filter(func(c): return is_instance_valid(_grilla[c]))


func celdas_de(quien: Object) -> Array[Vector2i]:
	"""Devuelve todas las celdas ocupadas por 'quien'."""
	var result: Array[Vector2i] = []
	for celda in _grilla:
		if _grilla[celda] == quien:
			result.append(celda)
	return result
