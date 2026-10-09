extends Node
## Autoguardado frecuente: cada 10 minutos de juego y ante cada cambio importante.
## Correr: godot --headless --path . res://tests/test_autoguardado.tscn

const RUTA := "user://test_autoguardado.json"

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _borrar() -> void:
	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))


func _ready() -> void:
	WorldClock.set_process(false)
	WorldClock.reiniciar(2, 10)
	GameManager.ruta_guardado = RUTA
	GameManager.autoguardado_habilitado = true
	_borrar()
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)

	WorldClock.avanzar(5)
	_check(not FileAccess.file_exists(RUTA), "con 5 minutos de juego todavía no guarda")
	WorldClock.avanzar(5)
	_check(FileAccess.file_exists(RUTA), "a los 10 minutos de juego guarda solo")

	GameManager.set_estado_mision("gille_trompeta", "en_curso")   # la trompeta aparece al encargarse
	_borrar()
	m.get_node("Trompeta").interact(Vector2.ZERO)
	GameManager.end_dialog()
	_check(FileAccess.file_exists(RUTA), "levantar un objeto guarda")

	_borrar()
	GameManager.desbloquear_logro("ciclista")
	_check(FileAccess.file_exists(RUTA), "conseguir un logro guarda")

	_borrar()
	GameManager.set_estado_mision("rosa_gato", "en_curso")
	_check(FileAccess.file_exists(RUTA), "un cambio de misión guarda")

	_check(GameManager.has_method("_on_pagina_oculta"), "en la web guarda cuando la pestaña se oculta o se cierra")

	# Cargar una partida no la pisa con un mundo a medio restaurar.
	m.get_node("Player").colocar_en(Vector2i(10, 10))
	GameManager.save_game(m)
	remove_child(m)
	m.free()
	GameManager.cargar_al_iniciar = true
	var m2 = load("res://scenes/main.tscn").instantiate()
	add_child(m2)
	var datos := GameManager.leer_partida()
	var c: Array = datos.mundo.jugador.celda
	_check(Vector2i(int(c[0]), int(c[1])) == Vector2i(10, 10), "cargar no pisa la partida guardada")
	_check(m2.celda_de(m2.get_node("Player").position) == Vector2i(10, 10), "Monti aparece donde se guardó")
	_borrar()
	GameManager.autoguardado_habilitado = false
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
