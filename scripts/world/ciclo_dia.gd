class_name CicloDia
extends RefCounted
## Tinte del mundo según la hora (ADR-0004). Interpola entre momentos clave del día.
## Se aplica con un CanvasModulate en el mapa: la interfaz (CanvasLayers) no se tiñe.

const NOCHE := Color(0.55, 0.6, 0.85)
const AMANECER := Color(0.95, 0.8, 0.85)
const ATARDECER := Color(1.0, 0.82, 0.65)

## [minuto del día, color]. El último cierra el ciclo con el mismo color que el primero.
const CLAVES := [
	[0, NOCHE],
	[5 * 60, NOCHE],
	[6 * 60 + 30, AMANECER],
	[8 * 60, Color.WHITE],
	[17 * 60 + 30, Color.WHITE],
	[19 * 60, ATARDECER],
	[20 * 60 + 30, NOCHE],
	[24 * 60, NOCHE],
]


static func tinte(minuto_del_dia: int) -> Color:
	var m := posmod(minuto_del_dia, 24 * 60)
	for i in range(CLAVES.size() - 1):
		var a: Array = CLAVES[i]
		var b: Array = CLAVES[i + 1]
		if m >= a[0] and m <= b[0]:
			var t := float(m - a[0]) / float(maxi(1, b[0] - a[0]))
			return (a[1] as Color).lerp(b[1], t)
	return Color.WHITE
