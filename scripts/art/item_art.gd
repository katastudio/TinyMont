extends RefCounted
## Iconos de objetos del inventario/album, 100% procedurales (sin assets).
## Se dibujan dentro de un slot (Rect2). Crear un objeto nuevo = agregar un case.
## Se usa por preload (sin class_name) para no depender del cache global de clases.

const WHITE := Color("fcfcfc")
const BLACK := Color("181018")


## Nombre visible de cada objeto (mochila, álbum, diálogos).
const NOMBRES := {
	"vasitos": "Vasitos", "cafecito": "Cafecito de la estación", "trompeta": "Trompeta",
	"pelota": "Pelota", "recuerdo": "Recuerdo", "microfono": "Micrófono", "celular": "Celular",
	"parlante": "Parlante", "medalla": "Medalla", "gato": "Mostaza", "lente": "Lente",
	"guantes": "Guantes", "vincha": "Vincha", "bandera": "Bandera a cuadros",
	"foto_gato": "Foto de Mostaza", "partitura": "Partitura de Gille", "pelota_dorada": "Pelota dorada",
	"rima": "Rima manuscrita", "aro_de_luz": "Aro de luz", "pulsera": "Pulsera de la juntada",
	"mapa_estelar": "Mapa estelar", "pua": "Púa de madera", "cd_cumbia": "CD de cumbia",
	"portada": "Portada del diario", "corbata": "Corbata elegante", "guantes_dorados": "Guantes dorados",
	"casco": "Casco de carrera", "cadena": "Cadena brillante", "vincha_brillos": "Vincha con brillos",
	"lentes_productor": "Lentes del productor", "microfono_rosa": "Micrófono rosa",
	"entrada_baile": "Entrada al baile", "camiseta_azul_oro": "Camiseta azul y oro",
	"aviso_gille": "Respuesta de Gille", "nota_secreta": "Nota secreta", "confirmacion_juli": "Respuesta de Juli",
	"confirmacion_tiaguito": "Respuesta de Tiaguito", "respuesta_emi": "Respuesta de Emi",
	"aviso_atajatodo": "Respuesta del Atajatodo",
}
## Recados (mensajes entre vecinos): se dibujan como un sobre.
const RECADOS := ["aviso_gille", "nota_secreta", "confirmacion_juli", "confirmacion_tiaguito", "respuesta_emi", "aviso_atajatodo"]
const CON_ICONO := ["vasitos", "cafecito", "trompeta", "pelota", "recuerdo", "microfono", "celular",
	"parlante", "medalla", "gato", "lente", "guantes", "vincha", "bandera", "foto_gato", "partitura",
	"pelota_dorada", "rima", "aro_de_luz", "pulsera", "mapa_estelar", "pua", "cd_cumbia", "portada",
	"corbata", "guantes_dorados", "casco", "cadena", "vincha_brillos", "lentes_productor",
	"microfono_rosa", "entrada_baile", "camiseta_azul_oro"]


static func tiene_icono(item: String) -> bool:
	return item in CON_ICONO or item in RECADOS


static func nombre(item: String) -> String:
	return NOMBRES.get(item, item.capitalize())


static func draw_on(ci: CanvasItem, item: String, r: Rect2) -> void:
	if item in RECADOS:
		_recado(ci, r)
		return
	match item:
		"guantes":
			_guantes(ci, r, Color("2fa84f"))
		"guantes_dorados":
			_guantes(ci, r, Color("f5c518"))
		"vincha":
			_vincha(ci, r, false)
		"vincha_brillos":
			_vincha(ci, r, true)
		"bandera":
			_bandera(ci, r)
		"foto_gato":
			_foto_gato(ci, r)
		"partitura":
			_partitura(ci, r)
		"pelota_dorada":
			_pelota_dorada(ci, r)
		"rima":
			_rima(ci, r)
		"aro_de_luz":
			_aro_de_luz(ci, r)
		"pulsera":
			_pulsera(ci, r)
		"mapa_estelar":
			_mapa_estelar(ci, r)
		"pua":
			_pua(ci, r)
		"cd_cumbia":
			_cd(ci, r)
		"portada":
			_portada(ci, r)
		"corbata":
			_corbata(ci, r)
		"casco":
			_casco(ci, r)
		"cadena":
			_cadena(ci, r)
		"lentes_productor":
			_lentes_productor(ci, r)
		"microfono_rosa":
			_microfono_rosa(ci, r)
		"entrada_baile":
			_entrada(ci, r)
		"camiseta_azul_oro":
			_camiseta_azul_oro(ci, r)
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
		"medalla":
			_medalla(ci, r)
		"gato":
			_gato(ci, r)
		"lente":
			_lente(ci, r)
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


