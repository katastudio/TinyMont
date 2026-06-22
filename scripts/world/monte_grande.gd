extends Node2D
## Monte Grande - Plaza Mitre como corazón del centro.
## La plaza (rombo) está inscripta en una manzana enmarcada por un ANILLO de 4 calles:
##   - Av. L.N. Alem (oeste)  - Calle este
##   - Calle superior (Bv. Bs. As.)  - Calle inferior (Sta. Marina)
## Las 4 calles se CRUZAN en las 4 esquinas formando intersecciones (cruces).
## En cada lado cardinal, un edificio histórico: Comisaría (N), Iglesia (S),
## Municipalidad (O), Escuela N°1 (E). Alem baja desde la estación.

const T := 16
const MAP_W := 44
const MAP_H := 48

enum Tile {
	GRASS, BUILDING, ROAD, TREE, RAIL, PLAZA, WATER,
	SIDEWALK, MONUMENT, BENCH, PLATFORM, OMBU
}

var tiles := PackedInt32Array()
var labels: Array = []
var _redraw_timer := 0.0
var building_info := {}

# Anillo de la plaza: horizontales (superior/inferior) + verticales (Alem/este)
var h_road_ys := []
var v_road_xs := [13, 14]

const PLAZA_CX := 22
const PLAZA_CY := 33
const PLAZA_R := 7


func _ready():
	_build_map()
	_spawn_player()
	_spawn_npcs()
	_add_dialog_box()


# ==================== MAP CONSTRUCTION ====================

func _build_map():
	tiles.resize(MAP_W * MAP_H)
	tiles.fill(Tile.GRASS)
	_build_border()
	_lay_streets()
	_lay_sidewalks()
	_lay_tracks()
	_build_station()
	_fill_blocks()
	_build_plaza_mitre()
	_plant_trees()
	queue_redraw()


func _build_border():
	for x in MAP_W:
		set_tile(x, 0, Tile.TREE)
		set_tile(x, MAP_H - 1, Tile.TREE)
	for y in MAP_H:
		set_tile(0, y, Tile.TREE)
		set_tile(MAP_W - 1, y, Tile.TREE)


func _lay_streets():
	# La trama real es DIAGONAL (rotada 45°): la plaza se enmarca con un anillo
	# diagonal que sigue el rombo y 4 salidas en diagonal. Sin calles ortogonales.
	for y in MAP_H:
		for x in MAP_W:
			var d = abs(x - PLAZA_CX) + abs(y - PLAZA_CY)
			if d == 8 or d == 9:
				set_tile(x, y, Tile.ROAD)
	# 4 salidas diagonales (2 carriles) desde las esquinas del rombo
	_diag_avenue(17, 28, -1, -1, 10)  # NO -> Alem
	_diag_avenue(27, 28, 1, -1, 12)   # NE -> Bv. Bs. As.
	_diag_avenue(17, 38, -1, 1, 12)   # SO -> Sta. Marina
	_diag_avenue(27, 38, 1, 1, 12)    # SE -> Alem Doble
	# Alem sube (tramo vertical) hasta la estación — se detallará después
	for y in range(8, 25):
		set_tile(13, y, Tile.ROAD)
		set_tile(14, y, Tile.ROAD)
	# Carteles
	labels.append({pos = Vector2(8, 14), text = "ALEM"})
	labels.append({pos = Vector2(30, 22), text = "BV.BS AS"})
	labels.append({pos = Vector2(7, 41), text = "STA.MARINA"})
	labels.append({pos = Vector2(31, 41), text = "ALEM DOBLE"})


func _diag_avenue(sx: int, sy: int, dx: int, dy: int, n: int):
	for k in n:
		set_tile(sx + dx * k, sy + dy * k, Tile.ROAD)
		set_tile(sx + dx * k + dy, sy + dy * k + dx, Tile.ROAD)


func _lay_sidewalks():
	for sy in [10, 24, 26, 40, 42]:
		for x in MAP_W:
			if get_tile(x, sy) == Tile.GRASS:
				set_tile(x, sy, Tile.SIDEWALK)
	for sx in [12, 15, 29, 31]:
		for y in MAP_H:
			if get_tile(sx, y) == Tile.GRASS:
				set_tile(sx, y, Tile.SIDEWALK)


