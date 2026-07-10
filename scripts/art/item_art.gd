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
		"trompeta":
			_trompeta(ci, r)
		"pelota":
			_pelota(ci, r)
		"recuerdo":
			_recuerdo(ci, r)
		"microfono":
			_microfono(ci, r)
		"celular":
			_celular(ci, r)
		"parlante":
			_parlante(ci, r)
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


# Trompeta (misión de Gille): tubo dorado + campana.
static func _trompeta(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	var gold := Color("f5c518")
	var gold_dk := Color("c99a10")
	ci.draw_rect(Rect2(x + 2, y + 6, 8, 3), gold)         # tubo
	ci.draw_rect(Rect2(x + 9, y + 4, 3, 7), gold)         # campana
	ci.draw_rect(Rect2(x + 11, y + 3, 1, 9), gold_dk)     # borde campana
	ci.draw_rect(Rect2(x + 4, y + 4, 1, 2), gold_dk)      # pistones
	ci.draw_rect(Rect2(x + 6, y + 4, 1, 2), gold_dk)
	ci.draw_rect(Rect2(x + 1, y + 6, 1, 3), gold_dk)      # boquilla


# Pelota de fútbol (misión de El Diez).
static func _pelota(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_circle(c, 5.5, Color("30302a"))
	ci.draw_circle(c, 4.8, WHITE)
	ci.draw_rect(Rect2(c.x - 1, c.y - 1, 2, 2), Color("30302a"))    # gajos
	ci.draw_rect(Rect2(c.x - 4, c.y + 1, 2, 2), Color("30302a"))
	ci.draw_rect(Rect2(c.x + 2, c.y - 3, 2, 2), Color("30302a"))


# Recuerdo (estrellita dorada que se gana al completar una misión).
static func _recuerdo(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -6), c + Vector2(1.5, -1.5), c + Vector2(6, 0), c + Vector2(1.5, 1.5),
		c + Vector2(0, 6), c + Vector2(-1.5, 1.5), c + Vector2(-6, 0), c + Vector2(-1.5, -1.5),
	]), Color("ffd23c"))


# Micrófono (misión de Tiaguito): cabeza metálica + mango.
static func _microfono(ci: CanvasItem, r: Rect2) -> void:
	var c := Vector2(r.position.x + 7, r.position.y + 4)
	ci.draw_circle(c, 3.0, Color("b8b8c0"))                        # cabeza (grille)
	ci.draw_rect(Rect2(c.x - 3, c.y, 6, 1), Color("70707a"))       # banda
	ci.draw_rect(Rect2(c.x - 1, c.y + 3, 2, 8), Color("2a2a30"))   # mango
	ci.draw_rect(Rect2(c.x - 1, c.y + 10, 2, 1), Color("5a5a64"))  # base


# Celular (misión de La Coqueta): cuerpo + pantalla.
static func _celular(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 4, y + 2, 6, 11), Color("20202a"))      # cuerpo
	ci.draw_rect(Rect2(x + 5, y + 3, 4, 7), Color("6ab0f0"))       # pantalla
	ci.draw_rect(Rect2(x + 6, y + 11, 2, 1), Color("50505a"))      # botón


# Parlante (misión de Chuchu): caja + cono + tweeter.
static func _parlante(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 2, y + 3, 10, 9), Color("3a2a1a"))      # caja
	ci.draw_rect(Rect2(x + 2, y + 3, 10, 9), Color("18120c"), false, 1.0)
	ci.draw_circle(Vector2(x + 7, y + 8), 2.6, Color("18181a"))    # cono
	ci.draw_circle(Vector2(x + 7, y + 8), 1.0, Color("60606a"))
	ci.draw_circle(Vector2(x + 4, y + 5), 1.0, Color("18181a"))    # tweeter


# Fallback: caja con signo, para objetos aún sin ícono propio.
static func _generico(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 8), Color("c0a060"))
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 8), BLACK, false, 1.0)
