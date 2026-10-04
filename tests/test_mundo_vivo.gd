extends Node
## Integración del mundo vivo (spec 0010, F2): simula horas de juego en headless.
## Avance determinístico: se desactiva el procesamiento automático y se llama a
## _process(1/60) a mano sobre el reloj y los NPCs (1 minuto de juego por segundo real).
## Correr: godot --headless --path . res://tests/test_mundo_vivo.tscn

const DT := 1.0 / 60.0
const SEMILLA := 20261002
const COMIDA := ["mostaza", "kfc", "burger", "la_veneciana", "mcdonalds"]
const TRABAJO_WALTER := ["parada_306", "terminal_306"]
const RUMOR_PRUEBA := "Tito vio un plato volador arriba de la estación."
const DAN_MISIONES := ["Dona Rosa", "Marcos", "Gille", "Leo", "Tiaguito", "La Coqueta", "Chuchu", "Don Jorge", "Sandra"]

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	var r := _simular(SEMILLA, 8 * 60, true, true)
	var npcs: Dictionary = r.npcs

	_check(r.violaciones == 0, "sin violaciones de ocupación en 8 horas (%d)" % r.violaciones)
	_check("cancha_bochas" in npcs["Tito"].historial_pois, "Tito jugó a las bochas (%s)" % [npcs["Tito"].historial_pois])
	var walter_trabajo: bool = npcs["Walter"].historial_pois.any(func(p): return p in TRABAJO_WALTER)
	_check(walter_trabajo, "Walter trabajó en su línea (%s)" % [npcs["Walter"].historial_pois])
	var comieron := 0
	var activos := 0
	for n in npcs.values():
		if n.historial_pois.any(func(p): return p in COMIDA):
			comieron += 1
		if not n.historial_pois.is_empty():
			activos += 1
	_check(comieron >= 3, "al menos 3 vecinos fueron a comer (%d)" % comieron)
	_check(activos >= 18, "al menos 18 vecinos completaron alguna actividad (%d)" % activos)
	_check(r.lejos_de_su_lugar == 0, "quienes dan misiones siguen ubicables entre las 10 y las 16 (%d desvíos)" % r.lejos_de_su_lugar)
	_verificar_vida_social(r)
	print("Tiempo medio por frame: %.1f us" % r.us_por_frame)
	_check(r.us_por_frame < 2000.0, "la simulación cuesta menos de 2 ms por frame")
	_liberar(r.mundo)

	var a := _simular(SEMILLA, 2 * 60, false)
	var foto_a := _foto(a.mundo)
	_liberar(a.mundo)
	var b := _simular(SEMILLA, 2 * 60, false)
	var foto_b := _foto(b.mundo)
	_liberar(b.mundo)
	var c := _simular(SEMILLA + 1, 2 * 60, false)
	var foto_c := _foto(c.mundo)
	_liberar(c.mundo)
	_check(foto_a == foto_b, "misma semilla, mismas posiciones tras 2 horas")
	_check(foto_a != foto_c, "otra semilla, otro mundo")

	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _simular(semilla: int, minutos_juego: int, verificar: bool, inyectar_rumor := false) -> Dictionary:
	WorldClock.reiniciar(semilla, 8)
	var mundo = load("res://scenes/main.tscn").instantiate()
	mundo.semilla = semilla
	add_child(mundo)
	var npcs := {}
	var lista: Array = []
	for nodo in mundo.get_children():
		if "npc_name" in nodo:
			npcs[nodo.npc_name] = nodo
			lista.append(nodo)
			nodo.set_process(false)
		elif nodo.has_method("_process"):
			nodo.set_process(false)
		if nodo.has_method("_physics_process"):
			nodo.set_physics_process(false)
	if inyectar_rumor:
		npcs["Tito"].memoria.aprender(RUMOR_PRUEBA, WorldClock.minutos, "Tito")
	var spawn := {}
	for n in lista:
		spawn[n.npc_name] = mundo.celda_de(n.global_position)

	var frames := int(minutos_juego * 60 / WorldClock.minutos_por_segundo / DT / 60.0)
	var violaciones := 0
	var lejos := 0
	var us_total := 0
	for f in frames:
		var t0 := Time.get_ticks_usec()
		WorldClock._process(DT)
		for n in lista:
			n._process(DT)
		us_total += Time.get_ticks_usec() - t0
		if verificar:
			violaciones += _invariantes(mundo, lista, f)
			if f % 600 == 0 and WorldClock.hora() >= 10 and WorldClock.hora() < 16:
				for nombre in DAN_MISIONES:
					var d: Vector2i = mundo.celda_de(npcs[nombre].global_position) - spawn[nombre]
					if absi(d.x) + absi(d.y) > 3:
						lejos += 1
						if lejos <= 5:
							push_error("%s lejos de su lugar a las %s" % [nombre, WorldClock.texto_hora()])
	return {"mundo": mundo, "npcs": npcs, "violaciones": violaciones, "lejos_de_su_lugar": lejos,
		"us_por_frame": float(us_total) / maxf(1.0, frames)}


