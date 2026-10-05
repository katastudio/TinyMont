extends Node
## Mapas secundarios (spec 0006, ADR-0005): edificios y otros barrios, ida y vuelta.
## Correr: godot --headless --path . res://tests/test_mapas.tscn

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
	WorldClock.reiniciar(9, 12)
	GameManager.transicion_inmediata = true
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var p = m.get_node("Player")

	var destinos := {}
	for portal in m.portales():
		destinos[portal.destino] = portal
	_check(destinos.size() >= 3, "hay al menos 3 puertas a otros mapas (%d)" % destinos.size())
	_check(not FileAccess.file_exists("res://scripts/world/plaza.gd"), "el prototipo viejo de la plaza fue retirado")

	for escena in destinos:
		var portal = destinos[escena]
		_check(not m.es_transitable_estatica(portal.celda()), "%s: la puerta es parte del edificio" % escena)
		var vereda: Vector2i = portal.celda() + Vector2i(0, 1)
		p.colocar_en(vereda)
		p.facing = Vector2.UP
		_check(p.intentar_paso(Vector2.UP) == "portal", "%s: caminar contra la puerta entra" % escena)
		var mapa = GameManager.mapa_secundario
		_check(mapa != null and mapa.scene_file_path == escena, "%s: se cargó el mapa" % escena)
		if mapa == null:
			continue
		_check(not m.visible, "%s: el barrio queda oculto" % escena)
		_check(not p.is_physics_processing(), "%s: el Monti de afuera queda congelado" % escena)
		var p2 = mapa.get_node("Player")
		_check(p2 != null and p2.get_node("Camera2D").is_current(), "%s: adentro hay un Monti con cámara" % escena)
		_check(mapa.ocupacion.ocupante(mapa.celda_de(p2.position)) == p2, "%s: la grilla registra al Monti de adentro" % escena)
		_check(mapa.vecinos().size() >= 1, "%s: hay gente adentro" % escena)
		var bordes := 0
		for c in [Vector2i(0, 0), Vector2i(mapa.ancho - 1, 0), Vector2i(0, mapa.alto - 1)]:
			if not mapa.is_walkable(mapa.pos_de(c)):
				bordes += 1
		_check(bordes == 3, "%s: las paredes no se atraviesan" % escena)
		var alguien = mapa.vecinos()[0]
		var al_lado: Vector2i = mapa.celda_libre_junto_a(mapa.celda_de(alguien.position))
		p2.colocar_en(al_lado)
		_check(mapa.get_npc_at(alguien.position) == alguien, "%s: se puede hablar con la gente de adentro" % escena)
		# El mundo de afuera sigue vivo mientras tanto.
		var minutos := WorldClock.minutos
		for f in 120:
			WorldClock._process(DT)
		_check(WorldClock.minutos > minutos, "%s: el reloj sigue corriendo adentro" % escena)
		# Salir: caminar contra la salida devuelve a la vereda.
		p2.colocar_en(mapa.celda_entrada)
		_check(p2.intentar_paso(Vector2.DOWN) == "portal", "%s: caminar contra la salida sale" % escena)
		_check(GameManager.mapa_secundario == null, "%s: se descarga el mapa" % escena)
		_check(m.visible and p.is_physics_processing(), "%s: el barrio vuelve a verse y Monti a moverse" % escena)
		_check(m.celda_de(p.position) == vereda, "%s: Monti aparece en la vereda" % escena)
		_check(p.get_node("Camera2D").is_current(), "%s: vuelve la cámara del barrio" % escena)
		_check(not GameManager.is_dialog_active or GameManager.dialog_box.visible, "%s: no queda input trabado" % escena)
		GameManager.is_dialog_active = false

	# Guardar estando adentro guarda al Monti en la vereda del barrio.
	var portal0 = destinos.values()[0]
	p.colocar_en(portal0.celda() + Vector2i(0, 1))
	p.intentar_paso(Vector2.UP)
	GameManager.ruta_guardado = "user://test_mapas.json"
	GameManager.save_game()
	var datos := GameManager.leer_partida()
	var c: Array = datos.mundo.jugador.celda
	_check(Vector2i(int(c[0]), int(c[1])) == portal0.celda() + Vector2i(0, 1), "guardar adentro deja a Monti en la vereda")
	GameManager.volver_al_barrio()
	GameManager.borrar_partida()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
