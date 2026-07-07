extends RefCounted
## Arte de personajes DATA-DRIVEN y 100% procedural (sin assets).
## Se usa por preload (no class_name) para no depender del caché global de clases.
##
## Cada personaje es un descriptor de rasgos (Dictionary). El MISMO descriptor
## genera el sprite del mapa (map_rects) y el retrato del diálogo (portrait_rects).
## Crear un personaje nuevo = definir datos, no dibujar a mano.
##
## Rasgos (todos opcionales, con defaults):
##   skin, hair, hair_style(short|curly|long|slick|bald)
##   hat(none|cap|fedora|beanie|headband), hat_col
##   facial(none|mustache|beard|stubble), facial_col, glasses(bool)
##   shirt, pants, shoes, mark(none|stripes|badge), mark_col
##   accessory(none|backpack), port_bg

const BLACK := Color("141018")
const WHITE := Color("fcfcfc")
const CHEEK := Color("f0a0a0")
const STRAP := Color("e8c038")


static func _norm(desc: Dictionary) -> Dictionary:
	var d := {
		skin = Color("f4c29a"), hair = Color("3a2a1a"), hair_style = "short",
		hat = "none", hat_col = Color("e03020"),
		facial = "none", facial_col = Color("2a1e12"), glasses = false,
		shirt = Color("2f56d8"), pants = Color("394a86"), shoes = Color("5a3a20"),
		mark = "none", mark_col = WHITE, accessory = "none",
		port_bg = Color("cfe0ff"),
	}
	for k in desc:
		d[k] = desc[k]
	if not desc.has("facial_col"):
		d.facial_col = (d.hair as Color).darkened(0.1)
	d.skin_sh = (d.skin as Color).darkened(0.18)
	d.shirt_sh = (d.shirt as Color).darkened(0.28)
	d.pants_sh = (d.pants as Color).darkened(0.28)
	return d


# ---- Sprite de mapa (grilla ~16x18, de frente) ----
static func map_rects(desc: Dictionary, anim := {}) -> Array:
	var d := _norm(desc)
	var r := []
	var blink: bool = anim.get("blink", false)
	var step: int = anim.get("step", 0)
	var skin: Color = d.skin
	var ssh: Color = d.skin_sh
	var hair: Color = d.hair
	var covered: bool = d.hat in ["cap", "fedora", "beanie"]

	if d.hair_style != "bald":
		r.append([4, 5, 1, 3, hair]); r.append([11, 5, 1, 3, hair])
		if not covered:
			r.append([5, 2, 6, 1, hair]); r.append([4, 3, 8, 1, hair])
			if d.hair_style == "curly":
				r.append([3, 3, 1, 2, hair]); r.append([12, 3, 1, 2, hair])
				r.append([4, 2, 1, 1, hair]); r.append([11, 2, 1, 1, hair])
			elif d.hair_style == "long":
				r.append([3, 5, 1, 6, hair]); r.append([12, 5, 1, 6, hair])
			elif d.hair_style == "slick":
				r.append([4, 2, 8, 1, hair.darkened(0.2)])

	match d.hat:
		"cap":
			r.append([5, 2, 6, 1, d.hat_col]); r.append([4, 3, 8, 1, d.hat_col])
			r.append([4, 4, 8, 1, (d.hat_col as Color).darkened(0.25)])
		"fedora":
			r.append([4, 2, 8, 1, d.hat_col]); r.append([3, 3, 10, 1, d.hat_col])
			r.append([2, 4, 12, 1, (d.hat_col as Color).darkened(0.25)])
		"beanie":
			r.append([4, 2, 8, 1, d.hat_col]); r.append([4, 3, 8, 1, d.hat_col])
			r.append([4, 4, 8, 1, (d.hat_col as Color).darkened(0.15)])
		"headband":
			r.append([4, 4, 8, 1, d.hat_col])

	r.append([5, 5, 6, 4, skin]); r.append([10, 5, 1, 4, ssh])
	if d.glasses:
		r.append([5, 6, 6, 1, BLACK])
		if blink:
			r.append([6, 6, 1, 1, ssh]); r.append([9, 6, 1, 1, ssh])
		else:
			r.append([6, 6, 1, 1, WHITE]); r.append([9, 6, 1, 1, WHITE])
	elif blink:
		r.append([6, 7, 1, 1, ssh]); r.append([9, 7, 1, 1, ssh])
	else:
		r.append([6, 6, 1, 1, BLACK]); r.append([9, 6, 1, 1, BLACK])
	r.append([8, 7, 1, 1, ssh])

	match d.facial:
		"mustache":
			r.append([6, 8, 4, 1, d.facial_col])
		"beard":
			r.append([5, 8, 6, 1, d.facial_col])
			r.append([4, 7, 1, 2, d.facial_col]); r.append([11, 7, 1, 2, d.facial_col])
		"stubble":
			r.append([6, 8, 4, 1, (d.facial_col as Color).lightened(0.15)])

	r.append([7, 9, 2, 1, ssh])
	r.append([4, 9, 1, 3, skin]); r.append([11, 9, 1, 3, skin])
	r.append([5, 9, 6, 3, d.shirt]); r.append([5, 11, 6, 1, d.shirt_sh])

	match d.mark:
		"stripes":
			r.append([6, 9, 1, 3, d.mark_col]); r.append([8, 9, 1, 3, d.mark_col])
			r.append([10, 9, 1, 3, d.mark_col])
		"badge":
			r.append([7, 10, 2, 1, d.mark_col])
	if d.accessory == "backpack":
		r.append([6, 9, 1, 3, STRAP]); r.append([9, 9, 1, 3, STRAP])

	r.append([5, 12, 6, 2, d.pants]); r.append([5, 13, 6, 1, d.pants_sh])
	var lx := 5
	var rx := 9
	if step == 1:
		lx = 4
	elif step == 2:
		rx = 10
	r.append([lx, 14, 2, 2, d.pants]); r.append([rx, 14, 2, 2, d.pants])
	r.append([lx, 16, 2, 1, d.shoes]); r.append([rx, 16, 2, 1, d.shoes])
	return r


