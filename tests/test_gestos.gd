extends Node
## Gestos puntuales de los NPCs (roadmap C8): saltito y saludo.
## Correr: godot --headless --path . res://tests/test_gestos.tscn

const DT := 1.0 / 60.0

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var tito = m.get_node("Npc12Tito")
	tito.set_process(false)

	_check(tito.gesto_actual() == "", "sin gesto al empezar")
	tito.gesto("saltito")
	_check(tito.gesto_actual() == "saltito", "arranca el saltito")
	var max_salto := 0.0
	for i in 30:
		tito._process(DT)
		max_salto = maxf(max_salto, tito.altura_gesto())
	_check(max_salto >= 2.0, "el saltito despega al menos 2 px (%.1f)" % max_salto)
	for i in 60:
		tito._process(DT)
	_check(tito.gesto_actual() == "" and tito.altura_gesto() == 0.0, "el saltito termina y vuelve al piso")

	tito.gesto("bailar_tango")
	_check(tito.gesto_actual() == "", "un gesto desconocido se ignora")

	# Disparadores
	var rosa = m.get_node("Npc05DonaRosa")
	rosa.set_process(false)
	rosa.interact(m.get_node("Player").global_position)
	_check(rosa.gesto_actual() == "saludo", "al hablarle, el vecino saluda")
	GameManager.end_encounter()
	GameManager.set_estado_mision(rosa.mision_id, "en_curso")
	GameManager.agregar_item(rosa.requisito_item)
	rosa.dialogo_lines()
	_check(rosa.gesto_actual() == "saltito", "al completar su misión, salta de alegría")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
