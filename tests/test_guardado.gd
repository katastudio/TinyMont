extends Node
## Guardado del mundo vivo (spec 0010 F4 + spec 0005).
## Verifica que cargar una partida reproduce exactamente el mundo que siguió sin cargar.
## Correr: godot --headless --path . res://tests/test_guardado.tscn

const DT := 1.0 / 60.0
const RUTA := "user://test_guardado.json"

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	GameManager.ruta_guardado = RUTA
	GameManager.borrar_partida()
	_check(not GameManager.has_save(), "sin partida guardada al empezar")

	# Rama A: simula 90 minutos, toma una foto del estado, sigue 30 minutos más.
	WorldClock.reiniciar(4242, 8)
	var a = _crear_mundo()
	_simular(a, 90)
	var trompeta = a.get_node_or_null("Trompeta")
	_check(trompeta != null, "la trompeta está en el mapa")
	var celda_trompeta: Vector2i = a.celda_de(trompeta.position)
	GameManager.set_estado_mision("gille_trompeta", "en_curso")
	GameManager.set_estado_mision("eldiez_pelota", "en_curso")     # encargada, pelota sin levantar
	trompeta.interact(Vector2.ZERO)  # el jugador levanta la trompeta
	a.get_node("Player").colocar_en(Vector2i(10, 10))
	GameManager.save_game(a)
	_check(GameManager.has_save(), "has_save() es true después de guardar")
	_simular(a, 30)
	var foto_a := _foto(a)
	var reloj_a: int = WorldClock.minutos
	_liberar(a)

	# Rama B: arranca un mundo nuevo distinto y carga la partida guardada.
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	WorldClock.reiniciar(1, 6)
	GameManager.cargar_al_iniciar = true
	var b = _crear_mundo()
	_check(not GameManager.cargar_al_iniciar, "la carga pendiente se consume al iniciar el mundo")
	_check(b.get_node_or_null("Trompeta") == null, "la trompeta levantada no reaparece")
	_check(b.ocupacion.esta_libre(celda_trompeta), "su celda queda libre")
	var pelota = b.get_node("Pelota")
	_check(pelota.visible and b.get_npc_at(pelota.position) == pelota, "un objeto de una misión ya encargada aparece al cargar")
	_check("trompeta" in GameManager.inventario, "el inventario se restaura")
	_check(GameManager.get_estado_mision("gille_trompeta") == "en_curso", "las misiones se restauran")
	_check(b.celda_de(b.get_node("Player").position) == Vector2i(10, 10), "la posición del jugador se restaura")
	_check(b.ocupacion.ocupante(Vector2i(10, 10)) == b.get_node("Player"), "la grilla registra al jugador en su celda cargada")
	_simular(b, 30)
	_check(WorldClock.minutos == reloj_a, "el reloj sigue desde la hora guardada")
	var foto_b := _foto(b)
	var distintos := 0
	for i in foto_a.size():
		if foto_a[i] != foto_b[i]:
			distintos += 1
			if distintos <= 3:
				push_error("difiere: %s vs %s" % [foto_a[i], foto_b[i]])
	_check(distintos == 0, "cargar y seguir 30 minutos da el mismo mundo que no haber cargado")
	_liberar(b)

	_test_bici()
	_test_progreso_de_misiones()

	# Partida manipulada: rutas en los objetos y un color inválido no rompen la carga.
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	f.store_string(JSON.stringify({"jugador": {"bici_color": "no-es-color"}, "objetos_tomados": ["../TestGuardado", "Player", "/root"], "mundo": {}}))
	f.close()
	GameManager.cargar_al_iniciar = true
	var c = _crear_mundo()
	_check(c.get_node_or_null("Player") != null and is_instance_valid(self), "nombres manipulados no borran nodos que no son objetos")
	_check(GameManager.bici_color.a > 0.0, "un color inválido conserva el color anterior")
	_liberar(c)

	GameManager.borrar_partida()
	_check(not GameManager.has_save(), "borrar_partida elimina el archivo")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _crear_mundo():
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	for nodo in m.get_children():
		nodo.set_process(false)
		nodo.set_physics_process(false)
	return m


