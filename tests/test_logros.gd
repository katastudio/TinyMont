extends Node
## Logros (roadmap "Puntuación / logros"): se desbloquean una vez, se anuncian y se guardan.
## Correr: godot --headless --path . res://tests/test_logros.tscn

const RUTA := "user://test_logros.json"

var _fallas := 0
var _anuncios: Array = []


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	WorldClock.reiniciar(3, 10)
	GameManager.ruta_guardado = RUTA
	GameManager.borrar_partida()
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	GameManager.logros.clear()
	GameManager.logro_desbloqueado.connect(func(id): _anuncios.append(id))
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	for n in m.get_children():
		n.set_process(false)
		n.set_physics_process(false)

	_check(GameManager.LOGROS.size() == 10, "hay 10 logros definidos")
	_check(GameManager.logros.is_empty(), "al empezar no hay logros")

	# Misiones: primero, mitad y álbum completo.
	var ids: Array = GameManager.catalogo.keys()
	GameManager.set_estado_mision(ids[0], "completada")
	_check(GameManager.tiene_logro("primer_encargo"), "primer encargo al completar una misión")
	for i in range(1, 10):
		GameManager.set_estado_mision(ids[i], "completada")
	_check(GameManager.tiene_logro("medio_album"), "medio álbum con 10 misiones")
	_check(not GameManager.tiene_logro("vecino_de_ley"), "todavía no es vecino de ley")

	# Chismoso: 5 rumores distintos escuchados.
	for i in 5:
		GameManager.registrar_rumor_escuchado("rumor %d" % i)
	GameManager.registrar_rumor_escuchado("rumor 0")
	_check(GameManager.tiene_logro("chismoso"), "chismoso con 5 rumores distintos")

	# Querido por todos: relación 5 con 3 vecinos (hablando con ellos).
	for nombre in ["Npc12Tito", "Npc10Walter", "Npc00DonCarlos"]:
		for i in 6:
			m.get_node(nombre).dialogo_lines()
	_check(GameManager.tiene_logro("querido"), "querido por todos con 3 amigos")

	# Ciclista: 100 celdas en bici.
	for i in 100:
		GameManager.registrar_pedaleo()
	_check(GameManager.tiene_logro("ciclista"), "ciclista tras 100 celdas en bici")

	# Explorador: 15 lugares distintos.
	for poi in m.pois.slice(0, 15):
		GameManager.registrar_visita(poi.poi_id)
	_check(GameManager.tiene_logro("explorador"), "explorador con 15 lugares visitados")

	# Noctámbulo: el reloj marca las 2 con el mundo en juego.
	WorldClock.reiniciar(3, 1)
	WorldClock.avanzar(60)
	_check(GameManager.tiene_logro("noctambulo"), "noctámbulo a las 2 de la mañana")

	# Madrugador: hablar con alguien entre las 5 y las 7.
	WorldClock.reiniciar(3, 6)
	m.get_node("Npc05DonaRosa").dialogo_lines()
	_check(GameManager.tiene_logro("madrugador"), "madrugador al hablar a las 6")

	# Contra reloj: completar una misión contrarreloj.
	var fran = m.get_node("Franquito")
	fran.dialogo_lines()
	GameManager.agregar_item(fran.requisito_item)
	fran.dialogo_lines()
	_check(GameManager.tiene_logro("contra_reloj"), "contra reloj al ganar la carrera")

	# Una sola vez cada uno, y con anuncio.
	var antes := _anuncios.size()
	GameManager.set_estado_mision(ids[0], "completada")
	GameManager.registrar_rumor_escuchado("rumor nuevo")
	_check(_anuncios.size() == antes, "un logro no se anuncia dos veces")
	_check(_anuncios.size() == GameManager.logros.size(), "cada logro se anunció una vez (%d)" % _anuncios.size())
	var hud = GameManager._hud.get_child(0)
	_check(hud.texto_aviso() != "", "el HUD muestra el aviso del último logro")

	# Se guardan con la partida.
	var cuantos := GameManager.logros.size()
	GameManager.save_game(m)
	GameManager.logros.clear()
	GameManager.leer_partida()
	_check(GameManager.logros.size() == cuantos, "los logros sobreviven al guardado")
	_check(GameManager.album == null or GameManager.album.has_method("texto_logros"), "el álbum puede listar los logros")
	GameManager.abrir_album()
	_check(GameManager.album.texto_logros() == "Logros %d/10" % cuantos, "el álbum muestra los logros")
	GameManager.cerrar_album()
	GameManager.borrar_partida()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
