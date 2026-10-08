class_name EstiloMapa
extends RefCounted
## Estilo del mapa en tiempo real (ADR-0004, enmienda 2026-10-08): mañana, tarde o noche
## según la hora actual de Argentina (UTC-3, sin horario de verano desde 2009).
## Se calcula desde la hora UTC del sistema: un jugador en otro país ve la hora de Monte Grande.
## El clima se suma como un segundo tinte multiplicativo (por ahora sólo "despejado").

const UTC_ARGENTINA := -3.0

const ESTILOS := {
	"manana": Color(1.0, 0.96, 0.88),    # luz fresca y cálida
	"tarde": Color(1.0, 0.9, 0.78),      # sol de tarde, más dorado
	"noche": Color(0.55, 0.6, 0.85),     # azul nocturno, se sigue viendo
}

## Climas futuros: lluvia, nublado, tormenta... cada uno multiplica el estilo base.
const CLIMAS := {
	"despejado": Color.WHITE,
}

## [hora del cambio, estilo anterior, estilo siguiente]. Cada cambio dura una hora (±30 min).
const CAMBIOS := [[6.0, "noche", "manana"], [12.0, "manana", "tarde"], [20.0, "tarde", "noche"]]
const MEDIA_TRANSICION := 0.5


## Hora decimal de Argentina (0..24) para un instante UTC en segundos Unix.
static func hora_argentina(unix_utc: float) -> float:
	return fposmod(unix_utc / 3600.0 + UTC_ARGENTINA, 24.0)


static func hora_argentina_ahora() -> float:
	return hora_argentina(Time.get_unix_time_from_system())


static func estilo_para_hora(hora: float) -> String:
	if hora >= 6.0 and hora < 12.0:
		return "manana"
	if hora >= 12.0 and hora < 20.0:
		return "tarde"
	return "noche"


## Color del mapa para una hora de Argentina y un clima; transición gradual en cada cambio.
static func tinte(hora: float, clima: String = "despejado") -> Color:
	var h := fposmod(hora, 24.0)
	var base: Color = ESTILOS[estilo_para_hora(h)]
	for c in CAMBIOS:
		var d: float = h - float(c[0])
		if absf(d) < MEDIA_TRANSICION:
			var t := (d + MEDIA_TRANSICION) / (2.0 * MEDIA_TRANSICION)
			base = (ESTILOS[c[1]] as Color).lerp(ESTILOS[c[2]], t)
	return base * CLIMAS.get(clima, Color.WHITE)