func _simular(m, minutos: int) -> void:
	var npcs: Array = m.get_children().filter(func(n): return "npc_name" in n)
	for f in minutos * 60:
		WorldClock._process(DT)
		for n in npcs:
			n._process(DT)


## Estado observable completo de cada NPC: celda, posición, necesidades, memoria y actividad.
func _foto(m) -> Array:
	var foto := []
	for n in m.get_children():
		if "npc_name" in n:
			foto.append("%s@%s pos=%s act=%s nec=%s hechos=%d rel=%s" % [
				n.npc_name, m.celda_de(n.global_position), n.global_position, n.actividad_actual(),
				n._cerebro.necesidades, n.memoria.hechos.size(), _ordenado(n.memoria.relaciones)])
	return foto


func _liberar(m) -> void:
	remove_child(m)
	m.free()


## La bici se guarda donde quedó estacionada, y montada si el jugador iba en ella.
func _test_bici() -> void:
	WorldClock.reiniciar(7, 8)
	var m = _crear_mundo()
	var p = m.get_node("Player")
	var bici = m.get_node("Bicicleta")
	p.colocar_en(bici.tile())
	p._subir_bici()
	_check(GameManager.en_bici, "el jugador se sube a la bici")
	p.colocar_en(Vector2i(12, 14))
	p._bajar_bici()
	GameManager.save_game(m)
	_liberar(m)
	GameManager.cargar_al_iniciar = true
	var m2 = _crear_mundo()
	_check(m2.get_node("Bicicleta").tile() == Vector2i(12, 14), "la bici aparece donde quedó estacionada")
	_check(not GameManager.en_bici, "a pie si se guardó a pie")
	var p2 = m2.get_node("Player")
	p2.colocar_en(Vector2i(12, 14))
	p2._subir_bici()
	GameManager.save_game(m2)
	_liberar(m2)
	GameManager.en_bici = false
	GameManager.cargar_al_iniciar = true
	var m3 = _crear_mundo()
	_check(GameManager.en_bici, "montado si se guardó montado")
	_check(not m3.get_node("Bicicleta").visible, "la bici montada no se ve estacionada")
	m3.get_node("Player")._bajar_bici()
	_check(m3.get_node("Bicicleta").visible, "al bajarse la bici vuelve a verse")
	_liberar(m3)
	GameManager.en_bici = false


## El catálogo sale de la escena y el guardado conserva contadores y cuentas regresivas.
func _test_progreso_de_misiones() -> void:
	WorldClock.reiniciar(8, 8)
	var m = _crear_mundo()
	_check(GameManager.catalogo.has("marcos_vasitos") and GameManager.catalogo.has("rosa_gato"), "el mundo carga el catálogo de misiones")
	_check(not GameManager.catalogo.has(""), "el catálogo no incluye vecinos sin misión")
	_check(GameManager.catalogo["marcos_vasitos"].giver == "Marcos", "el catálogo sabe quién da cada misión")
	GameManager.misiones["m_cuenta"] = "en_curso"
	GameManager.iniciar_cuenta("m_cuenta", 42.5, "bandera")
	GameManager.misiones["m_contador"] = "en_curso"
	GameManager.iniciar_contador("m_contador", "Rodri", 3, "¡Gracias!")
	GameManager.registrar_contacto("Tito")
	GameManager.save_game(m)
	_liberar(m)
	GameManager.cuentas.clear()
	GameManager.contadores.clear()
	GameManager.cargar_al_iniciar = true
	var m2 = _crear_mundo()
	_check(is_equal_approx(GameManager.tiempo_restante("m_cuenta"), 42.5), "la cuenta regresiva sobrevive al guardado")
	_check(GameManager.contador_de("m_contador") == 1, "el contador sobrevive al guardado")
	_check(GameManager.registrar_contacto("Tito").is_empty(), "un vecino ya contado no vuelve a contar tras cargar")
	_liberar(m2)
	GameManager.cuentas.clear()
	GameManager.contadores.clear()
	GameManager.misiones.erase("m_cuenta")
	GameManager.misiones.erase("m_contador")


## Relaciones como texto con claves ordenadas (JSON no conserva el orden de inserción).
func _ordenado(d: Dictionary) -> String:
	var claves := d.keys()
	claves.sort()
	return ",".join(claves.map(func(k): return "%s=%s" % [k, d[k]]))
