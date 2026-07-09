extends RefCounted
## Arte de LUGARES (edificios) data-driven y procedural. Se usa por preload.
##
## Un lugar es un descriptor: {w, h (en tiles), fachada, techo, cartel, tipo}.
## rects() devuelve la lista [x,y,w,h,Color] en pixeles (edificio local, 0,0 = arriba-izq).
## El "tipo" agrega un motivo distintivo (cruz de clínica, marquesina, columnas...).

const T := 16
const SKY := Color("bfe0ff")
const DOORW := Color("4a3520")


static func _norm(desc: Dictionary) -> Dictionary:
	var d := {
		w = 3, h = 2, tipo = "generico",
		fachada = Color("d8b088"), techo = Color("a04030"), cartel = Color("e03020"),
	}
	for k in desc:
		d[k] = desc[k]
	return d


static func rects(desc: Dictionary) -> Array:
	var d := _norm(desc)
	var W: int = int(d.w) * T
	var H: int = int(d.h) * T
	var wall: Color = d.fachada
	var roof: Color = d.techo
	var sign: Color = d.cartel
	var r := []

	# cuerpo + sombras
	r.append([0, 0, W, H, wall])
	r.append([0, H - 3, W, 3, wall.darkened(0.22)])
	r.append([W - 3, 6, 3, H - 6, wall.darkened(0.12)])
	# techo
	r.append([0, 0, W, 5, roof])
	r.append([0, 5, W, 1, roof.darkened(0.35)])
	# banda de cartel (marquesina)
	r.append([2, 7, W - 4, 6, sign])
	r.append([2, 13, W - 4, 1, sign.darkened(0.3)])
	# puerta centrada
	var dcx := int(W / 2.0)
	r.append([dcx - 5, H - 12, 10, 12, DOORW])
	r.append([dcx - 4, H - 11, 8, 11, Color("6a4a2a")])
	r.append([dcx - 1, H - 7, 2, 2, Color("d8c078")])
	# ventanas a los costados (si hay lugar)
	for wx in [5, W - 11]:
		if abs(wx - (dcx - 5)) >= 9 and wx >= 3 and wx + 6 <= W - 3:
			r.append([wx - 1, H - 12, 8, 8, wall.darkened(0.4)])
			r.append([wx, H - 11, 6, 6, SKY])
			r.append([wx, H - 11, 6, 1, Color("ffffff")])

	_motif(r, d, W, H)
	return r


static func _motif(r: Array, d: Dictionary, W: int, H: int) -> void:
	var cx := int(W / 2.0)
	match d.tipo:
		"clinica":
			# cruz roja sobre panel blanco
			r.append([cx - 6, 0, 12, 6, Color("f4f4f4")])
			r.append([cx - 1, 1, 2, 4, Color("e03020")])
			r.append([cx - 3, 2, 6, 2, Color("e03020")])
		"teatro":
			# luces de marquesina
			for i in range(4, W - 3, 6):
				r.append([i, 8, 2, 2, Color("fcd800")])
		"cultural":
			# columnas + frontón
			for i in range(4, W - 5, 7):
				r.append([i, 14, 3, H - 17, Color("efe7d2")])
			r.append([cx - 7, 0, 14, 2, Color("efe7d2")])
			r.append([cx - 4, 2, 8, 2, Color("efe7d2")])
			r.append([cx - 1, 4, 2, 2, Color("efe7d2")])
		"club":
			# mástil con banderín
			r.append([cx, -8, 1, 8, Color("888888")])
			r.append([cx + 1, -8, 7, 4, d.cartel])
		"comida", "fastfood", "heladeria":
			# toldo a rayas (cartel + blanco)
			var j := 0
			for i in range(2, W - 3, 5):
				r.append([i, 13, 5, 3, d.cartel if j % 2 == 0 else Color("ffffff")])
				j += 1
		"jugueteria":
			# estrellita
			r.append([cx - 1, 0, 2, 6, Color("fcd800")])
			r.append([cx - 3, 2, 6, 2, Color("fcd800")])
		_:
			pass


static func draw_on(ci: CanvasItem, rects_list: Array, origin: Vector2, s: float) -> void:
	for a in rects_list:
		ci.draw_rect(Rect2(origin.x + a[0] * s, origin.y + a[1] * s, a[2] * s, a[3] * s), a[4])
