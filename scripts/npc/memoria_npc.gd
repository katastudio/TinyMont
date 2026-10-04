class_name MemoriaNPC
extends RefCounted
## Memoria de un NPC (spec 0010, F3): hechos que conoce y relaciones con otros.
## Lógica pura, sin escena. Serializable para el guardado (F4).
##
## Un hecho es {texto, minuto, fuente, propio}: `minuto` es el minuto de juego en que lo
## aprendió, `fuente` quién se lo contó y `propio` marca los hechos semilla de su ficha,
## que nunca se olvidan. Los rumores ajenos se olvidan tras DIAS_DE_MEMORIA días de juego.

const DIAS_DE_MEMORIA := 3
const MINUTOS_POR_DIA := 24 * 60

var hechos: Array = []
var relaciones: Dictionary = {}


func sembrar(textos: Array, minuto: int, quien: String) -> void:
	for t in textos:
		if not conoce(str(t)):
			hechos.append({"texto": str(t), "minuto": minuto, "fuente": quien, "propio": true})


func conoce(texto: String) -> bool:
	for h in hechos:
		if h.texto == texto:
			return true
	return false


## Agrega un hecho si no lo conocía. Devuelve true si es nuevo.
func aprender(texto: String, minuto: int, fuente: String) -> bool:
	if conoce(texto):
		return false
	hechos.append({"texto": texto, "minuto": minuto, "fuente": fuente, "propio": false})
	return true


func olvidar_viejos(minuto_actual: int) -> void:
	var limite := minuto_actual - DIAS_DE_MEMORIA * MINUTOS_POR_DIA
	hechos = hechos.filter(func(h): return h.propio or h.minuto >= limite)


func relacion_con(nombre: String) -> int:
	return int(relaciones.get(nombre, 0))


func ajustar_relacion(nombre: String, delta: int) -> void:
	relaciones[nombre] = relacion_con(nombre) + delta


## El hecho más reciente que `otra` no conoce, o {} si no hay novedades para contarle.
func novedad_para(otra: MemoriaNPC) -> Dictionary:
	var mejor: Dictionary = {}
	for h in hechos:
		if otra.conoce(h.texto):
			continue
		if mejor.is_empty() or h.minuto >= mejor.minuto:
			mejor = h
	return mejor


## El rumor ajeno más reciente (para contarle al jugador), o {}.
func ultimo_rumor_ajeno() -> Dictionary:
	var mejor: Dictionary = {}
	for h in hechos:
		if h.propio:
			continue
		if mejor.is_empty() or h.minuto >= mejor.minuto:
			mejor = h
	return mejor


## Charla entre dos NPCs: cada uno cuenta su novedad más reciente y la relación sube.
## Devuelve cuántos hechos se aprendieron en total.
static func charlar(a: MemoriaNPC, nombre_a: String, b: MemoriaNPC, nombre_b: String, minuto: int) -> int:
	var de_a := a.novedad_para(b)
	var de_b := b.novedad_para(a)
	var aprendidos := 0
	if not de_a.is_empty() and b.aprender(de_a.texto, minuto, nombre_a):
		aprendidos += 1
	if not de_b.is_empty() and a.aprender(de_b.texto, minuto, nombre_b):
		aprendidos += 1
	a.ajustar_relacion(nombre_b, 1)
	b.ajustar_relacion(nombre_a, 1)
	return aprendidos


func a_dict() -> Dictionary:
	return {"hechos": hechos.duplicate(true), "relaciones": relaciones.duplicate()}


static func desde_dict(datos: Dictionary) -> MemoriaNPC:
	var m := MemoriaNPC.new()
	for h in datos.get("hechos", []):
		m.hechos.append({"texto": str(h.texto), "minuto": int(h.minuto), "fuente": str(h.fuente), "propio": bool(h.propio)})
	for k in datos.get("relaciones", {}):
		m.relaciones[str(k)] = int(datos.relaciones[k])
	return m
