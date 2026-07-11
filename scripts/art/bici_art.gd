extends RefCounted
## Bicicleta en vista lateral — 100% procedural. Compartida por el nodo Bicicleta
## (estacionada) y el jugador (montado, cuando anda). Se usa por preload (sin class_name).
## base  = punto medio del suelo entre las ruedas; se dibuja hacia arriba.
## phase = fase de rotación (ruedas + pedal); mayor al andar, lenta en reposo.
## facing = dirección del frente: derecha (normal), izquierda (espejada),
##          arriba/abajo (rotada 90°) para que la trompa apunte hacia donde va.

const TIRE := Color("242028")
const RIM := Color("d8d8e0")
const SEAT := Color("201510")


static func _rueda(ci: CanvasItem, c: Vector2, r: float, phase: float) -> void:
	ci.draw_circle(c, r, TIRE)                    # cubierta
	ci.draw_circle(c, r - 1.0, Color("6a6a76"))   # llanta interior
	for i in 3:
		var a: float = phase + i * (TAU / 3.0)
		var d := Vector2(cos(a), sin(a)) * (r - 1.2)
		ci.draw_line(c - d, c + d, RIM, 1.0)      # rayos
	ci.draw_circle(c, 1.0, RIM)                   # maza


# Dibuja la bici alrededor del origen (0,0). La orientación la aplica draw_on
# con una transformación, así el mismo dibujo sirve para las 4 direcciones.
static func _cuerpo(ci: CanvasItem, phase: float, col: Color) -> void:
	var r := 3.6
	var lw := Vector2(-6, -r)    # rueda trasera
	var rw := Vector2(6, -r)     # rueda delantera (la "trompa")
	var bb := Vector2(-1, -r)    # eje de pedales
	var st := Vector2(-3, -11)   # asiento
	var hb := Vector2(7, -12)    # manubrio
	var dk := col.darkened(0.3)

	# cuadro (tubos)
	ci.draw_line(lw, bb, col, 1.5)     # vaina inferior
	ci.draw_line(lw, st, col, 1.5)     # tija trasera
	ci.draw_line(bb, st, col, 1.5)     # tubo de asiento
	ci.draw_line(bb, hb, col, 1.5)     # tubo diagonal
	ci.draw_line(st, hb, col, 1.5)     # tubo superior
	ci.draw_line(hb, rw, dk, 1.5)      # horquilla

	# manubrio + asiento
	ci.draw_line(hb + Vector2(-1, 1), hb + Vector2(3, -1), dk, 1.5)
	ci.draw_line(st + Vector2(-2, -1), st + Vector2(2, -1), SEAT, 2.0)

	# biela / pedales (giran con la fase)
	var pa := Vector2(cos(phase), sin(phase)) * 2.4
	ci.draw_line(bb, bb + pa, dk, 1.2)
	ci.draw_line(bb, bb - pa, dk, 1.2)

	# ruedas (encima de las uniones del cuadro)
	_rueda(ci, lw, r, phase)
	_rueda(ci, rw, r, phase)


# Vista cenital (para arriba/abajo): dibujada con la trompa hacia -y (arriba).
# Para "abajo" se espeja en y. Se dibuja alrededor del origen.
static func _cuerpo_vertical(ci: CanvasItem, phase: float, col: Color) -> void:
	var dk := col.darkened(0.3)
	ci.draw_line(Vector2(0, -8), Vector2(0, 6), col, 2.0)    # cuadro (largo de la bici)
	ci.draw_rect(Rect2(-2, 3, 4, 3), SEAT)                   # asiento (atrás)
	ci.draw_line(Vector2(-5, -8), Vector2(5, -8), dk, 2.0)   # manubrio (adelante)
	_rueda(ci, Vector2(0, -9), 3.0, phase)                   # rueda delantera
	_rueda(ci, Vector2(0, 6), 3.0, phase)                    # rueda trasera


static func draw_on(ci: CanvasItem, base: Vector2, phase: float, col: Color, facing := Vector2.RIGHT) -> void:
	if facing == Vector2.UP or facing == Vector2.DOWN:
		# vista cenital; canónica = trompa hacia arriba. "abajo" espeja en y.
		var fy := 1.0 if facing == Vector2.UP else -1.0
		ci.draw_set_transform(base, 0.0, Vector2(1.0, fy))
		_cuerpo_vertical(ci, phase, col)
	else:
		# vista lateral; trompa hacia +x. "izquierda" espeja en x.
		var flip := -1.0 if facing == Vector2.LEFT else 1.0
		ci.draw_set_transform(base, 0.0, Vector2(flip, 1.0))
		_cuerpo(ci, phase, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)   # restaurar
