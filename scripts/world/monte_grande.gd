extends Node2D
## Monte Grande - mapa pintado en el EDITOR DE GODOT (TileMapLayer "MapaLayer").
##
## El mapa se edita visualmente: abrí scenes/main.tscn, seleccioná el nodo
## "MapaLayer" y pintá con la paleta de tiles (panel TileSet abajo a la derecha).
## Cada swatch de color es un tipo de tile (ver PALETTE). En el juego NO se ven
## los swatches: este script lee la capa y dibuja el arte procedural real.
##
## La paleta (orden = posición en el atlas) y la capa se generan con
## tools/build_tilemap.gd a partir de data/map.txt (semilla inicial).

const T := 16
const MAP_LAYER := "MapaLayer"
const COLS := 8  # columnas del atlas de swatches
const TanqueArt = preload("res://scripts/art/tanque_art.gd")
const GrillaOcupacionScript = preload("res://scripts/world/grilla_ocupacion.gd")

enum Tile {
	GRASS, BUILDING, ROAD, TREE, RAIL, PLAZA, WATER,
	SIDEWALK, MONUMENT, BENCH, PLATFORM, OMBU
}

# Semilla para determinismo (NPCs usan semilla + índice para RNG independiente)
@export var semilla: int = 20261002

# Paleta editable: el índice = celda del atlas (col = i%COLS, fila = i/COLS).
# Para edificios, btype define el render especial y bname el cartel.
# color es solo el swatch que se ve en el editor (lo usa el generador).
const PALETTE := [
	{name = "pasto",     tile = Tile.GRASS,    btype = "",           bname = "",          color = Color("58d858")},
	{name = "calle",     tile = Tile.ROAD,     btype = "",           bname = "",          color = Color("9c9c9c")},
	{name = "vereda",    tile = Tile.SIDEWALK, btype = "",           bname = "",          color = Color("e8d8b0")},
	{name = "arbol",     tile = Tile.TREE,     btype = "",           bname = "",          color = Color("1c9c1c")},
	{name = "ginkgo",    tile = Tile.OMBU,     btype = "",           bname = "",          color = Color("b6d000")},
	{name = "via",       tile = Tile.RAIL,     btype = "",           bname = "",          color = Color("5c5c5c")},
	{name = "anden",     tile = Tile.PLATFORM, btype = "",           bname = "",          color = Color("b8a880")},
	{name = "plaza",     tile = Tile.PLAZA,    btype = "",           bname = "",          color = Color("fce0a8")},
	{name = "fuente",    tile = Tile.WATER,    btype = "",           bname = "",          color = Color("3cbcfc")},
	{name = "monumento", tile = Tile.MONUMENT, btype = "",           bname = "",          color = Color("8888a0")},
	{name = "banco",     tile = Tile.BENCH,    btype = "",           bname = "",          color = Color("a05000")},
	{name = "estacion",  tile = Tile.BUILDING, btype = "station",    bname = "Monte Grande",  color = Color("fcfcfc")},
	{name = "teatro",    tile = Tile.BUILDING, btype = "teatro",     bname = "TEATRO",    color = Color("fcd800")},
	{name = "veneciana", tile = Tile.BUILDING, btype = "restaurant", bname = "VENECIANA", color = Color("d85820")},
	{name = "mostaza",   tile = Tile.BUILDING, btype = "fastfood",   bname = "MOSTAZA",   color = Color("fc7460")},
	{name = "kata",      tile = Tile.BUILDING, btype = "studio",     bname = "KATA",      color = Color("c040c0")},
	{name = "club",      tile = Tile.BUILDING, btype = "club",       bname = "CLUB ATL.", color = Color("2038ec")},
	{name = "comisaria", tile = Tile.BUILDING, btype = "police",     bname = "COMISARIA", color = Color("1830a0")},
	{name = "iglesia",   tile = Tile.BUILDING, btype = "church",     bname = "IGLESIA",   color = Color("fcfcfc")},
	{name = "municipio", tile = Tile.BUILDING, btype = "govt",       bname = "MUNICIPIO", color = Color("4060c0")},
	{name = "escuela",   tile = Tile.BUILDING, btype = "school",     bname = "ESC.N1",    color = Color("fc74a0")},
	{name = "tanque",    tile = Tile.BUILDING, btype = "watertower", bname = "EL TANQUE", color = Color("d86a2c")},
]

var MAP_W := 44
var MAP_H := 48

var tiles := PackedInt32Array()
var labels: Array = []
var _redraw_timer := 0.0
var building_info := {}

var ocupacion := GrillaOcupacionScript.new()  # Grilla de ocupación: Vector2i -> Object
var astar := AStarGrid2D.new()                # A* para pathfinding
var pois: Array[PuntoInteres] = []            # Puntos de interés del mundo
var poi_por_id: Dictionary = {}               # Lookup rápido: poi_id -> PuntoInteres