# Medalla dorada (cierre: completaste todas las misiones) con cinta celeste/blanca.
static func _medalla(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_rect(Rect2(c.x - 3, c.y - 6, 2, 5), Color("74acf0"))   # cinta celeste
	ci.draw_rect(Rect2(c.x + 1, c.y - 6, 2, 5), Color("fcfcfc"))   # cinta blanca
	var mc := c + Vector2(0, 2)
	ci.draw_circle(mc, 4.2, Color("c99a10"))                       # borde
	ci.draw_circle(mc, 3.4, Color("ffd23c"))                       # oro
	ci.draw_colored_polygon(PackedVector2Array([
		mc + Vector2(0, -2.4), mc + Vector2(0.7, -0.7), mc + Vector2(2.4, 0),
		mc + Vector2(0.7, 0.7), mc + Vector2(0, 2.4), mc + Vector2(-0.7, 0.7),
		mc + Vector2(-2.4, 0), mc + Vector2(-0.7, -0.7),
	]), Color("c99a10"))                                          # estrellita


# Gato Mostaza (misión de Doña Rosa): naranja con manchas negras.
static func _gato(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	var org := Color("e0882c")
	var dk := Color("2a2018")
	ci.draw_rect(Rect2(x + 4, y + 2, 2, 1), org)         # orejas
	ci.draw_rect(Rect2(x + 8, y + 2, 2, 1), org)
	ci.draw_rect(Rect2(x + 4, y + 3, 6, 5), org)         # cabeza
	ci.draw_rect(Rect2(x + 5, y + 5, 1, 1), dk)          # ojos
	ci.draw_rect(Rect2(x + 8, y + 5, 1, 1), dk)
	ci.draw_rect(Rect2(x + 6, y + 6, 2, 1), Color("d05858"))  # nariz
	ci.draw_rect(Rect2(x + 4, y + 8, 6, 4), org)         # cuerpo
	ci.draw_rect(Rect2(x + 7, y + 9, 2, 2), dk)          # mancha
	ci.draw_rect(Rect2(x + 10, y + 7, 1, 4), org)        # cola
	ci.draw_rect(Rect2(x + 4, y + 12, 2, 1), org)        # patas
	ci.draw_rect(Rect2(x + 8, y + 12, 2, 1), org)


# Lente de telescopio (misión del astrónomo): marco metálico + vidrio.
static func _lente(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_circle(c, 5.2, Color("707880"))              # marco
	ci.draw_circle(c, 4.2, Color("7aa8cc"))              # vidrio
	ci.draw_circle(c + Vector2(-1, -1), 1.6, Color(1, 1, 1, 0.55))  # brillo


# Fallback: caja con signo, para objetos aún sin ícono propio.
static func _generico(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 8), Color("c0a060"))
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 8), BLACK, false, 1.0)



# ==================== Objetos de la historia (spec 0008) ====================

static func _recado(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 2, y + 4, 10, 7), Color("f4ecd8"))                 # sobre
	ci.draw_rect(Rect2(x + 2, y + 4, 10, 7), Color("b8a880"), false, 1.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 2, y + 4), Vector2(x + 12, y + 4), Vector2(x + 7, y + 8)]), Color("e0d4b4"))
	ci.draw_rect(Rect2(x + 6, y + 7, 2, 2), Color("d83030"))                  # sello


