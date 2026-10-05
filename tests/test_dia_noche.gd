extends Node
## Ciclo día/noche (ADR-0004): tinte del mundo según la hora, sin teñir la interfaz.
## Correr: godot --headless --path . res://tests/test_dia_noche.tscn

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
	var mediodia := CicloDia.tinte(12 * 60)
	var medianoche := CicloDia.tinte(0)
	var atardecer := CicloDia.tinte(19 * 60)
	_check(mediodia.is_equal_approx(Color.WHITE), "al mediodía no hay tinte")
	_check(_lum(medianoche) < 0.7 and medianoche.b > medianoche.r, "a medianoche el mundo es oscuro y azulado")
	_check(atardecer.r > atardecer.b and _lum(atardecer) < 1.0, "al atardecer el tinte es cálido")
	_check(_lum(medianoche) >= 0.5, "de noche se sigue viendo (no baja de 50 % de luz)")
	# Continuidad: entre dos minutos seguidos el tinte cambia poco (sin saltos bruscos).
	var salto := 0.0
	for minuto in 24 * 60:
		var a := CicloDia.tinte(minuto)
		var b := CicloDia.tinte((minuto + 1) % (24 * 60))
		salto = maxf(salto, absf(_lum(a) - _lum(b)))
	_check(salto < 0.02, "el tinte cambia de forma gradual (salto máximo %.3f)" % salto)

	WorldClock.set_process(false)
	WorldClock.reiniciar(1, 12)
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var tinte = m.get_node_or_null("TinteDia")
	_check(tinte is CanvasModulate, "el mapa tiene un CanvasModulate para el tinte")
	_check(tinte.color.is_equal_approx(Color.WHITE), "al mediodía el mapa no está teñido")
	WorldClock.avanzar(12 * 60)
	_check(tinte.color.is_equal_approx(CicloDia.tinte(0)), "a medianoche el mapa toma el tinte nocturno")
	_check(GameManager._hud.layer != 0, "la interfaz vive en otra capa y no se tiñe")
	var hud = GameManager._hud.get_child(0)
	_check(hud.texto_hora() == WorldClock.texto_hora(), "el HUD muestra la hora del barrio (%s)" % hud.texto_hora())
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