# Vida social (spec 0010, F3)
const MINUTOS_CHARLA := 10                    # duración de una charla entre vecinos
const ESPERA_ENTRE_CHARLAS := 60              # minutos antes de que la misma pareja vuelva a charlar
var charlas_totales: int = 0
var _vecinos: Array = []                      # NPCs con cerebro, en orden de escena (determinístico)
var _ultima_charla: Dictionary = {}           # "a|b" -> minuto de juego de su última charla


func _ready():
	_load_map()
	_spawn_player()
	_add_dialog_box()
	_create_pois()  # Recolecta los POIs de la escena
	_iniciar_vida_social()
	_iniciar_ciclo_dia()
	_cargar_catalogo_misiones()
	_iniciar_guardado()
	GameManager.mostrar_ui_juego(true)   # HUD + controles visibles en el juego
	MusicManager.play_music("tema_pueblo")
	# Los NPC ahora son nodos en la escena (main.tscn), editables en el Inspector.


# ==================== CARGA DESDE EL TILEMAP ====================

func _palette_at(ac: Vector2i):
	var idx := ac.y * COLS + ac.x
	if idx >= 0 and idx < PALETTE.size():
		return PALETTE[idx]
	return null


func _load_map():
	var layer: TileMapLayer = get_node_or_null(MAP_LAYER)
	if layer == null:
		push_error("Falta el nodo TileMapLayer '" + MAP_LAYER + "' en la escena.")
		return

	var rect := layer.get_used_rect()
	MAP_W = rect.position.x + rect.size.x
	MAP_H = rect.position.y + rect.size.y
	tiles.resize(MAP_W * MAP_H)
	tiles.fill(Tile.GRASS)

	# bounding box por TIPO de edificio (cada tipo = una instancia en el centro)
	var bld_cells := {}
	for c in layer.get_used_cells():
		var p = _palette_at(layer.get_cell_atlas_coords(c))
		if p == null:
			continue
		set_tile(c.x, c.y, p.tile)
		if p.btype != "":
			if not bld_cells.has(p.btype):
				bld_cells[p.btype] = {
					min_x = c.x, min_y = c.y, max_x = c.x, max_y = c.y, bname = p.bname
				}
			else:
				var b = bld_cells[p.btype]
				b.min_x = min(b.min_x, c.x); b.min_y = min(b.min_y, c.y)
				b.max_x = max(b.max_x, c.x); b.max_y = max(b.max_y, c.y)

	for btype in bld_cells:
		var b = bld_cells[btype]
		var w = b.max_x - b.min_x + 1
		var h = b.max_y - b.min_y + 1
		building_info[Vector2i(b.min_x, b.min_y)] = {
			name = b.bname, type = btype, w = w, h = h
		}
		labels.append({pos = Vector2(b.min_x, b.min_y), text = b.bname})

	# Los carteles de calle/lugar son nodos Cartel (scenes/world/cartel.tscn):
	# se colocan y editan en el editor, y se dibujan solos.

	# La capa de swatches es solo dato: en runtime se oculta y dibujamos el arte real.
	layer.visible = false

	# Construir la grilla A* con bloqueadores estáticos (tiles no caminables + Lugar/Puesto)
	_build_astar()

	# Registrar interactuables estáticos (objetos, etc.) en la grilla de ocupación
	_register_static_interactables()

	queue_redraw()


# ==================== A* Y OCUPACIÓN ====================

func _build_astar() -> void:
	"""Construye la grilla A* con región = mapa, marca bloqueadores estáticos."""
	var region = Rect2i(0, 0, MAP_W, MAP_H)
	astar.region = region
	astar.cell_size = Vector2(T, T)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()  # Inicializa la grilla

	# Marcar como sólidas (no walkable) todas las celdas que no son transitables estáticas
	for y in MAP_H:
		for x in MAP_W:
			if not _es_transitable_estatica_sin_astar(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)


func _es_transitable_estatica_sin_astar(celda: Vector2i) -> bool:
	"""Verifica si una celda es transitableestatica (sin considerar ocupación dinámica)."""
	var tile = get_tile(celda.x, celda.y)
	# Tiles caminables: GRASS, ROAD, PLAZA, SIDEWALK, PLATFORM
	if tile not in [Tile.GRASS, Tile.ROAD, Tile.PLAZA, Tile.SIDEWALK, Tile.PLATFORM]:
		return false

	# Verificar si Lugar o Puesto la bloquea
	for child in get_children():
		if child.has_method("bloquea") and child.bloquea(celda.x, celda.y):
			return false

	return true


func _register_static_interactables() -> void:
	"""Registra objetos estáticos con interact() en la grilla de ocupación."""
	for child in get_children():
		if child.has_method("interact") and not child is CharacterBody2D:
			# Es un interactuable estático (no el player)
			var celda = celda_de(child.position)
			ocupacion.reservar(celda, child)


