extends Node
## Test unitario del cerebro de utilidad (CerebroNPC), sin escena.
## Correr: godot --headless --path . res://tests/test_cerebro_npc_unit.tscn

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _cerebro(semilla: int = 7) -> CerebroNPC:
	var c := CerebroNPC.new()
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	c.rng = r
	return c


func _poi(id: String, satisface: Dictionary, celda := Vector2i(5, 5), desde := 0, hasta := 24, lleno := false) -> Dictionary:
	return {"id": id, "satisface": satisface, "celda": celda, "desde": desde, "hasta": hasta, "lleno": lleno}


func _ctx(hora := 12, dia := 0, celda := Vector2i(5, 5)) -> Dictionary:
	return {"hora": hora, "dia_semana": dia, "celda": celda}


func _ready() -> void:
	_test_hambre_elige_comida()
	_test_encaje_horario()
	_test_horario_que_cruza_medianoche()
	_test_plan_semanal_domina_en_su_ventana()
	_test_poi_lleno_se_descarta()
	_test_actualizar_y_aplicar()
	_test_cargar_ficha()
	_test_determinismo()
	_test_plan_desde_json()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _test_hambre_elige_comida() -> void:
	var c := _cerebro()
	c.necesidades = {"hambre": 95.0, "energia": 10.0, "social": 10.0, "ocio": 10.0, "deber": 10.0}
	var comida := _poi("kiosco", {"hambre": 70})
	var plaza := _poi("plaza", {"ocio": 60, "social": 40})
	var elegido := c.elegir([plaza, comida], _ctx())
	_check(elegido.get("id") == "kiosco", "con hambre alta elige el POI de comida")


func _test_encaje_horario() -> void:
	var c := _cerebro()
	c.necesidades = {"hambre": 80.0, "energia": 0.0, "social": 0.0, "ocio": 0.0, "deber": 0.0}
	c.rng = null  # sin ruido para comparar valores exactos
	var p := _poi("kiosco", {"hambre": 70}, Vector2i(5, 5), 8, 20)
	var en_horario := c.utilidad(p, _ctx(12))
	var fuera := c.utilidad(p, _ctx(23))
	_check(en_horario > 0.0, "un POI en horario tiene utilidad positiva")
	_check(fuera < en_horario * 0.5, "un POI fuera de horario queda penalizado")


func _test_horario_que_cruza_medianoche() -> void:
	_check(CerebroNPC.en_franja(23, 21, 7), "la franja 21-7 incluye las 23")
	_check(CerebroNPC.en_franja(3, 21, 7), "la franja 21-7 incluye las 3")
	_check(not CerebroNPC.en_franja(12, 21, 7), "la franja 21-7 no incluye las 12")
	_check(CerebroNPC.en_franja(0, 0, 24), "la franja 0-24 cubre todo el día")


func _test_plan_semanal_domina_en_su_ventana() -> void:
	var c := _cerebro()
	c.necesidades = {"hambre": 40.0, "energia": 30.0, "social": 30.0, "ocio": 30.0, "deber": 30.0}
	c.fuerza_rutina = 0.8
	c.plan = [{"dias": [1], "desde": 10, "hasta": 12, "poi": "cancha_bochas"}]
	var bochas := _poi("cancha_bochas", {"ocio": 80, "social": 30}, Vector2i(20, 20))
	var kiosco := _poi("kiosco", {"hambre": 70}, Vector2i(5, 5))
	var martes := c.elegir([kiosco, bochas], _ctx(11, 1, Vector2i(5, 5)))
	_check(martes.get("id") == "cancha_bochas", "el martes a las 11 el plan lleva a las bochas aunque quede lejos")
	var miercoles := c.elegir([kiosco, bochas], _ctx(11, 2, Vector2i(5, 5)))
	_check(miercoles.get("id") == "kiosco", "fuera del plan gana la necesidad cercana")


