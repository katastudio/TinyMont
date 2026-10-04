extends Node
## Test headless de movimiento de NPCs: 3600 frames (1 min a 60 fps) + verificación de ocupación
## Verifica: no hay dos NPCs en la misma celda, ningún NPC en celda no-walkable,
## ningún NPC pisa la celda del player, al menos 3 NPCs cambiaron de celda.
## Correr: godot --headless --path . res://tests/test_npc_movimiento.tscn

var _fallas := 0
var _frames := 0
var _max_frames := 3600
var _violaciones_impresas := 0
var _max_violaciones_impresas := 50

# Tracking para CA1 y CA2
var _celda_inicial_por_npc: Dictionary = {}  # npc.name -> Vector2i (celda de spawn)
var _celda_anterior_por_npc: Dictionary = {} # npc.name -> Vector2i
var _npcs_que_cambiaron: Dictionary = {}     # npc.name -> true
var _deambuladores: Array[String] = []       # nombres de NPCs con Rutina.DEAMBULAR

# World references
var _mundo: Node2D
var _player: CharacterBody2D
var _npcs: Array[Node] = []


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _imprimir_violacion(msg: String) -> void:
	if _violaciones_impresas < _max_violaciones_impresas:
		push_error(msg)
		_violaciones_impresas += 1
	_fallas += 1


func _encontrar_mundo() -> bool:
	"""Busca el nodo MonteGrande en la escena."""
	_mundo = get_node_or_null("MonteGrande") as Node2D
	if not _mundo:
		_mundo = find_child("MonteGrande", true, false) as Node2D

	if not _mundo or not _mundo.has_method("celda_de"):
		push_error("No se encontró MonteGrande o no tiene el método celda_de")
		return false

	return true


func _encontrar_player_y_npcs() -> bool:
	"""Busca el Player y los NPCs en el mundo."""
	_player = null
	_npcs.clear()

	for child in _mundo.get_children():
		# Player: CharacterBody2D con nombre "Player"
		if child is CharacterBody2D and child.name == "Player":
			_player = child
		# NPCs: StaticBody2D con el script npc.gd
		elif child is StaticBody2D and child.has_method("interact"):
			_npcs.append(child)

	if not _player:
		push_error("No se encontró el Player en el mundo")
		return false

	if _npcs.size() < 10:
		push_error("Esperaba al menos 10 NPCs, encontré %d" % _npcs.size())
		return false

	print("Encontrados: %d NPCs, 1 Player" % _npcs.size())

	# Guardar celdas iniciales e identificar deambuladores
	for npc in _npcs:
		var npc_name = npc.name
		var celda = _mundo.celda_de(npc.global_position)
		_celda_inicial_por_npc[npc_name] = celda
		_celda_anterior_por_npc[npc_name] = celda

		# Detectar deambuladores: rutina == 1 (DEAMBULAR)
		if "rutina" in npc and npc.rutina == 1:
			_deambuladores.append(npc_name)

	print("NPCs: %s" % [_npcs.map(func(n): return n.name)])
	if _deambuladores.size() > 0:
		print("Deambuladores: %s" % [_deambuladores])

	return true


func _on_frame() -> void:
	_frames += 1

	if _frames == 1:
		# Inicialización: encontrar mundo, player, NPCs
		if not _encontrar_mundo():
			_finalizar()
			return
		if not _encontrar_player_y_npcs():
			_finalizar()
			return

	if _frames > _max_frames:
		_finalizar()
		return

	if _frames % 600 == 0:
		print("Frame %d/%d..." % [_frames, _max_frames])

	# ========== VERIFICAR INVARIANTES CADA FRAME ==========

	var ocupacion = _mundo.ocupacion
	if not ocupacion:
		_imprimir_violacion("Frame %d: ocupacion no existe" % _frames)
		return

	var celda_player = _mundo.celda_de(_player.global_position)

	# Rastrear cambios de celda para CA1
	for npc in _npcs:
		var celda_npc = _mundo.celda_de(npc.global_position)
		var npc_name = npc.name

		var celda_anterior = _celda_anterior_por_npc.get(npc_name, celda_npc)

		# CA1: ¿cambió de celda?
		if celda_npc != celda_anterior:
			_npcs_que_cambiaron[npc_name] = true

		_celda_anterior_por_npc[npc_name] = celda_npc

		# Verificar que sea transitable
		if not _mundo.es_transitable_estatica(celda_npc):
			_imprimir_violacion("Frame %d: NPC %s en celda no-transitable %s" % [_frames, npc_name, celda_npc])

		# Verificar que no pise al player
		if celda_npc == celda_player:
			_imprimir_violacion("Frame %d: NPC %s pisa celda del player %s" % [_frames, npc_name, celda_player])

	# Verificar que no haya dos NPCs en la misma celda
	var celdas_ocupadas: Dictionary = {}
	for npc in _npcs:
		var celda = _mundo.celda_de(npc.global_position)
		if celdas_ocupadas.has(celda):
			var otro = celdas_ocupadas[celda]
			_imprimir_violacion("Frame %d: dos NPCs en celda %s: %s y %s" % [_frames, celda, npc.name, otro.name])
		celdas_ocupadas[celda] = npc


func _verificar_ca1_ca2() -> void:
	"""Verifica CA1 y CA2 después de la simulación."""
	print("\n=== VERIFICANDO CA1 (cambios de celda) ===")
	var npcs_cambiados = _npcs_que_cambiaron.size()
	_check(npcs_cambiados >= 3, "CA1: al menos 3 NPCs cambiaron de celda (cambiaron: %d)" % npcs_cambiados)

	if npcs_cambiados < 3:
		print("NPCs que cambiaron: %s" % _npcs_que_cambiaron.keys())

	print("\n=== VERIFICANDO CA2 (deambuladores en radio) ===")
	var todo_ok = true
	for npc in _npcs:
		if npc.name not in _deambuladores:
			continue

		var celda_actual = _mundo.celda_de(npc.global_position)
		var celda_spawn = _celda_inicial_por_npc.get(npc.name, celda_actual)

		# Chebyshev distance: max(abs(dx), abs(dy))
		var dx = absi(celda_actual.x - celda_spawn.x)
		var dy = absi(celda_actual.y - celda_spawn.y)
		var distancia = max(dx, dy)

		var radio = npc.radio_deambular if "radio_deambular" in npc else 3

		if distancia <= radio:
			print("OK: %s dentro de radio %d (distancia %d)" % [npc.name, radio, distancia])
		else:
			_imprimir_violacion("CA2 fallido: %s a distancia %d > radio %d" % [npc.name, distancia, radio])
			todo_ok = false

	_check(todo_ok or _deambuladores.size() == 0, "CA2: todos los deambuladores dentro de su radio")


func _finalizar() -> void:
	print("\n=== Test finalizado en frame %d ===" % _frames)

	# Verificar CA1 y CA2
	_verificar_ca1_ca2()

	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _ready() -> void:
	# Conectar a process_frame para validar cada frame
	if not get_tree().process_frame.is_connected(_on_frame):
		get_tree().process_frame.connect(_on_frame)