func celda_de(world_pos: Vector2) -> Vector2i:
	"""Convierte posición mundial a celda de grilla."""
	return Vector2i(int(world_pos.x) / T, int(world_pos.y) / T)


func pos_de(celda: Vector2i) -> Vector2:
	"""Convierte celda de grilla a centro de tile en posición mundial."""
	return Vector2(celda.x * T + T / 2.0, celda.y * T + T / 2.0)


func es_transitable_estatica(celda: Vector2i) -> bool:
	"""Verifica si una celda es transitables táticamente (sin ocupantes dinámicos)."""
	return _es_transitable_estatica_sin_astar(celda)


func camino(desde: Vector2i, hasta: Vector2i, esquivar_ocupadas: bool = false) -> Array[Vector2i]:
	"""Calcula el camino óptimo usando A*. Devuelve lista de celdas (sin incluir origen).
	Con esquivar_ocupadas, las celdas ocupadas en este momento cuentan como obstáculo
	(se marcan sólidas sólo durante el cálculo)."""
	var tapadas: Array = []
	if esquivar_ocupadas:
		for c in ocupacion.celdas_ocupadas():
			if c != desde and c != hasta and astar.is_in_boundsv(c) and not astar.is_point_solid(c):
				astar.set_point_solid(c, true)
				tapadas.append(c)
	var path = astar.get_id_path(desde, hasta)
	for c in tapadas:
		astar.set_point_solid(c, false)
	var result: Array[Vector2i] = []
	for i in range(1, path.size()):  # Saltar el primer punto (origen)
		result.append(path[i])
	return result


# ==================== POIs ====================

func _create_pois():
	"""Recolecta los PuntoInteres colocados como hijos en la escena (spec 0010)."""
	pois.clear()
	poi_por_id.clear()
	for child in get_children():
		if child is PuntoInteres:
			pois.append(child)
			poi_por_id[child.poi_id] = child


## Hora real fija para tests (-1 = usar la hora actual de Argentina).
var hora_real_fija: float = -1.0


func hora_real() -> float:
	return hora_real_fija if hora_real_fija >= 0.0 else EstiloMapa.hora_argentina_ahora()


func estilo_actual() -> String:
	return EstiloMapa.estilo_para_hora(hora_real())


## Estilo del mapa en tiempo real (ADR-0004): un CanvasModulate tiñe el mapa según la
## hora actual de Argentina (mañana, tarde o noche), no según el reloj del juego.
func _iniciar_ciclo_dia() -> void:
	var tinte := CanvasModulate.new()
	tinte.name = "TinteDia"
	add_child(tinte)
	_actualizar_tinte()
	if not WorldClock.tick.is_connected(_on_tick_tinte):
		WorldClock.tick.connect(_on_tick_tinte)


func _on_tick_tinte(_minutos: int) -> void:
	_actualizar_tinte()


func _actualizar_tinte() -> void:
	var tinte = get_node_or_null("TinteDia")
	if tinte:
		tinte.color = EstiloMapa.tinte(hora_real())


## Catálogo de misiones: cada NPC que encarga una misión (no los ayudantes) aporta una entrada.
func _cargar_catalogo_misiones() -> void:
	var cat := {}
	for child in get_children():
		if "mision_id" in child and child.mision_id != "" and child.otorga_item == "":
			cat[child.mision_id] = {"giver": child.npc_name, "recompensa": child.recompensa_item}
	GameManager.catalogo = cat


func _iniciar_vida_social() -> void:
	_vecinos.clear()
	for child in get_children():
		if child.has_method("disponible_para_charlar"):
			_vecinos.append(child)
	if not WorldClock.tick.is_connected(_on_tick_social):
		WorldClock.tick.connect(_on_tick_social)


## Junta a vecinos adyacentes cuando al menos uno tiene ganas de charlar y el otro está
## disponible: intercambian novedades y suman relación.
func _on_tick_social(_minutos: int) -> void:
	var ahora: int = WorldClock.minutos
	var libres: Array = _vecinos.filter(func(n): return is_instance_valid(n) and n.disponible_para_charlar())
	for i in libres.size():
		var a = libres[i]
		if a.charlando():
			continue
		for j in range(i + 1, libres.size()):
			var b = libres[j]
			if b.charlando():
				continue
			if not (a.quiere_charlar() or b.quiere_charlar()):
				continue
			var d: Vector2i = a.celda_logica() - b.celda_logica()
			if maxi(absi(d.x), absi(d.y)) != 1:  # adyacentes, incluso en diagonal
				continue
			var clave := "%s|%s" % [a.npc_name, b.npc_name]
			if ahora - int(_ultima_charla.get(clave, -ESPERA_ENTRE_CHARLAS)) < ESPERA_ENTRE_CHARLAS:
				continue
			MemoriaNPC.charlar(a.memoria, a.npc_name, b.memoria, b.npc_name, ahora)
			a.iniciar_charla(b, MINUTOS_CHARLA)
			b.iniciar_charla(a, MINUTOS_CHARLA)
			_ultima_charla[clave] = ahora
			charlas_totales += 1
			break