func _lay_tracks():
	for x in MAP_W:
		set_tile(x, 4, Tile.RAIL)
		set_tile(x, 5, Tile.RAIL)


func _build_station():
	for x in range(18, 24):
		set_tile(x, 6, Tile.PLATFORM)
		set_tile(x, 7, Tile.PLATFORM)
	labels.append({pos = Vector2(24, 7), text = "ESTACION MG"})
	_bld_special(18, 1, 6, 3, "ESTACION", "station")


func _fill_blocks():
	# Comercios cerca de la estación (no compiten con la plaza)
	_bld_special(6, 8, 4, 2, "TEATRO", "teatro")
	_bld_special(16, 13, 5, 3, "VENECIANA", "restaurant")
	_bld_special(24, 13, 5, 3, "MOSTAZA", "fastfood")
	_bld_special(2, 13, 6, 3, "KATA", "studio")
	_bld_special(36, 13, 5, 3, "CLUB ATL.", "club")

	# === 4 edificios históricos en los lados del rombo ===
	_bld_special(18, 20, 8, 3, "COMISARIA", "police")   # N
	_bld_special(18, 43, 8, 3, "IGLESIA", "church")     # S
	_bld_special(5, 30, 6, 6, "MUNICIPIO", "govt")      # O
	_bld_special(33, 30, 6, 6, "ESC.N1", "school")      # E


func _build_plaza_mitre():
	var cx := PLAZA_CX
	var cy := PLAZA_CY
	# Rombo (cuadrada en diagonal a las calles)
	for dy in range(-PLAZA_R, PLAZA_R + 1):
		var w = PLAZA_R - abs(dy)
		for dx in range(-w, w + 1):
			set_tile(cx + dx, cy + dy, Tile.PLAZA)
	# Cruz de mosaico
	for i in range(-PLAZA_R + 1, PLAZA_R):
		set_tile(cx + i, cy, Tile.SIDEWALK)
		set_tile(cx, cy + i, Tile.SIDEWALK)
	# Fuente octogonal central
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			set_tile(cx + dx, cy + dy, Tile.WATER)
	# Monumentos en las 4 diagonales
	for d in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(3, 3), Vector2i(-3, 3)]:
		set_tile(cx + d.x, cy + d.y, Tile.MONUMENT)
	# Ginkgo histórico (en los vértices N y S, hacia las calles)
	set_tile(cx - 4, cy, Tile.OMBU)
	set_tile(cx + 4, cy, Tile.OMBU)
	labels.append({pos = Vector2(cx - 3, cy - PLAZA_R - 1), text = "PLAZA MITRE"})


func _plant_trees():
	var positions = [
		Vector2i(19, 29), Vector2i(25, 29), Vector2i(19, 37), Vector2i(25, 37),
		Vector2i(9, 13), Vector2i(15, 8), Vector2i(29, 8), Vector2i(40, 9),
		Vector2i(9, 22), Vector2i(35, 22), Vector2i(9, 36), Vector2i(35, 36),
		Vector2i(22, 27), Vector2i(22, 39),
	]
	for pos in positions:
		if get_tile(pos.x, pos.y) in [Tile.GRASS, Tile.SIDEWALK]:
			set_tile(pos.x, pos.y, Tile.TREE)


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
	if x in v_road_xs:
		# Alem (tramo vertical): línea de centro punteada
		draw_line(Vector2(x*T+T-1, y*T), Vector2(x*T+T-1, y*T+T), Pal.ROAD_DK, 1.0)
		if y % 3 != 0:
			draw_line(Vector2(x*T+8, y*T+2), Vector2(x*T+8, y*T+T-2), Pal.ROAD_LINE, 1.0)
	else:
		# Calles diagonales: empedrado punteado
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
	player.position = Vector2(13 * T + T / 2, 10 * T + T / 2)
	add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * T
	cam.limit_bottom = MAP_H * T


