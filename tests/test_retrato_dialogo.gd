extends Node
## Retratos en el cuadro de diálogo (roadmap C7).
## Correr: godot --headless --path . res://tests/test_retrato_dialogo.tscn

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
	var caja = GameManager.dialog_box
	_check(caja != null, "hay cuadro de diálogo")

	var tito = m.get_node("Npc12Tito")
	GameManager.start_dialog("Tito", ["Hola."], tito.camiseta, tito.retrato())
	_check(caja.retrato.visible, "con descriptor se ve el retrato")
	_check(caja.retrato.descriptor == tito.retrato(), "el retrato es el del que habla")
	_check(caja.text_label.offset_left >= 28.0, "el texto se corre a la derecha del retrato")
	GameManager.end_dialog()

	GameManager.start_dialog("Monte Grande", ["Fin."], Color.WHITE)
	_check(not caja.retrato.visible, "sin descriptor no hay retrato")
	_check(caja.text_label.offset_left < 10.0, "sin retrato el texto ocupa todo el ancho")
	GameManager.end_dialog()

	m.get_node("Trompeta").interact(Vector2.ZERO)
	_check(caja.retrato.visible and caja.retrato.descriptor == m.get_node("Player").retrato(), "al encontrar un objeto habla Monti con su retrato")
	GameManager.end_dialog()

	var fuente: String = FileAccess.get_file_as_string("res://scripts/ui/encounter_screen.gd")
	_check("_npc.retrato()" in fuente, "la pantalla de encuentro pasa el retrato del NPC al diálogo")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