# ==================== GUARDADO (spec 0010 F4 + spec 0005) ====================

func _iniciar_guardado() -> void:
	GameManager.mundo_activo = self
	if GameManager.cargar_al_iniciar:
		GameManager.cargar_al_iniciar = false
		# Mientras se restaura no se autoguarda: pisaría la partida con un mundo a medio cargar.
		GameManager.restaurando = true
		var datos := GameManager.leer_partida()
		if not datos.is_empty():
			restaurar(datos.get("mundo", {}))
		GameManager.restaurando = false
	if not GameManager.victoria_lograda.is_connected(_fiesta_en_la_plaza):
		GameManager.victoria_lograda.connect(_fiesta_en_la_plaza)
	if not GameManager.final_cerrado.is_connected(_terminar_fiesta):
		GameManager.final_cerrado.connect(_terminar_fiesta)
	if not GameManager.mision_cambiada.is_connected(_on_mision_autoguardado):
		GameManager.mision_cambiada.connect(_on_mision_autoguardado)


# ==================== HISTORIA (spec 0008) ====================

const CELDA_FUENTE := Vector2i(22, 33)     # fuente de la Plaza Mitre
const RADIO_LLEGADA := 4
var _en_fiesta := false

## Álbum completo: todo el barrio va a la Plaza Mitre a recibir a Monti.
func _fiesta_en_la_plaza() -> void:
	_en_fiesta = true
	for n in _vecinos:
		if is_instance_valid(n):
			n.convocar(CELDA_FUENTE)


## Cuando Monti llega a la plaza durante la fiesta, aparece la pantalla final.
func _revisar_llegada_a_la_fiesta() -> void:
	if not _en_fiesta or (GameManager.final and GameManager.final.visible):
		return
	var player = get_node_or_null("Player")
	if player == null:
		return
	var d: Vector2i = celda_de(player.position) - CELDA_FUENTE
	if absi(d.x) + absi(d.y) <= RADIO_LLEGADA:
		GameManager.mostrar_final()


func _terminar_fiesta() -> void:
	_en_fiesta = false
	for n in _vecinos:
		if is_instance_valid(n):
			n.liberar_convocatoria()


func _exit_tree() -> void:
	if GameManager.mundo_activo == self:
		GameManager.mundo_activo = null


func _on_mision_autoguardado(_a = null, _b = null) -> void:
	GameManager.autoguardar()


## Foto completa del mundo vivo: reloj, jugador, NPCs, objetos tomados y vida social.
func snapshot() -> Dictionary:
	var npcs := {}
	for n in _vecinos:
		if is_instance_valid(n):
			npcs[String(n.name)] = n.a_dict()
	var player = get_node_or_null("Player")
	var celda_player: Vector2i = celda_de(player.position) if player else Vector2i.ZERO
	return {
		"reloj": WorldClock.a_dict(),
		"jugador": {"celda": [celda_player.x, celda_player.y],
			"facing": [player.facing.x, player.facing.y] if player else [0, 1]},
		"npcs": npcs,
		"charlas_totales": charlas_totales,
		"ultima_charla": _ultima_charla.duplicate(),
		"bicis": _snapshot_bicis(player),
	}


## Por cada bici: dónde está estacionada y si el jugador va montado en ella.
func _snapshot_bicis(player) -> Dictionary:
	var bicis := {}
	for child in get_children():
		if child.has_method("es_bici"):
			var montada: bool = player != null and player._bici_ref == child
			bicis[String(child.name)] = {"pos": [child.position.x, child.position.y], "montada": montada}
	return bicis


func _restaurar_bicis(datos: Dictionary, player) -> void:
	for nombre in datos:
		var n := str(nombre)
		if n.validate_node_name() != n or not has_node(n):
			continue
		var bici = get_node(n)
		if not bici.has_method("es_bici"):
			continue
		var b: Dictionary = datos[nombre]
		var pos = b.get("pos", [])
		if pos.size() == 2:
			bici.position = Vector2(float(pos[0]), float(pos[1]))
		if bool(b.get("montada", false)) and player:
			player.montar_bici(bici)