func _spawn_npcs():
	_create_npc(Vector2(20, 31), "Don Carlos", [
		"¡Eh, pibe! Bienvenido\na la Plaza Mitre.",
		"Bajaste por Alem\ndesde la estacion,\n¿no? Es el eje.",
		"La plaza es de 1904\ny esta en diagonal\na las calles."
	], Pal.BLUE)

	_create_npc(Vector2(18, 16), "La Sole", [
		"¡Hola, vecino!",
		"¿Venis a La Veneciana?\nLa mejor pizza del\nconurbano sur."
	], Pal.RED)

	_create_npc(Vector2(20, 7), "El Pipe", [
		"Estoy esperando el\nRoca hace 40 minutos.",
		"Para alla va a El\nJaguel y Ezeiza."
	], Pal.YELLOW)

	_create_npc(Vector2(26, 18), "El Gordo", [
		"¡Vamo' el Club Atletico\nMonte Grande, papa!",
		"Aca se juega al futbol\ndesde 1911."
	], Pal.GRASS_DK)

	_create_npc(Vector2(18, 18), "Lucia", [
		"¡Hola! Trabajo en\nKata Studio.",
		"Estamos haciendo\nTinyMont, un juego\nsobre Monte Grande."
	], Pal.PURPLE)

	_create_npc(Vector2(24, 35), "Dona Rosa", [
		"¡Ay, nene! ¿No viste\na mi gato Mostaza?",
		"Es naranja con\nmanchas negras."
	], Pal.PINK)

	_create_npc(Vector2(21, 30), "Don Ramon", [
		"¿Sabias que ese\narbol es un Ginkgo\nbiloba?",
		"Por algo le dicen\nla Ciudad de los\nArboles."
	], Pal.WOOD)

	_create_npc(Vector2(8, 11), "Mili", [
		"¡Hoy hay funcion en\nel Teatro!",
		"Tango, folklore y\nteatro. No te lo\npierdas."
	], Pal.WATER)

	_create_npc(Vector2(13, 16), "Beto", [
		"Quiosco abierto las\n24hs sobre Alem.",
		"¿Un Manaos bien\nfrio, pibe?"
	], Pal.YELLOW)

	_create_npc(Vector2(17, 7), "Ruben", [
		"Diarios, revistas\ny figuritas, vecino.",
		"40 anios en este\npuesto de la estacion."
	], Pal.BRICK)

	_create_npc(Vector2(13, 20), "Walter", [
		"Manejo el 306, del\ncentro a Constitucion.",
		"¡SUBE adelante,\nBAJA atras!"
	], Pal.BLUE)

	_create_npc(Vector2(29, 20), "Dona Marta", [
		"¿Necesitas algo,\nnene? Tengo fiado\nsi sos del barrio."
	], Pal.PINK)

	_create_npc(Vector2(24, 31), "Tito", [
		"¿Jugas a las bochas,\npibe? Veni que armamos\nuna con los muchachos.",
		"La plaza no cambia,\npor suerte."
	], Pal.GRASS_DK)

	_create_npc(Vector2(22, 38), "El Chino", [
		"¡Choripan recien\nhecho! Con chimi\ncasero, jefe.",
		"¿Con o sin? Dale\nque se enfria."
	], Pal.RED)

	_create_npc(Vector2(22, 42), "Padre Quique", [
		"Bienvenido a la\nParroquia Inmaculada\nConcepcion, hijo.",
		"Los domingos hay\nmisa a las 10 y 19."
	], Pal.WHITE)


func _create_npc(tile_pos: Vector2, npc_name: String, lines: Array, color: Color):
	var npc = preload("res://scenes/npc/npc.tscn").instantiate()
	npc.position = Vector2(tile_pos.x * T + T / 2, tile_pos.y * T + T / 2)
	npc.npc_name = npc_name
	npc.dialog_lines = lines
	npc.npc_color = color
	add_child(npc)


func _add_dialog_box():
	add_child(preload("res://scenes/ui/dialog_box.tscn").instantiate())


func _process(delta):
	_redraw_timer += delta
	if _redraw_timer >= 0.3:
		_redraw_timer = 0.0
		queue_redraw()