func _invariantes(mundo, lista: Array, frame: int) -> int:
	var malas := 0
	var vistas := {}
	var celda_player: Vector2i = mundo.celda_de(mundo.get_node("Player").global_position) if mundo.has_node("Player") else Vector2i(-99, -99)
	for n in lista:
		var c: Vector2i = mundo.celda_de(n.global_position)
		var error := ""
		if vistas.has(c):
			error = "%s y %s en la celda %s" % [n.npc_name, vistas[c], c]
		elif not mundo.es_transitable_estatica(c):
			error = "%s en celda no transitable %s" % [n.npc_name, c]
		elif c == celda_player:
			error = "%s pisa al player en %s" % [n.npc_name, c]
		elif mundo.ocupacion.ocupante(c) != n:
			error = "la grilla no registra a %s en %s" % [n.npc_name, c]
		vistas[c] = n.npc_name
		if error != "":
			malas += 1
			if malas <= 3:
				push_error("frame %d: %s" % [frame, error])
	return malas


func _foto(mundo) -> Array:
	var foto := []
	for nodo in mundo.get_children():
		if "npc_name" in nodo:
			foto.append("%s@%s" % [nodo.npc_name, mundo.celda_de(nodo.global_position)])
	foto.sort()
	return foto


func _liberar(mundo) -> void:
	remove_child(mundo)
	mundo.free()


func _verificar_vida_social(r: Dictionary) -> void:
	var mundo = r.mundo
	var npcs: Dictionary = r.npcs
	print("Charlas en 8 horas: %d" % mundo.charlas_totales)
	_check(mundo.charlas_totales >= 10, "los vecinos charlaron al menos 10 veces")
	var saben := []
	var con_relacion := 0
	for nombre in npcs:
		var n = npcs[nombre]
		if nombre != "Tito" and n.memoria.conoce(RUMOR_PRUEBA):
			saben.append(nombre)
		if not n.memoria.relaciones.is_empty():
			con_relacion += 1
	_check(saben.size() >= 2, "el rumor de Tito llegó a otros vecinos (%s)" % [saben])
	_check(con_relacion >= 10, "al menos 10 vecinos tienen relaciones nuevas (%d)" % con_relacion)

	# El jugador escucha los chismes del barrio.
	var chismoso = null
	for nombre in npcs:
		var n = npcs[nombre]
		if n.mision_id == "" and not n.memoria.ultimo_rumor_ajeno().is_empty():
			chismoso = n
			break
	_check(chismoso != null, "algún vecino sin misión tiene un chisme para contar")
	if chismoso:
		var lineas: Array = chismoso.dialogo_lines()
		var rumor: String = chismoso.memoria.ultimo_rumor_ajeno().texto
		_check(lineas.any(func(l): return rumor in str(l)), "%s le cuenta el chisme al jugador" % chismoso.npc_name)
		chismoso.dialogo_lines()
		chismoso.dialogo_lines()
		_check(chismoso.memoria.relacion_con("jugador") >= 3, "cada charla con el jugador suma relación")

	# Completar una misión se vuelve noticia del barrio.
	var rosa = npcs["Dona Rosa"]
	GameManager.set_estado_mision(rosa.mision_id, "en_curso")
	GameManager.agregar_item(rosa.requisito_item)
	rosa.dialogo_lines()
	_check(GameManager.get_estado_mision(rosa.mision_id) == "completada", "la misión de Doña Rosa se completó")
	var noticia: Dictionary = rosa.memoria.hechos.back()
	_check("Dona Rosa" in noticia.texto or "Doña Rosa" in noticia.texto, "Doña Rosa recuerda que el jugador la ayudó (%s)" % noticia.texto)