func restaurar(d: Dictionary) -> void:
	if d.is_empty():
		return
	WorldClock.desde_dict(d.get("reloj", {}))
	# Objetos que el jugador ya levantó: no reaparecen y liberan su celda.
	# Los nombres vienen del archivo de guardado: sólo se aceptan nombres simples de nodos
	# hijos (sin rutas) que sean objetos levantables.
	for nombre in GameManager.objetos_tomados:
		var n := str(nombre)
		if n.is_empty() or n.validate_node_name() != n or not has_node(n):
			continue
		var obj = get_node(n)
		if "item" in obj and obj.has_method("interact"):
			ocupacion.liberar(celda_de(obj.position), obj)
			remove_child(obj)
			obj.queue_free()
	# Dos pasadas: primero todos sueltan sus celdas y después cada uno toma las guardadas.
	var datos_npcs: Dictionary = d.get("npcs", {})
	for n in _vecinos:
		n.soltar_celdas()
	var player = get_node_or_null("Player")
	if player:
		for c in ocupacion.celdas_de(player):
			ocupacion.liberar(c, player)
	for n in _vecinos:
		if datos_npcs.has(String(n.name)):
			n.restaurar(datos_npcs[String(n.name)])
		else:
			ocupacion.reservar(n.celda_logica(), n)
	if player:
		var j: Dictionary = d.get("jugador", {})
		var c = j.get("celda", [])
		if c.size() == 2:
			player.colocar_en(Vector2i(int(c[0]), int(c[1])))
		var f = j.get("facing", [0, 1])
		player.facing = Vector2(float(f[0]), float(f[1]))
	_restaurar_bicis(d.get("bicis", {}), player)
	charlas_totales = int(d.get("charlas_totales", 0))
	_ultima_charla.clear()
	var uc: Dictionary = d.get("ultima_charla", {})
	for k in uc:
		_ultima_charla[str(k)] = int(uc[k])


# ==================== HELPERS ====================

func set_tile(x: int, y: int, tile: int):
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		tiles[y * MAP_W + x] = tile


func get_tile(x: int, y: int) -> int:
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		return tiles[y * MAP_W + x]
	return Tile.BUILDING


func _bld(x: int, y: int, w: int, h: int, label: String):
	for dy in h:
		for dx in w:
			if get_tile(x + dx, y + dy) == Tile.GRASS:
				set_tile(x + dx, y + dy, Tile.BUILDING)
	if label != "":
		labels.append({pos = Vector2(x, y), text = label})


func _bld_special(x: int, y: int, w: int, h: int, label: String, btype: String):
	_bld(x, y, w, h, label)
	building_info[Vector2i(x, y)] = {name = label, type = btype, w = w, h = h}


# ==================== RENDERING ====================

func _draw():
	for y in MAP_H:
		for x in MAP_W:
			_draw_tile(x, y)
	_draw_fuente_octogonal()
	_draw_special_buildings()
	_draw_labels()


func _draw_tile(x: int, y: int):
	var r := Rect2(x * T, y * T, T, T)
	match get_tile(x, y):
		Tile.GRASS:
			draw_rect(r, Pal.GRASS)
			if (x * 7 + y * 3) % 5 == 0:
				draw_line(Vector2(x*T+5, y*T+3), Vector2(x*T+5, y*T+9), Pal.GRASS_DK, 1.0)
			if (x * 3 + y * 11) % 7 == 0:
				draw_line(Vector2(x*T+11, y*T+6), Vector2(x*T+11, y*T+12), Pal.GRASS_DK, 1.0)
		Tile.BUILDING:
			_draw_building(x, y, r)
		Tile.ROAD:
			_draw_road(x, y, r)
		Tile.SIDEWALK:
			draw_rect(r, Pal.SIDEWALK)
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), Pal.SIDEWALK_DK)
		Tile.TREE:
			draw_rect(r, Pal.GRASS)
			draw_rect(Rect2(x*T+6, y*T+10, 4, 6), Pal.WOOD)
			draw_circle(Vector2(x*T+8, y*T+6), 6.0, Pal.GRASS_DK)
			draw_circle(Vector2(x*T+7, y*T+5), 4.0, Pal.GRASS)
		Tile.OMBU:
			draw_rect(r, Pal.GRASS)
			draw_rect(Rect2(x*T+5, y*T+10, 6, 6), Pal.WOOD_DK)
			draw_circle(Vector2(x*T+8, y*T+5), 7.0, Pal.GRASS_DK)
			draw_circle(Vector2(x*T+6, y*T+4), 3.0, Pal.YELLOW)
			draw_circle(Vector2(x*T+10, y*T+6), 3.0, Pal.GRASS)
		Tile.RAIL:
			_draw_rail(x, y, r)
		Tile.PLATFORM:
			draw_rect(r, Pal.SIDEWALK)
			draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), Pal.SIDEWALK_DK)
			draw_line(Vector2(x*T, y*T), Vector2(x*T+T, y*T), Pal.YELLOW, 2.0)
		Tile.PLAZA:
			draw_rect(r, Pal.WALL_TAN)
			draw_rect(Rect2(x*T+1, y*T+1, 6, 6), Pal.WHITE)
			draw_rect(Rect2(x*T+9, y*T+9, 6, 6), Pal.WHITE)
		Tile.WATER:
			_draw_fountain(x, y, r)
		Tile.MONUMENT:
			draw_rect(r, Pal.WALL_TAN)
			draw_rect(Rect2(x*T+4, y*T+8, 8, 8), Pal.ROAD)
			draw_rect(Rect2(x*T+5, y*T+9, 6, 6), Pal.ROAD_DK)
			draw_rect(Rect2(x*T+6, y*T+3, 4, 6), Pal.ROAD_DK)
			draw_circle(Vector2(x*T+8, y*T+3), 3.0, Pal.ROAD_DK)
		Tile.BENCH:
			draw_rect(r, Pal.WALL_TAN)
			draw_rect(Rect2(x*T+2, y*T+6, 12, 2), Pal.WOOD)


