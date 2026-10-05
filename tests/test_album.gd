extends Node
## Álbum del barrio, íconos y HUD (spec 0008 R3 y R8).
## Correr: godot --headless --path . res://tests/test_album.tscn

const ItemArt = preload("res://scripts/art/item_art.gd")

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)

	# Todo objeto que aparece en una misión tiene ícono y nombre propios.
	var objetos := {}
	for n in m.get_children():
		if "mision_id" in n:
			for id in [n.recompensa_item, n.requisito_item, n.otorga_item]:
				if id != "":
					objetos[id] = n.npc_name
			for ay in n.ayudas:
				objetos[str(ay.get("item", ""))] = n.npc_name
		elif "item" in n and n.has_method("interact"):
			objetos[n.item] = String(n.name)
	objetos.erase("")
	for id in objetos:
		_check(ItemArt.tiene_icono(id), "el objeto %s (%s) tiene ícono propio" % [id, objetos[id]])
		_check(ItemArt.nombre(id) != id.capitalize() or ItemArt.NOMBRES.has(id), "el objeto %s tiene nombre" % id)
	# Cada misión regala algo distinto: nada de recuerdos genéricos.
	var recompensas := {}
	for id in GameManager.catalogo:
		var r: String = GameManager.catalogo[id].recompensa
		_check(r != "" and r != "recuerdo", "la misión %s regala un objeto icónico (%s)" % [id, r])
		_check(not recompensas.has(r), "la recompensa %s no se repite" % r)
		recompensas[r] = true

	# El álbum: un espacio por misión del catálogo, con lo conseguido marcado.
	GameManager.abrir_album()
	_check(GameManager.album_abierto, "el álbum se abre")
	var album = GameManager.album
	var espacios: Array = album.espacios()
	_check(espacios.size() == GameManager.total_misiones(), "un espacio por misión (%d)" % espacios.size())
	_check(espacios.all(func(e): return not e.conseguido), "al empezar no hay nada conseguido")
	var primera: Dictionary = espacios[0]
	GameManager.agregar_item(primera.recompensa)
	GameManager.set_estado_mision(primera.mision, "completada")
	espacios = album.espacios()
	_check(espacios[0].conseguido, "al conseguir la recompensa, el espacio se completa")
	_check(album.texto_contador() == "1/%d" % GameManager.total_misiones(), "el contador muestra el progreso")

	# Con el álbum abierto el jugador no camina.
	var player = m.get_node("Player")
	_check(player.puede_moverse() == false, "con el álbum abierto Monti no se mueve")
	GameManager.cerrar_album()
	_check(not GameManager.album_abierto and player.puede_moverse(), "al cerrarlo vuelve a moverse")

	# HUD: cuenta regresiva visible durante una contrarreloj.
	var hud = GameManager._hud.get_child(0) if GameManager._hud.get_child_count() > 0 else null
	_check(hud != null and hud.has_method("texto_cuenta"), "el HUD sabe mostrar la cuenta regresiva")
	if hud:
		_check(hud.texto_cuenta() == "", "sin contrarreloj no hay cuenta")
		GameManager.misiones["m_reloj"] = "en_curso"
		GameManager.iniciar_cuenta("m_reloj", 42.3, "")
		_check(hud.texto_cuenta() == "0:43", "con contrarreloj muestra el tiempo (%s)" % hud.texto_cuenta())
		GameManager.cuentas.clear()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
