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

enum Tile {
	GRASS, BUILDING, ROAD, TREE, RAIL, PLAZA, WATER,
	SIDEWALK, MONUMENT, BENCH, PLATFORM, OMBU
}

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
	{name = "estacion",  tile = Tile.BUILDING, btype = "station",    bname = "ESTACION DE MONTE GRANDE",  color = Color("e03020")},
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


func _ready():
	_load_map()
	_spawn_player()
	_add_dialog_box()
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
	queue_redraw()


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


func _draw_fountain(x: int, y: int, r: Rect2):
	draw_rect(r, Pal.WATER_DK)
	draw_rect(Rect2(x*T+2, y*T+2, T-4, T-4), Pal.WATER)
	var t = int(Time.get_ticks_msec() / 300.0)
	var jet_h = 3 + (t % 3)
	draw_rect(Rect2(x*T+7, y*T+8-jet_h, 2, jet_h), Pal.WHITE)
	var wave = t % 4
	draw_line(Vector2(x*T+3+wave, y*T+10), Vector2(x*T+6+wave, y*T+10), Pal.WHITE, 1.0)


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
				draw_rect(Rect2(bx, by, bw, 4), Pal.RED)
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
	var rects = [
		[-12, -56, 24, 56, Color("d86a2c")],   # columna (mural)
		[-12, -36, 10, 36, Color("c0281c")],
		[-3, -46, 7, 46, Color("f5c518")],
		[5, -32, 8, 32, Color("c0281c")],
		[-1, -22, 5, 22, Color("201510")],
		[-9, -54, 7, 12, Color("2a8c7a")],
		[-12, -56, 24, 2, Color("8a5a2a")],
		[-18, -62, 36, 6, Color("8a6238")],    # embudo (se ensancha)
		[-26, -68, 52, 6, Color("9a7444")],
		[-34, -74, 68, 6, Color("a8845a")],
		[-40, -80, 80, 6, Color("b98f5a")],
		[-40, -92, 80, 12, Color("c9a877")],   # copa (tanque)
		[-40, -82, 80, 2, Color("7c5a34")],
		[-35, -92, 70, 3, Color("d8bf95")],
		[-30, -89, 3, 5, Color("6a4a28")],     # letra O
		[28, -89, 3, 5, Color("6a4a28")],      # letra S
		[-1, -98, 2, 6, Color("444444")],      # antena
		[-13, -3, 26, 3, Color("2a1e14")],     # base
	]
	for a in rects:
		draw_rect(Rect2(cx + a[0], ground + a[1], a[2], a[3]), a[4])


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
	var tx := int(world_pos.x) / T
	var ty := int(world_pos.y) / T
	var tile = get_tile(tx, ty)
	if tile not in [Tile.GRASS, Tile.ROAD, Tile.PLAZA, Tile.SIDEWALK, Tile.PLATFORM]:
		return false
	for child in get_children():
		if child.has_method("interact"):
			var ntx := int(child.position.x) / T
			var nty := int(child.position.y) / T
			if ntx == tx and nty == ty:
				return false
	return true


func get_npc_at(world_pos: Vector2):
	var tx := int(world_pos.x) / T
	var ty := int(world_pos.y) / T
	for child in get_children():
		if child.has_method("interact"):
			var ntx := int(child.position.x) / T
			var nty := int(child.position.y) / T
			if ntx == tx and nty == ty:
				return child
	return null


# ==================== PLAYER & NPCs ====================

func _spawn_player():
	var player = preload("res://scenes/player/player.tscn").instantiate()
	player.position = _station_exit_pos()
	add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * T
	cam.limit_bottom = MAP_H * T


# El jugador arranca "saliendo de la estación": busca el edificio de la estación
# y baja hasta el primer tile caminable debajo de su centro.
func _station_exit_pos() -> Vector2:
	for anchor in building_info:
		var b = building_info[anchor]
		if b.type == "station":
			var cx: int = anchor.x + int(b.w / 2.0)
			for y in range(anchor.y + b.h, MAP_H):
				var wp := Vector2(cx * T + T / 2.0, y * T + T / 2.0)
				if is_walkable(wp):
					return wp
	# Fallback: centro del mapa arriba
	return Vector2(int(MAP_W / 2.0) * T + T / 2.0, 8 * T + T / 2.0)


func _add_dialog_box():
	add_child(preload("res://scenes/ui/dialog_box.tscn").instantiate())


func _process(delta):
	_redraw_timer += delta
	if _redraw_timer >= 0.3:
		_redraw_timer = 0.0
		queue_redraw()