func _draw_building(x: int, y: int, r: Rect2):
	var pick = (x * 5 + y * 3) % 3
	var body = Pal.BRICK
	if pick == 1:
		body = Pal.WALL_TAN
	elif pick == 2:
		body = Pal.ROOF
	draw_rect(r, Pal.BRICK_DK)
	draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), body)
	draw_rect(Rect2(x*T, y*T, T, 3), Pal.BRICK_DK)
	if (x + y) % 3 == 0:
		draw_rect(Rect2(x*T+3, y*T+5, 4, 5), Pal.SKY)
		draw_rect(Rect2(x*T+9, y*T+5, 4, 5), Pal.SKY)
		draw_rect(Rect2(x*T+3, y*T+5, 4, 5), Pal.WHITE, false, 1.0)
		draw_rect(Rect2(x*T+9, y*T+5, 4, 5), Pal.WHITE, false, 1.0)
	elif (x + y) % 3 == 1:
		draw_rect(Rect2(x*T+5, y*T+6, 6, 10), Pal.WOOD_DK)
		draw_rect(Rect2(x*T+6, y*T+7, 4, 8), Pal.WOOD)


func _draw_road(x: int, y: int, r: Rect2):
	draw_rect(r, Pal.ROAD)
	var up := get_tile(x, y - 1) == Tile.ROAD
	var dn := get_tile(x, y + 1) == Tile.ROAD
	var lf := get_tile(x - 1, y) == Tile.ROAD
	var rt := get_tile(x + 1, y) == Tile.ROAD
	if (up or dn) and not lf and not rt:
		# Corredor vertical (ej. Alem): línea de centro punteada
		draw_line(Vector2(x*T+T-1, y*T), Vector2(x*T+T-1, y*T+T), Pal.ROAD_DK, 1.0)
		if y % 3 != 0:
			draw_line(Vector2(x*T+8, y*T+2), Vector2(x*T+8, y*T+T-2), Pal.ROAD_LINE, 1.0)
	elif (lf or rt) and not up and not dn:
		# Corredor horizontal: línea de centro punteada
		draw_line(Vector2(x*T, y*T+T-1), Vector2(x*T+T, y*T+T-1), Pal.ROAD_DK, 1.0)
		if x % 3 != 0:
			draw_line(Vector2(x*T+2, y*T+8), Vector2(x*T+T-2, y*T+8), Pal.ROAD_LINE, 1.0)
	else:
		# Diagonales / cruces: empedrado punteado
		if (x + y) % 2 == 0:
			draw_rect(Rect2(x*T+6, y*T+6, 4, 4), Pal.ROAD_LINE)


func _draw_rail(x: int, y: int, r: Rect2):
	draw_rect(r, Pal.ROAD_DK)
	for i in 4:
		draw_rect(Rect2(x*T + i*4, y*T+1, 2, T-2), Pal.WOOD_DK)
	draw_line(Vector2(x*T, y*T+4), Vector2(x*T+T, y*T+4), Pal.WHITE, 1.0)
	draw_line(Vector2(x*T, y*T+12), Vector2(x*T+T, y*T+12), Pal.WHITE, 1.0)


## Cada celda de agua se pinta como piso de plaza; la fuente se dibuja entera encima
## (octogonal, celeste con borde blanco, como la de la Plaza Mitre real).
func _draw_fountain(x: int, y: int, r: Rect2):
	draw_rect(r, Pal.WALL_TAN)


## Rectángulo (en celdas) que ocupa la fuente: el bloque de agua de la plaza.
func fuente_rect() -> Rect2i:
	var minimo := Vector2i(MAP_W, MAP_H)
	var maximo := Vector2i(-1, -1)
	for y in MAP_H:
		for x in MAP_W:
			if get_tile(x, y) == Tile.WATER:
				minimo = Vector2i(mini(minimo.x, x), mini(minimo.y, y))
				maximo = Vector2i(maxi(maximo.x, x), maxi(maximo.y, y))
	if maximo.x < 0:
		return Rect2i()
	return Rect2i(minimo, maximo - minimo + Vector2i.ONE)


