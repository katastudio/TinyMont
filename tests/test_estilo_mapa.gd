extends Node
## Estilo del mapa en tiempo real según la hora de Argentina (UTC-3, sin horario de verano).
## Mañana / tarde / noche hoy; el clima se suma después sobre el mismo sistema.
## Correr: godot --headless --path . res://tests/test_estilo_mapa.tscn

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _lum(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b


func _ready() -> void:
	# 2026-10-08 15:00:00 UTC = 12:00 en Argentina.
	var unix_15_utc := Time.get_unix_time_from_datetime_string("2026-10-08T15:00:00")
	_check(is_equal_approx(EstiloMapa.hora_argentina(unix_15_utc), 12.0), "15:00 UTC son las 12:00 en Argentina")
	_check(is_equal_approx(EstiloMapa.hora_argentina(unix_15_utc - 13 * 3600), 23.0), "02:00 UTC son las 23:00 del día anterior en Argentina")

	_check(EstiloMapa.estilo_para_hora(8.0) == "manana", "a las 8 es de mañana")
	_check(EstiloMapa.estilo_para_hora(15.0) == "tarde", "a las 15 es de tarde")
	_check(EstiloMapa.estilo_para_hora(23.0) == "noche", "a las 23 es de noche")
	_check(EstiloMapa.estilo_para_hora(3.0) == "noche", "a las 3 es de noche")

	var noche := EstiloMapa.tinte(23.0)
	_check(_lum(noche) < 0.7 and noche.b > noche.r, "de noche el mapa es oscuro y azulado")
	_check(_lum(noche) >= 0.5, "de noche se sigue viendo")
	_check(_lum(EstiloMapa.tinte(10.0)) >= 0.9 and _lum(EstiloMapa.tinte(15.0)) >= 0.85, "de mañana y de tarde el mapa es luminoso")
	_check(not EstiloMapa.tinte(10.0).is_equal_approx(EstiloMapa.tinte(15.0)), "mañana y tarde se distinguen")
	var salto := 0.0
	for minuto in 24 * 60:
		var a := EstiloMapa.tinte(minuto / 60.0)
		var b := EstiloMapa.tinte(((minuto + 1) % (24 * 60)) / 60.0)
		salto = maxf(salto, absf(_lum(a) - _lum(b)))
	_check(salto < 0.02, "los cambios de estilo son graduales (salto máximo %.3f)" % salto)
	_check(EstiloMapa.tinte(15.0, "despejado").is_equal_approx(EstiloMapa.tinte(15.0)), "el clima despejado no altera el estilo")
	_check(EstiloMapa.CLIMAS.has("despejado"), "el sistema ya tiene lugar para climas")

	# El mapa sigue la hora real de Argentina, no el reloj del juego.
	WorldClock.set_process(false)
	WorldClock.reiniciar(1, 12)
	var m = load("res://scenes/main.tscn").instantiate()
	m.hora_real_fija = 23.0
	add_child(m)
	var tinte: CanvasModulate = m.get_node("TinteDia")
	_check(tinte.color.is_equal_approx(EstiloMapa.tinte(23.0)), "con la hora real a las 23, el mapa está de noche")
	WorldClock.avanzar(6 * 60)
	_check(tinte.color.is_equal_approx(EstiloMapa.tinte(23.0)), "el reloj del juego no cambia el estilo")
	m.hora_real_fija = 10.0
	m._actualizar_tinte()
	_check(tinte.color.is_equal_approx(EstiloMapa.tinte(10.0)), "a las 10 reales el mapa está de mañana")
	_check(m.estilo_actual() == "manana", "el mapa informa su estilo actual")
	m.queue_free()

	# Los exteriores de otros mapas también; los interiores no (están iluminados).
	var jaguel = load("res://scenes/mapas/el_jaguel.tscn").instantiate()
	var veneciana = load("res://scenes/mapas/la_veneciana.tscn").instantiate()
	_check(jaguel.exterior and not veneciana.exterior, "El Jagüel es exterior, La Veneciana es interior")
	jaguel.free()
	veneciana.free()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
