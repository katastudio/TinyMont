extends Node
## Pantalla de título: botones CONTINUAR y NUEVA PARTIDA (mismo estilo, sin superponerse).
## Correr: godot --headless --path . res://tests/test_titulo.tscn

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	GameManager.ruta_guardado = "user://test_titulo.json"
	var f := FileAccess.open(GameManager.ruta_guardado, FileAccess.WRITE)
	f.store_string("{}")
	f.close()
	var t = load("res://scenes/ui/title_screen.tscn").instantiate()
	add_child(t)
	await get_tree().process_frame
	t.size = Vector2(146, 316)   # tamaño lógico de un teléfono
	var principal: Rect2 = t._button_rect()
	var nueva: Rect2 = t._nueva_rect()
	var pantalla := Rect2(Vector2.ZERO, t.size)
	_check(t._hay_partida, "con partida guardada hay dos botones")
	_check(pantalla.encloses(principal) and pantalla.encloses(nueva), "los dos botones entran en la pantalla")
	_check(not principal.grow(2).intersects(nueva), "los botones no se pisan")
	_check(nueva.position.y > principal.end.y, "NUEVA PARTIDA va debajo de CONTINUAR")
	_check(absf(nueva.get_center().x - principal.get_center().x) < 1.0, "los dos botones están centrados")
	_check(nueva.size.y >= 18.0 and nueva.size.x >= 96.0, "NUEVA PARTIDA es un botón cómodo para el dedo")
	var mute: Control = t.get_child(0)
	_check(not Rect2(mute.position, mute.size).intersects(nueva), "no tapa el botón de sonido")
	_check(t.accion_en(principal.get_center()) == "iniciar", "tocar CONTINUAR inicia")
	_check(t.accion_en(nueva.get_center()) == "nueva", "tocar NUEVA PARTIDA arranca de cero")
	_check(t.accion_en(Vector2(2, 2)) == "", "tocar fuera no hace nada")
	t.queue_free()
	GameManager.borrar_partida()

	var t2 = load("res://scenes/ui/title_screen.tscn").instantiate()
	add_child(t2)
	await get_tree().process_frame
	t2.size = Vector2(146, 316)
	_check(not t2._hay_partida and t2.accion_en(t2._nueva_rect().get_center()) != "nueva", "sin partida no hay botón de nueva partida")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