## Octógono de la fuente en coordenadas del mundo (esquinas recortadas un tercio de celda).
func fuente_octogono() -> PackedVector2Array:
	var f := fuente_rect()
	var r := Rect2(f.position * T, f.size * T)
	var c := float(T)
	return PackedVector2Array([
		r.position + Vector2(c, 0), r.position + Vector2(r.size.x - c, 0),
		r.position + Vector2(r.size.x, c), r.position + Vector2(r.size.x, r.size.y - c),
		r.position + Vector2(r.size.x - c, r.size.y), r.position + Vector2(c, r.size.y),
		r.position + Vector2(0, r.size.y - c), r.position + Vector2(0, c),
	])


func _draw_fuente_octogonal() -> void:
	var oct := fuente_octogono()
	if oct.size() != 8:
		return
	var centro := Vector2.ZERO
	for p in oct:
		centro += p / 8.0
	draw_colored_polygon(oct, Pal.WHITE)                                   # borde blanco
	var agua := PackedVector2Array()
	for p in oct:
		agua.append(centro + (p - centro) * 0.86)
	draw_colored_polygon(agua, Color("8fd8f8"))                              # celeste
	var t := int(Time.get_ticks_msec() / 300.0)
	var colores := [Color("ffd23c"), Color("f06aa8"), Color("6ab0f0")]       # chorros con luces de colores
	for i in 3:
		var alto_chorro := 6 + ((t + i) % 3) * 2
		var x := centro.x - 8 + i * 8
		draw_rect(Rect2(x, centro.y - alto_chorro, 2, alto_chorro), colores[i])
	var ola := t % 4
	draw_line(Vector2(centro.x - 14 + ola, centro.y + 10), Vector2(centro.x - 8 + ola, centro.y + 10), Pal.WHITE, 1.0)


func _draw_special_buildings():
	var font = ThemeDB.fallback_font
	if not font:
		return
	for pos in building_info:
		var info = building_info[pos]
		var bx = pos.x * T
		var by = pos.y * T
		var bw = info.w * T
		var bh = info.h * T
		match info.type:
			"station":
				# Estacion: paredes blancas + techo verde oscuro (tapa el ladrillo generico)
				var green := Pal.GRASS_DK.darkened(0.3)
				draw_rect(Rect2(bx, by, bw, bh), Color("c6c8cc"))                    # paredes gris claro
				draw_rect(Rect2(bx, by, bw, bh), Pal.BLACK, false, 1.0)              # contorno
				draw_rect(Rect2(bx - 2, by, bw + 4, 8), green)                       # techo con alero
				draw_rect(Rect2(bx - 2, by + 8, bw + 4, 1), green.darkened(0.25))    # sombra del alero
				var dcx: float = bx + bw / 2.0
				draw_rect(Rect2(dcx - 5, by + bh - 12, 10, 12), Pal.WOOD_DK)         # puerta
				draw_rect(Rect2(dcx - 4, by + bh - 11, 8, 11), Pal.WOOD)
				draw_rect(Rect2(dcx - 1, by + bh - 11, 1, 11), Pal.WOOD_DK)          # doble hoja
				for i in range(info.w):                                             # ventanas
					var wcx: float = bx + i * T + T / 2.0
					if absf(wcx - dcx) < 14:
						continue
					draw_rect(Rect2(wcx - 3, by + 11, 6, 7), Pal.SKY)
					draw_rect(Rect2(wcx - 3, by + 11, 6, 7), Pal.BLACK, false, 1.0)
					draw_rect(Rect2(wcx, by + 11, 1, 7), Pal.WHITE)                  # cruceta
			"teatro":
				draw_rect(Rect2(bx, by, bw, 4), Pal.YELLOW)
			"restaurant":
				for i in range(info.w):
					var col = Pal.RED if i % 2 == 0 else Pal.WHITE
					draw_rect(Rect2(bx+i*T, by, T, 3), col)
			"fastfood":
				draw_rect(Rect2(bx, by, bw, 3), Pal.YELLOW)
			"club":
				draw_rect(Rect2(bx, by, bw, 3), Pal.BLUE)
				draw_rect(Rect2(bx+T, by+T, T*3, 2), Pal.WHITE)
			"studio":
				draw_rect(Rect2(bx, by, bw, 3), Pal.PURPLE)
			"church":
				var ccx = bx + bw / 2.0
				draw_rect(Rect2(ccx - 1, by - 7, 2, 9), Pal.WHITE)
				draw_rect(Rect2(ccx - 3, by - 4, 6, 2), Pal.WHITE)
				draw_rect(Rect2(ccx - 3, by + bh - 7, 6, 7), Pal.WALL_TAN)
			"govt":
				draw_rect(Rect2(bx, by, bw, 3), Pal.BLUE)
				draw_line(Vector2(bx, by), Vector2(bx + bw, by), Pal.WHITE, 2.0)
				for ci in range(info.w):
					draw_rect(Rect2(bx + ci * T + 6, by + 4, 2, bh - 6), Pal.WHITE)
			"school":
				draw_rect(Rect2(bx, by, bw, 4), Pal.WHITE)
				draw_rect(Rect2(bx + 4, by - 8, 1, 8), Pal.WOOD_DK)
				draw_rect(Rect2(bx + 5, by - 8, 7, 2), Pal.SKY)
				draw_rect(Rect2(bx + 5, by - 6, 7, 2), Pal.WHITE)
				draw_rect(Rect2(bx + 5, by - 4, 7, 2), Pal.SKY)
			"police":
				draw_rect(Rect2(bx, by, bw, 4), Pal.BLUE)
				draw_rect(Rect2(bx + bw / 2.0 - 3, by + 4, 6, 3), Pal.RED)
			"watertower":
				# tapar el ladrillo del footprint (El Tanque va sobre verde/plaza)
				draw_rect(Rect2(bx, by, bw, bh), Pal.GRASS)
				_draw_tanque(bx + bw / 2.0, by + bh)


