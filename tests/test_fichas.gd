extends Node
## Valida las fichas de personaje (data/personajes) contra la escena principal (spec 0010).
## Correr: godot --headless --path . res://tests/test_fichas.tscn

const NECESIDADES := ["hambre", "energia", "social", "ocio", "deber"]

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	var mundo = load("res://scenes/main.tscn").instantiate()
	add_child(mundo)
	var ids_poi := {"propio": true}
	for poi in mundo.pois:
		_check(not ids_poi.has(poi.poi_id), "POI duplicado: %s" % poi.poi_id)
		ids_poi[poi.poi_id] = true
		_check(mundo.es_transitable_estatica(poi.celda()), "POI %s en celda no transitable %s" % [poi.poi_id, poi.celda()])
		var ocupante = mundo.ocupacion.ocupante(poi.celda())
		_check(ocupante == null or "npc_name" in ocupante, "POI %s tapado por el objeto %s" % [poi.poi_id, ocupante])
		_check(poi.capacidad > 0 and poi.duracion_min > 0, "POI %s con capacidad y duración positivas" % poi.poi_id)
		for n in poi.satisface:
			_check(n in NECESIDADES, "POI %s satisface una necesidad desconocida: %s" % [poi.poi_id, n])
	print("POIs en escena: %d" % mundo.pois.size())
	_check(mundo.pois.size() >= 15, "hay al menos 15 POIs en la escena")

	var npcs := 0
	for nodo in mundo.get_children():
		if not ("npc_name" in nodo):
			continue
		npcs += 1
		_check(nodo.rutina == 3, "%s usa la rutina CEREBRO" % nodo.npc_name)
		var ruta := "res://data/personajes/%s.json" % nodo.id_ficha()
		_check(FileAccess.file_exists(ruta), "%s tiene ficha en %s" % [nodo.npc_name, ruta])
		if not FileAccess.file_exists(ruta):
			continue
		var f = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		_check(f is Dictionary, "ficha de %s es JSON válido" % nodo.npc_name)
		if not (f is Dictionary):
			continue
		_validar_ficha(f, ids_poi, nodo.npc_name)
	print("NPCs validados: %d" % npcs)
	_check(npcs >= 20, "la escena tiene al menos 20 NPCs")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _validar_ficha(f: Dictionary, ids_poi: Dictionary, quien: String) -> void:
	for campo in ["id", "nombre", "descripcion", "personalidad", "decaimiento", "plan_semanal", "rumores_semilla", "lugar_propio"]:
		_check(f.has(campo), "%s: falta el campo %s" % [quien, campo])
	var afin: Dictionary = f.get("personalidad", {}).get("afinidad", {})
	for n in NECESIDADES:
		var v = afin.get(n, -1.0)
		_check(v >= 0.0 and v <= 1.0, "%s: afinidad %s fuera de rango" % [quien, n])
		var d = f.get("decaimiento", {}).get(n, -1.0)
		_check(d >= 0.0 and d <= 50.0, "%s: decaimiento %s fuera de rango" % [quien, n])
	var fuerza = f.get("personalidad", {}).get("fuerza_rutina", -1.0)
	_check(fuerza >= 0.0 and fuerza <= 1.0, "%s: fuerza_rutina fuera de rango" % quien)
	for e in f.get("plan_semanal", []):
		_check(ids_poi.has(e.get("poi", "")), "%s: el plan usa un POI inexistente: %s" % [quien, e.get("poi")])
		_check(int(e.get("desde", -1)) in range(0, 25) and int(e.get("hasta", -1)) in range(0, 25), "%s: horas del plan fuera de rango" % quien)
		for d in e.get("dias", []):
			_check(int(d) in range(0, 7), "%s: día fuera de rango en el plan" % quien)
	_check(f.get("rumores_semilla", []).size() >= 2, "%s: al menos 2 rumores semilla" % quien)
