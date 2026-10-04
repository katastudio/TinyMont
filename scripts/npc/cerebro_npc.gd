class_name CerebroNPC
extends RefCounted
## Cerebro de utilidad de un NPC (spec 0010, ADR-0003). Lógica pura, sin escena.
##
## Cada necesidad es una URGENCIA entre 0 (satisfecha) y 100 (urgente) que crece con
## el tiempo según `decaimiento` (puntos por hora de juego). Para cada opción (un POI
## representado como diccionario) se calcula:
##
##   utilidad = (Σ urgencia² × afinidad × satisface × encaje_horario × factor_distancia
##               + bonus_plan) × ruido
##
## La urgencia al cuadrado hace que una necesidad apremiante domine sobre varias leves.
## El bonus del plan semanal hace que la rutina personal gane dentro de su ventana horaria.
##
## Formato de una opción: {id, satisface: {necesidad: 0..100}, celda: Vector2i,
##                         desde: int, hasta: int, lleno: bool}
## Formato del contexto:  {hora: int, dia_semana: int, celda: Vector2i}

const NECESIDADES := ["hambre", "energia", "social", "ocio", "deber"]
const AFINIDAD_DEFECTO := 0.5
const DECAIMIENTO_DEFECTO := 5.0
const URGENCIA_INICIAL := 30.0
const PENALIZACION_FUERA_DE_HORARIO := 0.25
const PESO_PLAN := 1.5
const ESCALA_DISTANCIA := 12.0
const RUIDO := 0.05

var necesidades: Dictionary = {}
var afinidad: Dictionary = {}
var decaimiento: Dictionary = {}
var plan: Array = []
var fuerza_rutina: float = 0.5
var rng: RandomNumberGenerator = null


func _init() -> void:
	for n in NECESIDADES:
		necesidades[n] = URGENCIA_INICIAL
		afinidad[n] = AFINIDAD_DEFECTO
		decaimiento[n] = DECAIMIENTO_DEFECTO


func cargar_ficha(ficha: Dictionary) -> void:
	var personalidad: Dictionary = ficha.get("personalidad", {})
	var afin: Dictionary = personalidad.get("afinidad", {})
	var dec: Dictionary = ficha.get("decaimiento", {})
	var ini: Dictionary = ficha.get("necesidades_iniciales", {})
	for n in NECESIDADES:
		afinidad[n] = clampf(float(afin.get(n, AFINIDAD_DEFECTO)), 0.0, 1.0)
		decaimiento[n] = maxf(0.0, float(dec.get(n, DECAIMIENTO_DEFECTO)))
		necesidades[n] = clampf(float(ini.get(n, URGENCIA_INICIAL)), 0.0, 100.0)
	fuerza_rutina = clampf(float(personalidad.get("fuerza_rutina", 0.5)), 0.0, 1.0)
	plan = []
	for e in ficha.get("plan_semanal", []):
		# JSON entrega los números como float: se normalizan a int para comparar días y horas.
		var dias: Array = []
		for d in e.get("dias", []):
			dias.append(int(d))
		plan.append({"dias": dias, "desde": int(e.get("desde", 0)), "hasta": int(e.get("hasta", 24)), "poi": str(e.get("poi", ""))})


## Hace crecer las urgencias según los minutos de juego transcurridos.
func actualizar(minutos: int) -> void:
	var horas := minutos / 60.0
	for n in NECESIDADES:
		necesidades[n] = minf(100.0, necesidades[n] + decaimiento[n] * horas)


## Aplica el efecto de completar la actividad de una opción.
func aplicar(opcion: Dictionary) -> void:
	var satisface: Dictionary = opcion.get("satisface", {})
	for n in satisface:
		if necesidades.has(n):
			necesidades[n] = maxf(0.0, necesidades[n] - float(satisface[n]))


## Devuelve la opción de mayor utilidad, o {} si ninguna es útil.
func elegir(opciones: Array, contexto: Dictionary) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_valor := 0.0
	for op in opciones:
		var valor := utilidad(op, contexto)
		if valor > mejor_valor:
			mejor_valor = valor
			mejor = op
	return mejor


func utilidad(opcion: Dictionary, contexto: Dictionary) -> float:
	if opcion.get("lleno", false):
		return 0.0
	var hora: int = contexto.get("hora", 12)
	var dia: int = contexto.get("dia_semana", 0)

	var satisface: Dictionary = opcion.get("satisface", {})
	var por_necesidad := 0.0
	for n in satisface:
		if necesidades.has(n):
			var urgencia: float = necesidades[n] / 100.0
			por_necesidad += urgencia * urgencia * afinidad[n] * float(satisface[n]) / 100.0

	var encaje := 1.0
	if not en_franja(hora, int(opcion.get("desde", 0)), int(opcion.get("hasta", 24))):
		encaje = PENALIZACION_FUERA_DE_HORARIO

	var origen: Vector2i = contexto.get("celda", Vector2i.ZERO)
	var destino: Vector2i = opcion.get("celda", origen)
	var distancia := float(absi(destino.x - origen.x) + absi(destino.y - origen.y))
	# La rutina es un compromiso: su bonus no se descuenta por distancia.
	var valor := por_necesidad * encaje / (1.0 + distancia / ESCALA_DISTANCIA) \
		+ bonus_plan(str(opcion.get("id", "")), dia, hora)
	if valor <= 0.0:
		return 0.0

	if rng:
		valor *= rng.randf_range(1.0 - RUIDO, 1.0 + RUIDO)
	return valor


## Bonus por el plan semanal: la fuerza de la rutina si hay una entrada activa para ese POI.
func bonus_plan(poi_id: String, dia: int, hora: int) -> float:
	for entrada in plan:
		if str(entrada.get("poi", "")) != poi_id:
			continue
		var dias: Array = entrada.get("dias", [])
		if not dias.is_empty() and not (dia in dias):
			continue
		if en_franja(hora, int(entrada.get("desde", 0)), int(entrada.get("hasta", 24))):
			return fuerza_rutina * PESO_PLAN
	return 0.0


## true si `hora` cae en [desde, hasta). Si desde > hasta, la franja cruza la medianoche.
static func en_franja(hora: int, desde: int, hasta: int) -> bool:
	if desde == hasta:
		return false
	if desde < hasta:
		return hora >= desde and hora < hasta
	return hora >= desde or hora < hasta