# El Tanque: torre de agua tipo hongo (columna con mural + copa ancha).
# cx = centro X, ground = Y del suelo (base). Se dibuja hacia arriba.
func _draw_tanque(cx: float, ground: float):
	TanqueArt.draw_on(self, cx, ground)


func _draw_labels():
	var font = ThemeDB.fallback_font
	if not font:
		return
	for lbl in labels:
		var pos = Vector2(lbl.pos.x * T + 2, lbl.pos.y * T + 10)
		var tw = lbl.text.length() * 4 + 4
		draw_rect(Rect2(pos.x - 2, pos.y - 8, tw + 2, 11), Pal.WHITE)
		draw_rect(Rect2(pos.x - 3, pos.y - 9, tw + 4, 13), Pal.BLACK, false, 1.0)
		draw_string(font, pos, lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Pal.BLACK)


# ==================== TILE-BASED COLLISION ====================

func is_walkable(world_pos: Vector2) -> bool:
	"""Verifica si una posición es caminable: estáticamente transitable + sin ocupantes dinámicos."""
	var celda = celda_de(world_pos)
	return es_transitable_estatica(celda) and ocupacion.esta_libre(celda)


func get_npc_at(world_pos: Vector2):
	"""Devuelve el interactuable (NPC u objeto) en una posición, si existe."""
	var celda = celda_de(world_pos)
	var ocupante = ocupacion.ocupante(celda)
	if ocupante and ocupante.has_method("interact"):
		return ocupante
	return null


# ==================== PLAYER & NPCs ====================

func _spawn_player():
	var player = preload("res://scenes/player/player.tscn").instantiate()
	player.position = _station_exit_pos()
	add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	# franja reservada arriba para el HUD (barra sólida 24px + safe area del notch)
	cam.limit_top = -int(GameManager.safe_top_frac() * get_viewport_rect().size.y + 24.0)
	cam.limit_right = MAP_W * T
	cam.limit_bottom = MAP_H * T  # controles flotantes: el mapa se ve completo abajo


# El jugador arranca "saliendo de la estación": busca el edificio de la estación
# y baja hasta el primer tile caminable debajo de su centro.
func _station_exit_pos() -> Vector2:
	for anchor in building_info:
		var b = building_info[anchor]
		if b.type == "station":
			var cx: int = anchor.x + int(b.w / 2.0)
			var exit_y: int = anchor.y + b.h   # fila de la vereda, justo debajo de la estación
			# Arrancar SOBRE la vereda, al lado de Marcos (no en la calle de abajo):
			# probar tiles caminables en esa fila, cerca del centro.
			for dx in [-1, 1, -2, 2, -3, 3, 0]:
				var side := Vector2((cx + dx) * T + T / 2.0, exit_y * T + T / 2.0)
				if is_walkable(side):
					return side
			# Fallback: bajar hasta el primer tile caminable
			for y in range(exit_y, MAP_H):
				var below := Vector2(cx * T + T / 2.0, y * T + T / 2.0)
				if is_walkable(below):
					return below
	# Fallback: centro del mapa arriba
	return Vector2(int(MAP_W / 2.0) * T + T / 2.0, 8 * T + T / 2.0)


# ==================== PUERTAS A OTROS MAPAS (spec 0006, ADR-0005) ====================

func portales() -> Array:
	return get_children().filter(func(n): return n is Portal)


func portal_en(celda: Vector2i):
	for p in portales():
		if p.celda() == celda:
			return p
	return null


## Caminar contra una puerta lleva a su mapa; Monti vuelve a aparecer en la vereda.
func cruzar_portal(celda: Vector2i, quien: Node) -> bool:
	var portal = portal_en(celda)
	if portal == null or portal.destino == "":
		return false
	GameManager.ir_a_mapa(portal.destino, celda_de(quien.position))
	return true


func _add_dialog_box():
	add_child(preload("res://scenes/ui/dialog_box.tscn").instantiate())


func _process(delta):
	if _en_fiesta:
		_revisar_llegada_a_la_fiesta()
	_redraw_timer += delta
	if _redraw_timer >= 0.3:
		_redraw_timer = 0.0
		queue_redraw()
