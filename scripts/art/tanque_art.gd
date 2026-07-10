extends RefCounted
## El Tanque de Monte Grande (torre de agua tipo hongo, con mural de fuego) — 100% procedural.
## Landmark del barrio. cx = centro X, ground = Y del suelo (base); se dibuja hacia arriba.
## Se usa por preload (sin class_name). Compartido por el mapa y la pantalla de título.

const RECTS := [
	[-12, -56, 24, 56, Color("d86a2c")],   # columna (mural)
	[-12, -36, 10, 36, Color("c0281c")],
	[-3, -46, 7, 46, Color("f5c518")],
	[5, -32, 8, 32, Color("c0281c")],
	[-1, -22, 5, 22, Color("201510")],
	[-9, -54, 7, 12, Color("2a8c7a")],
	[-12, -56, 24, 2, Color("8a5a2a")],
	[-18, -62, 36, 6, Color("8a6238")],    # embudo (se ensancha)
	[-26, -68, 52, 6, Color("9a7444")],
	[-34, -74, 68, 6, Color("a8845a")],
	[-40, -80, 80, 6, Color("b98f5a")],
	[-40, -92, 80, 12, Color("c9a877")],   # copa (tanque)
	[-40, -82, 80, 2, Color("7c5a34")],
	[-35, -92, 70, 3, Color("d8bf95")],
	[-30, -89, 3, 5, Color("6a4a28")],     # letra O
	[28, -89, 3, 5, Color("6a4a28")],      # letra S
	[-1, -98, 2, 6, Color("444444")],      # antena
	[-13, -3, 26, 3, Color("2a1e14")],     # base
]


static func draw_on(ci: CanvasItem, cx: float, ground: float, s := 1.0) -> void:
	for a in RECTS:
		ci.draw_rect(Rect2(cx + a[0] * s, ground + a[1] * s, a[2] * s, a[3] * s), a[4])
