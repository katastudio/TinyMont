extends Node
## Introducción con Marcos, descargo y final en la Plaza Mitre (spec 0008 §3, R5, R7).
## Correr: godot --headless --path . res://tests/test_historia.tscn

const DT := 1.0 / 60.0
const FUENTE := Vector2i(22, 33)

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	_reset()

	# Inicio libre: una partida nueva no arranca con ningún diálogo.
	var m = _mundo()
	await get_tree().process_frame
	_check(not GameManager.is_dialog_active, "partida nueva: el inicio es libre, sin diálogos")
	_check(GameManager.get_estado_mision("marcos_vasitos") == "no_iniciada", "partida nueva: ninguna misión arranca sola")

	# La historia de Marcos llega cuando el jugador le habla por primera vez.
	var marcos = m.get_node("Marcos")
	var primera: Array = marcos.dialogo_lines()
	_check(primera.size() >= 6 and "Monte Grande" in " ".join(primera), "la primera charla con Marcos cuenta la historia")
	_check(GameManager.get_estado_mision("marcos_vasitos") == "en_curso", "y le encarga la primera misión")
	var segunda: Array = marcos.dialogo_lines()
	_check(segunda.size() < primera.size() and not (primera[0] in segunda), "la presentación no se repite")
	_liberar(m)

	# Descargo en el título.
	var titulo = load("res://scenes/ui/title_screen.tscn").instantiate()
	add_child(titulo)
	_check("ficticios" in titulo.descargo() and "cariño" in titulo.descargo(), "el título muestra el descargo")
	titulo.queue_free()

	# Final: al completar el álbum, el barrio se junta en la plaza y aparece la pantalla final.
	_reset()
	m = _mundo()
	for n in m.get_children():
		n.set_process(false)
		n.set_physics_process(false)
	for id in GameManager.catalogo:
		GameManager.set_estado_mision(id, "completada")
		GameManager.agregar_item(GameManager.catalogo[id].recompensa)
	_check(GameManager._victoria, "álbum completo: victoria")
	GameManager.dialog_ended.emit()    # cierra el diálogo de la última entrega
	GameManager.end_dialog()            # cierra el aviso de la victoria
	var npcs: Array = m.get_children().filter(func(n): return "npc_name" in n)
	_check(npcs.all(func(n): return n.convocado()), "todos los vecinos van a la plaza")
	for f in 60 * 90:
		WorldClock._process(DT)
		for n in npcs:
			n._process(DT)
	var cerca := npcs.filter(func(n): var d: Vector2i = n.celda_logica() - FUENTE; return absi(d.x) + absi(d.y) <= 8).size()
	_check(cerca >= npcs.size() - 3, "el barrio está reunido en la plaza (%d de %d)" % [cerca, npcs.size()])
	_check(GameManager.final == null or not GameManager.final.visible, "la pantalla final espera a que llegue Monti")
	var p = m.get_node("Player")
	p.colocar_en(Vector2i(19, 34))
	m._revisar_llegada_a_la_fiesta()
	_check(GameManager.final != null and GameManager.final.visible, "Monti llega a la plaza: pantalla final")
	_check("vecino" in GameManager.final.texto_titulo(), "la pantalla final lo nombra vecino")
	_check("ficticios" in GameManager.final.texto_creditos(), "los créditos incluyen el descargo")
	GameManager.cerrar_final()
	_check(npcs.all(func(n): return not n.convocado()), "al cerrar el final, cada vecino vuelve a su vida")
	_liberar(m)
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _reset() -> void:
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	GameManager.flags.clear()
	GameManager._victoria = false
	GameManager.is_dialog_active = false
	WorldClock.reiniciar(5, 10)


func _mundo():
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	return m


func _liberar(m) -> void:
	remove_child(m)
	m.free()
