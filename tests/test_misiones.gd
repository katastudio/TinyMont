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
	_test_ayudas_multiples()
	_test_requiere_completadas()
	_test_contador()
	_test_contrarreloj()
	_test_catalogo_y_victoria()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)



func _npc(nombre: String) -> Node:
	var n = preload("res://scripts/npc/npc.gd").new()
	n.npc_name = nombre
	n.dialog_lines = ["hola, soy %s" % nombre]
	return n


## Un vecino puede ayudar en varias misiones ajenas y además tener la suya.
func _test_ayudas_multiples() -> void:
	var gille = _npc("Gille2")
	gille.mision_id = "m_propia"
	gille.dialog_encargo = ["encargo propio"]
	gille.dialog_recordatorio = ["recordatorio propio"]
	gille.requisito_item = "x_propio"
	gille.ayudas = [
		{"mision": "m_salina", "item": "aviso_salina", "lineas": ["¡Decile que voy!"], "recordatorio": ["Ya te dije que voy."]},
		{"mision": "m_biza", "item": "nota_secreta", "lineas": ["La nota es un La."], "recordatorio": ["Era un La."]},
	]
	GameManager.set_estado_mision("m_salina", "en_curso")
	_check(gille.dialogo_lines() == ["¡Decile que voy!"], "ayudas: entrega el aviso de la misión de Salina")
	_check(GameManager.tiene_item("aviso_salina"), "ayudas: el jugador recibe el aviso")
	_check(gille.dialogo_lines() == ["encargo propio"], "ayudas: ya dado el aviso, sigue con su propia misión")
	GameManager.set_estado_mision("m_biza", "en_curso")
	_check(gille.dialogo_lines() == ["La nota es un La."], "ayudas: también ayuda en la misión del Biza")
	_check(GameManager.tiene_item("nota_secreta"), "ayudas: el jugador recibe la nota")
	gille.free()


## Una misión puede exigir misiones completadas antes de encargarse.
func _test_requiere_completadas() -> void:
	var juli = _npc("Juli2")
	juli.mision_id = "m_juli"
	juli.requiere_completadas = 99
	juli.dialog_bloqueada = ["Volvé cuando el barrio te conozca."]
	juli.dialog_encargo = ["¡Vamos con la entrevista!"]
	_check(juli.dialogo_lines() == ["Volvé cuando el barrio te conozca."], "previas: bloqueada sin progreso")
	_check(GameManager.get_estado_mision("m_juli") == "no_iniciada", "previas: no se encarga")
	juli.requiere_completadas = 0
	_check(juli.dialogo_lines() == ["¡Vamos con la entrevista!"], "previas: con progreso se encarga")
	juli.free()


## Repartir invitaciones: cada vecino distinto cuenta una vez; quien encarga no cuenta.
func _test_contador() -> void:
	var rodri = _npc("Rodri2")
	rodri.mision_id = "m_rodri"
	rodri.requisito_contador = 3
	rodri.linea_contacto = "¡Gracias por la invitación al show!"
	rodri.dialog_encargo = ["Repartí 3 invitaciones."]
	rodri.dialog_recordatorio = ["Te faltan invitaciones."]
	rodri.dialog_entrega = ["¡Gracias! Tomá un CD."]
	rodri.recompensa_item = "cd_cumbia"
	_check(rodri.dialogo_lines() == ["Repartí 3 invitaciones."], "contador: encarga")
	var a = _npc("VecinoA")
	var b = _npc("VecinoB")
	var c = _npc("VecinoC")
	var lineas_a: Array = a.dialogo_lines()
	_check("¡Gracias por la invitación al show!" in lineas_a, "contador: el vecino agradece la invitación")
	a.dialogo_lines()
	rodri.dialogo_lines()
	_check(GameManager.contador_de("m_rodri") == 1, "contador: repetir vecino o hablar con Rodri no suma")
	b.dialogo_lines()
	_check(rodri.dialogo_lines() == ["Te faltan invitaciones."], "contador: con 2 de 3 recuerda")
	c.dialogo_lines()
	_check(rodri.dialogo_lines() == ["¡Gracias! Tomá un CD."], "contador: con 3 entrega")
	_check(GameManager.get_estado_mision("m_rodri") == "completada" and GameManager.tiene_item("cd_cumbia"), "contador: completa y da la recompensa")
	for n in [rodri, a, b, c]:
		n.free()


## Contrarreloj: el tiempo corre sólo fuera de los diálogos, vencido se reintenta sin castigo.
func _test_contrarreloj() -> void:
	var fran = _npc("Franquito2")
	fran.mision_id = "m_fran"
	fran.limite_segundos = 10.0
	fran.requisito_item = "bandera"
	fran.recompensa_item = "casco"
	fran.dialog_encargo = ["¡Corré!"]
	fran.dialog_entrega = ["¡Llegaste!"]
	fran.dialog_recordatorio = ["¡Dale que se acaba!"]
	fran.dialogo_lines()
	_check(GameManager.tiempo_restante("m_fran") == 10.0, "reloj: arranca la cuenta al encargar")
	GameManager.is_dialog_active = true
	GameManager._process(3.0)
	_check(GameManager.tiempo_restante("m_fran") == 10.0, "reloj: en diálogo no corre")
	GameManager.is_dialog_active = false
	GameManager.agregar_item("bandera")
	GameManager._process(11.0)
	_check(GameManager.get_estado_mision("m_fran") == "no_iniciada", "reloj: vencido vuelve a no iniciada")
	_check(not GameManager.tiene_item("bandera"), "reloj: vencido se pierde el objeto del recado")
	_check(GameManager.tiempo_restante("m_fran") < 0.0, "reloj: sin cuenta activa")
	fran.dialogo_lines()
	_check(GameManager.get_estado_mision("m_fran") == "en_curso", "reloj: se puede reintentar")
	GameManager.agregar_item("bandera")
	GameManager._process(4.0)
	_check(fran.dialogo_lines() == ["¡Llegaste!"], "reloj: a tiempo se completa")
	_check(GameManager.tiempo_restante("m_fran") < 0.0, "reloj: completada, la cuenta se detiene")
	fran.free()


## El total sale del catálogo de la escena y la victoria llega al completarlo.
func _test_catalogo_y_victoria() -> void:
	var antes: Dictionary = GameManager.catalogo.duplicate()
	GameManager.catalogo = {"c1": {"giver": "A", "recompensa": "r1"}, "c2": {"giver": "B", "recompensa": "r2"}}
	GameManager.misiones.erase("c1")
	GameManager.misiones.erase("c2")
	GameManager._victoria = false
	_check(GameManager.total_misiones() == 2, "catálogo: el total sale del catálogo")
	GameManager.set_estado_mision("c1", "completada")
	_check(GameManager.misiones_completadas() == 1, "catálogo: sólo cuentan misiones del catálogo")
	_check(not GameManager._victoria, "catálogo: sin victoria a mitad de camino")
	GameManager.set_estado_mision("c2", "completada")
	_check(GameManager._victoria, "catálogo: victoria al completar el catálogo")
	GameManager.catalogo = antes
	GameManager._victoria = false