static func _guantes(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var x := r.position.x
	var y := r.position.y
	for dx in [1, 7]:
		ci.draw_rect(Rect2(x + dx, y + 4, 6, 7), col)                         # palma
		ci.draw_rect(Rect2(x + dx, y + 2, 1, 3), col)                         # dedos
		ci.draw_rect(Rect2(x + dx + 2, y + 1, 1, 3), col)
		ci.draw_rect(Rect2(x + dx + 4, y + 2, 1, 3), col)
		ci.draw_rect(Rect2(x + dx, y + 10, 6, 2), WHITE)                      # puño


static func _vincha(ci: CanvasItem, r: Rect2, brillos: bool) -> void:
	var c := r.get_center()
	ci.draw_arc(c + Vector2(0, 2), 5.0, PI, TAU, 10, Color("f06aa8"), 2.0)
	if brillos:
		for p in [Vector2(-4, -1), Vector2(0, -4), Vector2(4, -1)]:
			ci.draw_rect(Rect2(c + p, Vector2(1, 1)), WHITE)


static func _bandera(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 2, y + 2, 1, 11), Color("5a5a64"))                 # mástil
	for i in 4:
		for j in 3:
			var col := BLACK if (i + j) % 2 == 0 else WHITE
			ci.draw_rect(Rect2(x + 3 + i * 2, y + 2 + j * 2, 2, 2), col)


static func _foto_gato(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 1, y + 2, 12, 11), WHITE)                          # marco de foto
	ci.draw_rect(Rect2(x + 2, y + 3, 10, 8), Color("8ec8f0"))
	ci.draw_rect(Rect2(x + 4, y + 6, 6, 5), Color("e8a030"))                  # gato
	ci.draw_rect(Rect2(x + 4, y + 5, 1, 1), Color("e8a030"))                  # orejas
	ci.draw_rect(Rect2(x + 9, y + 5, 1, 1), Color("e8a030"))


static func _partitura(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 2, y + 1, 10, 13), WHITE)
	for i in 4:
		ci.draw_rect(Rect2(x + 3, y + 3 + i * 3, 8, 1), Color("9090a0"))     # pentagrama
	ci.draw_rect(Rect2(x + 5, y + 5, 2, 2), BLACK)                            # notas
	ci.draw_rect(Rect2(x + 8, y + 8, 2, 2), BLACK)


static func _pelota_dorada(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_circle(c, 5.5, Color("a87a10"))
	ci.draw_circle(c, 4.8, Color("f5c518"))
	ci.draw_rect(Rect2(c.x - 1, c.y - 1, 2, 2), Color("a87a10"))
	ci.draw_rect(Rect2(c.x - 3, c.y - 3, 1, 1), WHITE)                        # brillo


static func _rima(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 2, y + 1, 10, 13), Color("fff6c8"))                # hoja
	for i in 4:
		ci.draw_rect(Rect2(x + 3, y + 3 + i * 3, 6 + (i % 2) * 2, 1), Color("3050c0"))  # renglones escritos
	ci.draw_rect(Rect2(x + 10, y + 9, 1, 5), Color("d83030"))                 # lápiz


static func _aro_de_luz(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center() + Vector2(0, -1)
	ci.draw_arc(c, 5.0, 0, TAU, 16, Color("fff6c8"), 2.0)
	ci.draw_rect(Rect2(c.x - 1, c.y - 2, 2, 4), Color("20202a"))              # celular al centro
	ci.draw_rect(Rect2(c.x, c.y + 5, 1, 3), Color("5a5a64"))                  # pie


static func _pulsera(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	var cols := [Color("d83030"), Color("f5c518"), Color("2fa84f"), Color("3050c0")]
	for i in 8:
		var a := TAU * i / 8.0
		ci.draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * 4.5 - Vector2(1, 1), Vector2(2, 2)), cols[i % 4])


static func _mapa_estelar(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 1, y + 2, 12, 11), Color("1c2448"))
	for p in [Vector2(3, 4), Vector2(7, 6), Vector2(10, 4), Vector2(5, 10), Vector2(10, 10)]:
		ci.draw_rect(Rect2(x + p.x, y + p.y, 1, 1), Color("fff6c8"))
	ci.draw_line(Vector2(x + 3, y + 4), Vector2(x + 7, y + 6), Color(1, 1, 1, 0.4))
	ci.draw_line(Vector2(x + 7, y + 6), Vector2(x + 10, y + 4), Color(1, 1, 1, 0.4))


