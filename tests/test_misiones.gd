extends Node
## Test headless de la máquina de misiones (npc.dialogo_lines):
## efectos exactamente una vez, sin duplicar items ni re-aplicar estados.
## Correr: godot --headless --path . res://tests/test_misiones.tscn
## Sale con código 1 si falla algún chequeo.

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	var NpcScript := preload("res://scripts/npc/npc.gd")

	# GIVER: encargo -> recordatorio -> entrega -> post-mision
	var g := NpcScript.new()
	g.npc_name = "TestGiver"
	g.mision_id = "test_mision"
	g.dialog_lines = ["ambiental"]
	g.dialog_encargo = ["encargo"]
	g.dialog_recordatorio = ["recordatorio"]
	g.dialog_entrega = ["entrega"]
	g.requisito_item = "test_item"
	g.recompensa_item = "test_recuerdo"

	_check(g.dialogo_lines() == ["encargo"], "giver: encarga la mision")
	_check(GameManager.get_estado_mision("test_mision") == "en_curso", "giver: estado en_curso")
	_check(g.dialogo_lines() == ["recordatorio"], "giver: recordatorio sin item")
	_check(GameManager.get_estado_mision("test_mision") == "en_curso", "giver: recordatorio no cambia estado")

	GameManager.agregar_item("test_item")
	var n_antes: int = GameManager.inventario.size()
	_check(g.dialogo_lines() == ["entrega"], "giver: entrega con item")
	_check(GameManager.get_estado_mision("test_mision") == "completada", "giver: estado completada")
	_check(not GameManager.tiene_item("test_item"), "giver: consume el requisito")
	_check(GameManager.inventario.count("test_recuerdo") == 1, "giver: da la recompensa")
	_check(GameManager.inventario.size() == n_antes, "giver: neto quita 1 / da 1")
	_check(g.dialogo_lines() == ["ambiental"], "giver: charla post-mision")
	_check(GameManager.inventario.count("test_recuerdo") == 1, "giver: NO duplica recompensa al re-hablar")

	# AYUDANTE: otorga su item una sola vez mientras la mision esta en curso
	var a := NpcScript.new()
	a.npc_name = "TestAyudante"
	a.mision_id = "test_mision2"
	a.dialog_lines = ["amb2"]
	a.dialog_recordatorio = ["llevalo"]
	a.dialog_entrega = ["toma"]
	a.otorga_item = "test_objeto"

	_check(a.dialogo_lines() == ["amb2"], "ayudante: ambiental antes de la mision")
	GameManager.set_estado_mision("test_mision2", "en_curso")
	_check(a.dialogo_lines() == ["toma"], "ayudante: otorga el item en_curso")
	_check(GameManager.inventario.count("test_objeto") == 1, "ayudante: da el item")
	_check(a.dialogo_lines() == ["llevalo"], "ayudante: recordatorio si ya lo tenes")
	_check(GameManager.inventario.count("test_objeto") == 1, "ayudante: NO duplica el item")

	g.free()
	a.free()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
