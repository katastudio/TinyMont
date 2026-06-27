extends Node2D
## Monte Grande - mapa cargado desde un PLANO DE TEXTO editable a mano.
##
## El mapa vive en res://data/map.txt y se edita con cualquier editor de texto:
## cada caracter es un tile. Ver la leyenda al principio de ese archivo.
## Este script SOLO lee ese plano; no calcula geografía. Para cambiar la ciudad,
## editá data/map.txt (no este código).

const T := 16
const MAP_PATH := "res://data/map.txt"

enum Tile {
	GRASS, BUILDING, ROAD, TREE, RAIL, PLAZA, WATER,
	SIDEWALK, MONUMENT, BENCH, PLATFORM, OMBU
}

# caracter de terreno -> Tile. Las LETRAS de edificio se resuelven por la leyenda.
const CHAR_TILE := {
	".": Tile.GRASS, "#": Tile.ROAD, ":": Tile.SIDEWALK, "T": Tile.TREE,
	"O": Tile.OMBU, "=": Tile.RAIL, "_": Tile.PLATFORM, "P": Tile.PLAZA,
	"~": Tile.WATER, "M": Tile.MONUMENT, "b": Tile.BENCH, " ": Tile.GRASS,
}

var MAP_W := 44
var MAP_H := 48

var tiles := PackedInt32Array()
var labels: Array = []
var _redraw_timer := 0.0
var building_info := {}


func _ready():
	_load_map()
	_spawn_player()
	_spawn_npcs()
	_add_dialog_box()


# ==================== CARGA DEL PLANO DE TEXTO ====================

func _load_map():
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir el plano: " + MAP_PATH)
		return
	var raw := f.get_as_text()
	f.close()

	var legend := {}   # letra -> {name, type}
	var grid: Array = []
	for line in raw.split("\n"):
		if line.begins_with(";"):
			_parse_legend_line(line, legend)
		elif line.strip_edges() == "" and grid.is_empty():
			continue  # líneas en blanco antes del grid
		else:
			grid.append(line)
	# recortar líneas en blanco finales
	while not grid.is_empty() and grid[grid.size() - 1].strip_edges() == "":
		grid.pop_back()

	MAP_H = grid.size()
	MAP_W = 0
	for row in grid:
		MAP_W = max(MAP_W, row.length())

	tiles.resize(MAP_W * MAP_H)
	tiles.fill(Tile.GRASS)

	# bounding box por letra de edificio
	var bld_cells := {}  # letra -> {min_x, min_y, max_x, max_y}
	for y in MAP_H:
		var row: String = grid[y]
		for x in MAP_W:
			var ch := " " if x >= row.length() else row[x]
			if legend.has(ch):
				set_tile(x, y, Tile.BUILDING)
				if not bld_cells.has(ch):
					bld_cells[ch] = {min_x = x, min_y = y, max_x = x, max_y = y}
				else:
					var b = bld_cells[ch]
					b.min_x = min(b.min_x, x); b.min_y = min(b.min_y, y)
					b.max_x = max(b.max_x, x); b.max_y = max(b.max_y, y)
			elif CHAR_TILE.has(ch):
				set_tile(x, y, CHAR_TILE[ch])
			# cualquier otro caracter queda como GRASS (default)

	# registrar edificios (anchor + tamaño) para render especial + cartel
	for ch in bld_cells:
		var b = bld_cells[ch]
		var info = legend[ch]
		var w = b.max_x - b.min_x + 1
		var h = b.max_y - b.min_y + 1
		building_info[Vector2i(b.min_x, b.min_y)] = {
			name = info.name, type = info.type, w = w, h = h
		}
		labels.append({pos = Vector2(b.min_x, b.min_y), text = info.name})

	queue_redraw()


func _parse_legend_line(line: String, legend: Dictionary):
	# Leyenda de edificio:  ";   S = ESTACION = station"
	var body := line.substr(1).strip_edges()
	if "=" in body and not body.begins_with("@"):
		var parts := body.split("=")
		if parts.size() >= 3:
			var letter := parts[0].strip_edges()
			if letter.length() == 1:
				legend[letter] = {
					name = parts[1].strip_edges(),
					type = parts[2].strip_edges(),
				}
				return
	# Carteles de calle:  "@ ALEM@8,14   @ BV.BS AS@30,22 ..."
	var re := RegEx.new()
	re.compile("@\\s*([^@]+?)@(\\d+),(\\d+)")
	for m in re.search_all(line):
		var txt := m.get_string(1).strip_edges()
		var lx := int(m.get_string(2))
		var ly := int(m.get_string(3))
		labels.append({pos = Vector2(lx, ly), text = txt})


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