# ---- Retrato de diálogo (grilla 24x24, primer plano) ----
static func portrait_rects(desc: Dictionary) -> Array:
	var d := _norm(desc)
	var r := []
	r.append([0, 0, 24, 24, d.port_bg])
	if d.hair_style != "bald":
		r.append([3, 5, 18, 16, d.hair])
	r.append([5, 6, 14, 15, d.skin]); r.append([16, 7, 3, 13, d.skin_sh])
	r.append([4, 12, 1, 3, d.skin_sh]); r.append([19, 12, 1, 3, d.skin_sh])

	match d.hat:
		"cap":
			r.append([3, 2, 18, 3, d.hat_col]); r.append([4, 2, 15, 1, (d.hat_col as Color).lightened(0.2)])
			r.append([2, 5, 20, 1, (d.hat_col as Color).darkened(0.25)])
		"fedora":
			r.append([4, 2, 16, 1, d.hat_col]); r.append([2, 3, 20, 2, d.hat_col])
			r.append([1, 5, 22, 1, (d.hat_col as Color).darkened(0.25)])
		"beanie":
			r.append([3, 2, 18, 4, d.hat_col])
		"headband":
			if d.hair_style != "bald":
				r.append([5, 3, 14, 3, d.hair])
			r.append([4, 7, 16, 1, d.hat_col])
		"none":
			if d.hair_style != "bald":
				r.append([5, 3, 14, 3, d.hair])
				if d.hair_style == "curly":
					r.append([4, 4, 1, 3, d.hair]); r.append([19, 4, 1, 3, d.hair]); r.append([6, 2, 12, 1, d.hair])

	r.append([7, 9, 3, 1, d.hair]); r.append([14, 9, 3, 1, d.hair])
	r.append([7, 10, 3, 2, WHITE]); r.append([14, 10, 3, 2, WHITE])
	r.append([9, 10, 1, 2, BLACK]); r.append([15, 10, 1, 2, BLACK])
	if d.glasses:
		r.append([6, 9, 5, 1, BLACK]); r.append([13, 9, 5, 1, BLACK])
		r.append([6, 10, 1, 3, BLACK]); r.append([10, 10, 1, 3, BLACK])
		r.append([13, 10, 1, 3, BLACK]); r.append([17, 10, 1, 3, BLACK])
		r.append([11, 11, 2, 1, BLACK])
	r.append([11, 12, 2, 3, d.skin_sh])
	r.append([7, 14, 1, 1, CHEEK]); r.append([16, 14, 1, 1, CHEEK])

	match d.facial:
		"mustache":
			r.append([8, 16, 8, 1, d.facial_col])
			r.append([8, 17, 3, 1, d.facial_col]); r.append([13, 17, 3, 1, d.facial_col])
		"beard":
			r.append([5, 16, 14, 5, d.facial_col])
		"stubble":
			r.append([6, 18, 12, 2, (d.facial_col as Color).lightened(0.1)])
	if d.facial != "beard":
		r.append([9, 17, 6, 1, Color("a83020")])
	return r


# ---- Estado de animación (procedural, desde el tiempo) ----
# cfg: {respira, respira_amp, respira_vel, parpadea, parpadeo_cada}
# Devuelve {bob(px vertical), blink(bool), step(0=quieto,1/2=caminando)}
static func anim_state(t: float, cfg: Dictionary, moving := false, phase := 0.0) -> Dictionary:
	var st := {bob = 0, blink = false, step = 0}
	if cfg.get("respira", true):
		st.bob = int(round(sin((t + phase) * cfg.get("respira_vel", 2.0)) * cfg.get("respira_amp", 1.0)))
	if cfg.get("parpadea", true):
		st.blink = fmod(t + phase * 1.7, cfg.get("parpadeo_cada", 4.0)) < 0.12
	if moving:
		st.step = (int(t * 8.0) % 2) + 1
		st.bob = -1 if (int(t * 8.0) % 2 == 0) else 0
	return st


# ---- Helper para dibujar durante _draw() ----
static func draw_on(ci: CanvasItem, rects: Array, origin: Vector2, s: float) -> void:
	for a in rects:
		ci.draw_rect(Rect2(origin.x + a[0] * s, origin.y + a[1] * s, a[2] * s, a[3] * s), a[4])


# ---- Descriptores predefinidos ----
# Protagonista: el recién llegado (mochila al hombro).
const PROTAG := {
	hat = "cap", hat_col = Color("e03020"), hair = Color("4a3320"),
	shirt = Color("2f56d8"), pants = Color("394a86"), accessory = "backpack",
}
