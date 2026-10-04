extends Node
## WorldClock: reloj del mundo vivo (autoload).
## Escala por defecto: 1 minuto de juego por segundo real (un día dura 24 minutos reales).
## Emite un tick lento cada INTERVALO_TICK segundos reales con los minutos transcurridos.
## El mundo sigue vivo durante diálogos y encuentros; sólo se detiene con el árbol en pausa.

signal tick(minutos_transcurridos: int)
signal hora_cambiada(hora: int)
signal dia_nuevo(dia: int)

const INTERVALO_TICK := 0.5
const MINUTOS_POR_DIA := 24 * 60
const HORA_INICIAL := 8
const DIAS := ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"]

var minutos_por_segundo: float = 1.0
var semilla: int = 20261002
var minutos: int = HORA_INICIAL * 60  # minutos de juego desde el lunes 00:00 de la semana 1
var pausado: bool = false

var _acumulado_real: float = 0.0
var _minutos_fraccion: float = 0.0


func _process(delta: float) -> void:
	if pausado:
		return
	_acumulado_real += delta
	while _acumulado_real >= INTERVALO_TICK:
		_acumulado_real -= INTERVALO_TICK
		_minutos_fraccion += INTERVALO_TICK * minutos_por_segundo
		var enteros := int(_minutos_fraccion)
		if enteros > 0:
			_minutos_fraccion -= enteros
			avanzar(enteros)


## Avanza el reloj N minutos de juego emitiendo las mismas señales que el tick real.
func avanzar(cantidad: int) -> void:
	if cantidad <= 0:
		return
	var hora_previa := hora()
	var dia_previo := dia()
	minutos += cantidad
	tick.emit(cantidad)
	if dia() != dia_previo:
		dia_nuevo.emit(dia())
	if hora() != hora_previa:
		hora_cambiada.emit(hora())


## Reinicia el reloj (tests y nueva partida).
func reiniciar(nueva_semilla: int = semilla, hora_inicio: int = HORA_INICIAL) -> void:
	semilla = nueva_semilla
	minutos = hora_inicio * 60
	_acumulado_real = 0.0
	_minutos_fraccion = 0.0


func hora() -> int:
	return (minutos / 60) % 24


func minuto() -> int:
	return minutos % 60


## Día absoluto desde el inicio (0 = primer lunes).
func dia() -> int:
	return minutos / MINUTOS_POR_DIA


## Día de la semana: 0 = lunes ... 6 = domingo.
func dia_semana() -> int:
	return dia() % 7


func nombre_dia() -> String:
	return DIAS[dia_semana()]


func texto_hora() -> String:
	return "%02d:%02d" % [hora(), minuto()]


## RNG determinístico por entidad: misma semilla e id producen la misma secuencia.
func rng_para(id: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(id) ^ semilla
	return r


## Estado serializable del reloj (F4). La semilla va como texto: JSON no preserva enteros de 64 bits.
func a_dict() -> Dictionary:
	return {"minutos": minutos, "semilla": str(semilla), "acumulado": _acumulado_real, "fraccion": _minutos_fraccion}


func desde_dict(d: Dictionary) -> void:
	minutos = int(d.get("minutos", HORA_INICIAL * 60))
	semilla = int(str(d.get("semilla", semilla)))
	_acumulado_real = float(d.get("acumulado", 0.0))
	_minutos_fraccion = float(d.get("fraccion", 0.0))
