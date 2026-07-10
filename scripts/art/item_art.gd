extends RefCounted
## Iconos de objetos del inventario/album, 100% procedurales (sin assets).
## Se dibujan dentro de un slot (Rect2). Crear un objeto nuevo = agregar un case.
## Se usa por preload (sin class_name) para no depender del cache global de clases.

const WHITE := Color("fcfcfc")
const BLACK := Color("181018")


static func draw_on(ci: CanvasItem, item: String, r: Rect2) -> void:
	match item:
		"vasitos":
			_vasitos(ci, r)
		"cafecito":
			_cafecito(ci, r)
		_:
			_generico(ci, r)


# Pila de vasitos de café (el objeto de la misión tutorial de Marcos).
static func _vasitos(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 2, y + 3, 4, 8), WHITE)
	ci.draw_rect(Rect2(x + 8, y + 4, 4, 7), Color("e4e4e8"))
	ci.draw_rect(Rect2(x + 2, y + 3, 4, 1), Color("b8b8c0"))   # bordes
	ci.draw_rect(Rect2(x + 8, y + 4, 4, 1), Color("b8b8c0"))
	ci.draw_rect(Rect2(x + 5, y + 10, 4, 1), Color("c8c8d0"))  # sombra base


# Cafecito (recuerdo que regala Marcos al completar su misión).
static func _cafecito(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 3, y + 4, 7, 7), WHITE)             # taza
	ci.draw_rect(Rect2(x + 4, y + 5, 5, 2), Color("6f4e37"))   # café
	ci.draw_rect(Rect2(x + 10, y + 5, 2, 3), WHITE)            # asa
	ci.draw_rect(Rect2(x + 5, y + 2, 1, 2), Color(1, 1, 1, 0.6))  # vapor
	ci.draw_rect(Rect2(x + 7, y + 1, 1, 2), Color(1, 1, 1, 0.5))


# Fallback: caja con signo, para objetos aún sin ícono propio.
static func _generico(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 8), Color("c0a060"))
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 8), BLACK, false, 1.0)