func _test_poi_lleno_se_descarta() -> void:
	var c := _cerebro()
	c.necesidades = {"hambre": 95.0, "energia": 0.0, "social": 0.0, "ocio": 0.0, "deber": 0.0}
	var lleno := _poi("kiosco", {"hambre": 70}, Vector2i(5, 5), 0, 24, true)
	var otro := _poi("mostaza", {"hambre": 50}, Vector2i(9, 9))
	_check(c.utilidad(lleno, _ctx()) == 0.0, "un POI lleno tiene utilidad cero")
	_check(c.elegir([lleno, otro], _ctx()).get("id") == "mostaza", "con el kiosco lleno elige otro lugar de comida")
	var vacio := c.elegir([lleno], _ctx())
	_check(vacio.is_empty(), "si no hay opciones útiles devuelve un diccionario vacío")


func _test_actualizar_y_aplicar() -> void:
	var c := _cerebro()
	c.necesidades = {"hambre": 10.0, "energia": 10.0, "social": 10.0, "ocio": 10.0, "deber": 10.0}
	c.decaimiento = {"hambre": 12.0, "energia": 6.0, "social": 6.0, "ocio": 6.0, "deber": 6.0}
	c.actualizar(60)
	_check(is_equal_approx(c.necesidades["hambre"], 22.0), "una hora de juego suma el decaimiento por hora")
	c.actualizar(60 * 24)
	_check(c.necesidades["hambre"] == 100.0, "la urgencia nunca supera 100")
	c.aplicar(_poi("kiosco", {"hambre": 70}))
	_check(is_equal_approx(c.necesidades["hambre"], 30.0), "aplicar la actividad reduce la urgencia")
	c.aplicar(_poi("kiosco", {"hambre": 70}))
	_check(c.necesidades["hambre"] == 0.0, "la urgencia nunca baja de 0")


func _test_cargar_ficha() -> void:
	var c := _cerebro()
	c.cargar_ficha({
		"personalidad": {"afinidad": {"hambre": 0.9, "ocio": 0.95}, "fuerza_rutina": 0.7},
		"decaimiento": {"hambre": 9.0},
		"necesidades_iniciales": {"hambre": 33.0},
		"plan_semanal": [{"dias": [1], "desde": 10, "hasta": 12, "poi": "cancha_bochas"}],
	})
	_check(is_equal_approx(c.afinidad["hambre"], 0.9), "carga afinidades de la ficha")
	_check(is_equal_approx(c.afinidad["deber"], CerebroNPC.AFINIDAD_DEFECTO), "las afinidades faltantes usan el valor por defecto")
	_check(is_equal_approx(c.fuerza_rutina, 0.7), "carga la fuerza de rutina")
	_check(is_equal_approx(c.decaimiento["hambre"], 9.0), "carga el decaimiento por hora")
	_check(is_equal_approx(c.necesidades["hambre"], 33.0), "carga las necesidades iniciales")
	_check(c.plan.size() == 1, "carga el plan semanal")


func _test_determinismo() -> void:
	var opciones := [
		_poi("a", {"ocio": 50}, Vector2i(4, 4)),
		_poi("b", {"ocio": 50}, Vector2i(6, 6)),
		_poi("c", {"ocio": 50}, Vector2i(5, 7)),
	]
	var seq1 := []
	var seq2 := []
	var c1 := _cerebro(99)
	var c2 := _cerebro(99)
	for i in 20:
		seq1.append(c1.elegir(opciones, _ctx()).get("id"))
		seq2.append(c2.elegir(opciones, _ctx()).get("id"))
	_check(seq1 == seq2, "misma semilla produce la misma secuencia de elecciones")


func _test_plan_desde_json() -> void:
	# JSON entrega todos los números como float: el plan tiene que funcionar igual.
	var ficha = JSON.parse_string('{"personalidad": {"fuerza_rutina": 0.8}, "plan_semanal": [{"dias": [0, 1], "desde": 6, "hasta": 10, "poi": "terminal"}]}')
	var c := _cerebro()
	c.cargar_ficha(ficha)
	_check(c.bonus_plan("terminal", 0, 8) > 0.0, "un plan leído de JSON activa su bonus el lunes a las 8")
	_check(c.bonus_plan("terminal", 2, 8) == 0.0, "un plan leído de JSON no aplica el miércoles")
