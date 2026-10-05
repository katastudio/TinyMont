extends Node
## Diálogos por humor (spec 0010 §6, dialogos_por_humor): el ánimo sale de las necesidades.
## Correr: godot --headless --path . res://tests/test_humor.tscn

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	WorldClock.reiniciar(3, 8)
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var tito = m.get_node("Npc12Tito")
	var ficha: Dictionary = tito._ficha
	var casos := {
		"hambriento": {"hambre": 90.0, "energia": 10.0, "social": 10.0, "ocio": 10.0, "deber": 10.0},
		"cansado": {"hambre": 10.0, "energia": 90.0, "social": 10.0, "ocio": 10.0, "deber": 10.0},
		"aburrido": {"hambre": 10.0, "energia": 10.0, "social": 10.0, "ocio": 90.0, "deber": 10.0},
		"solo": {"hambre": 10.0, "energia": 10.0, "social": 90.0, "ocio": 10.0, "deber": 10.0},
		"contento": {"hambre": 5.0, "energia": 5.0, "social": 5.0, "ocio": 5.0, "deber": 5.0},
	}
	for humor in casos:
		tito._cerebro.necesidades = casos[humor].duplicate()
		_check(tito.humor() == humor, "con %s el humor es %s (es %s)" % [casos[humor], humor, tito.humor()])
		var propias: Array = ficha.get("dialogos_por_humor", {}).get(humor, [])
		_check(not propias.is_empty(), "la ficha de Tito tiene líneas para %s" % humor)
		var lineas: Array = tito.dialogo_lines()
		_check(lineas.any(func(l): return l in propias), "Tito dice una línea de %s" % humor)
	# Neutral: ninguna necesidad alta ni todas bajas, no agrega línea de humor.
	tito._cerebro.necesidades = {"hambre": 50.0, "energia": 50.0, "social": 50.0, "ocio": 50.0, "deber": 50.0}
	_check(tito.humor() == "", "con necesidades medias no hay humor marcado")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
