extends Node
## Regresión: con fundido real, mantener apretado contra una puerta dispara la transición
## en cada frame. Antes se cargaban dos interiores al entrar y la pantalla quedaba en negro
## al salir. Debe haber una sola transición a la vez y la pantalla debe volver a verse.
## Correr: godot --headless --path . res://tests/test_transicion.tscn

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _esperar(segundos: float) -> void:
	var fin := Time.get_ticks_msec() + int(segundos * 1000)
	while Time.get_ticks_msec() < fin:
		await get_tree().process_frame


func _secundarios() -> int:
	return get_children().filter(func(n): return n is MapaSecundario).size()


func _ready() -> void:
	WorldClock.set_process(false)
	GameManager.transicion_inmediata = false
	GameManager.forzar_fundido = true      # fundido real aunque sea headless
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var p = m.get_node("Player")
	var puerta = m.portales().filter(func(x): return "veneciana" in x.destino)[0]
	var vereda: Vector2i = puerta.celda() + Vector2i(0, 1)
	p.colocar_en(vereda)

	# Entrar con la flecha apretada: varios intentos durante el fundido.
	for i in 5:
		p.intentar_paso(Vector2.UP)
		await get_tree().process_frame
	await _esperar(1.0)
	_check(_secundarios() == 1, "se carga un solo interior (%d)" % _secundarios())
	_check(GameManager.mapa_secundario != null, "el interior quedó registrado")
	_check(GameManager.opacidad_fundido() == 0.0, "al terminar de entrar la pantalla se ve")

	# Salir con la flecha apretada: varios intentos durante el fundido.
	var mapa = GameManager.mapa_secundario
	var p2 = mapa.get_node("Player")
	p2.colocar_en(mapa.celda_entrada)
	for i in 5:
		if is_instance_valid(p2):
			p2.intentar_paso(Vector2.DOWN)
		await get_tree().process_frame
	await _esperar(1.0)
	_check(_secundarios() == 0, "no queda ningún interior cargado (%d)" % _secundarios())
	_check(GameManager.mapa_secundario == null, "se volvió al barrio")
	_check(GameManager.opacidad_fundido() == 0.0, "al volver la pantalla NO queda en negro (%.2f)" % GameManager.opacidad_fundido())
	_check(m.visible and p.is_physics_processing(), "el barrio se ve y Monti se mueve")
	_check(p.get_node("Camera2D").is_current(), "la cámara es la del barrio")
	_check(m.celda_de(p.position) == vereda, "Monti está en la vereda")
	GameManager.forzar_fundido = false
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