static func _pua(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -4), c + Vector2(5, -4), c + Vector2(0, 6)]), Color("b0703a"))
	ci.draw_rect(Rect2(c.x - 2, c.y - 2, 3, 1), Color("d89a5a"))              # veta


static func _cd(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_circle(c, 5.5, Color("c8c8d0"))
	ci.draw_circle(c, 4.5, Color("a050d0"))                                   # etiqueta violeta
	ci.draw_circle(c, 1.2, Color("2c2c38"))


static func _portada(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 1, y + 1, 12, 13), WHITE)
	ci.draw_rect(Rect2(x + 2, y + 2, 10, 2), BLACK)                           # título
	ci.draw_rect(Rect2(x + 2, y + 5, 5, 5), Color("6ab0f0"))                  # foto
	for i in 3:
		ci.draw_rect(Rect2(x + 8, y + 5 + i * 2, 4, 1), Color("9090a0"))      # texto
	ci.draw_rect(Rect2(x + 2, y + 11, 10, 1), Color("9090a0"))


static func _corbata(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_rect(Rect2(c.x - 2, c.y - 6, 4, 2), Color("1c2448"))              # nudo
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -4), c + Vector2(2, -4), c + Vector2(3, 4), c + Vector2(0, 7), c + Vector2(-3, 4)]), Color("3050c0"))
	ci.draw_rect(Rect2(c.x - 1, c.y - 1, 1, 1), Color("8ec8f0"))              # brillo


static func _casco(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center() + Vector2(0, 1)
	ci.draw_circle(c, 5.5, Color("3050c0"))
	ci.draw_rect(Rect2(c.x - 6, c.y, 12, 6), Color(0, 0, 0, 0))
	ci.draw_rect(Rect2(c.x - 1, c.y - 2, 6, 3), Color("2c2c38"))              # visor
	ci.draw_rect(Rect2(c.x - 5, c.y - 1, 2, 1), Color("f5c518"))              # franja


static func _cadena(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center() + Vector2(0, -2)
	ci.draw_arc(c, 5.0, 0.2, PI - 0.2, 10, Color("e8e8f0"), 1.0)
	ci.draw_rect(Rect2(c.x - 2, c.y + 5, 4, 4), Color("f5c518"))              # dije
	ci.draw_rect(Rect2(c.x - 1, c.y + 6, 1, 1), WHITE)


static func _lentes_productor(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	ci.draw_rect(Rect2(c.x - 6, c.y - 2, 5, 4), BLACK)
	ci.draw_rect(Rect2(c.x + 1, c.y - 2, 5, 4), BLACK)
	ci.draw_rect(Rect2(c.x - 1, c.y - 1, 2, 1), BLACK)                        # puente
	ci.draw_rect(Rect2(c.x - 5, c.y - 1, 1, 1), Color(1, 1, 1, 0.5))          # reflejo


static func _microfono_rosa(ci: CanvasItem, r: Rect2) -> void:
	var c := Vector2(r.position.x + 7, r.position.y + 4)
	ci.draw_circle(c, 3.0, Color("f06aa8"))
	ci.draw_rect(Rect2(c.x - 3, c.y, 6, 1), Color("c04080"))
	ci.draw_rect(Rect2(c.x - 1, c.y + 3, 2, 8), Color("fcd0e4"))


static func _entrada(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 1, y + 4, 12, 7), Color("f5c518"))
	ci.draw_rect(Rect2(x + 9, y + 4, 1, 7), Color("a87a10"))                  # troquel
	ci.draw_rect(Rect2(x + 2, y + 6, 6, 1), Color("a050d0"))
	ci.draw_rect(Rect2(x + 2, y + 8, 4, 1), Color("a050d0"))


static func _camiseta_azul_oro(ci: CanvasItem, r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	ci.draw_rect(Rect2(x + 3, y + 3, 8, 10), Color("1c3c9c"))                 # cuerpo
	ci.draw_rect(Rect2(x + 1, y + 3, 2, 4), Color("1c3c9c"))                  # mangas
	ci.draw_rect(Rect2(x + 11, y + 3, 2, 4), Color("1c3c9c"))
	ci.draw_rect(Rect2(x + 3, y + 7, 8, 2), Color("f5c518"))                  # franja oro
