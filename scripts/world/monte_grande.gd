extends Node2D
## Monte Grande - "Ciudad de los Árboles"
## Centro real: estación Roca (vías NO-SE), Av. L.N. Alem (eje comercial),
## Plaza Mitre central (cuadrada, en diagonal a las calles) enmarcada por
## Boulevard Buenos Aires, Av. Las Heras, Sofía Terrero de Santamarina y Dardo Rocha.

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

# Calles reales. Horizontales = paralelas a las vías del Roca.
var h_road_ys := [14, 25, 40]   # Av. L.N. Alem, Boulevard Bs As, Av. Las Heras
var v_road_xs := [8, 15, 29, 36] # Máximo Paz, Sofía Terrero, Dardo Rocha, M. Acosta

# Plaza Mitre (rombo central)
const PLAZA_CX := 22
const PLAZA_CY := 32
const PLAZA_R := 6


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
	for y in h_road_ys:
		for x in MAP_W:
			set_tile(x, y, Tile.ROAD)
	for x in v_road_xs:
		for y in MAP_H:
			set_tile(x, y, Tile.ROAD)
	# Avenidas paralelas a las vías
	labels.append({pos = Vector2(17, 14), text = "AV.L.N.ALEM"})
	labels.append({pos = Vector2(16, 25), text = "BLVD.BS AS"})
	labels.append({pos = Vector2(17, 40), text = "AV.LAS HERAS"})
	# Calles transversales
	labels.append({pos = Vector2(8, 11), text = "MAXIMO PAZ"})
	labels.append({pos = Vector2(11, 21), text = "S.TERRERO"})
	labels.append({pos = Vector2(29, 21), text = "DARDO ROCHA"})
	labels.append({pos = Vector2(36, 11), text = "M.ACOSTA"})


func _lay_sidewalks():
	for sy in [13, 16, 24, 26, 39, 41]:
		for x in MAP_W:
			if get_tile(x, sy) == Tile.GRASS:
				set_tile(x, sy, Tile.SIDEWALK)
	for sx in [7, 9, 14, 16, 28, 30, 35, 37]:
		for y in MAP_H:
			if get_tile(sx, y) == Tile.GRASS:
				set_tile(sx, y, Tile.SIDEWALK)


func _lay_tracks():
	for x in MAP_W:
		if not (x in v_road_xs):
			set_tile(x, 6, Tile.RAIL)
			set_tile(x, 7, Tile.RAIL)


func _build_station():
	# Andén (caminable) bajo las vías
	for x in range(18, 25):
		set_tile(x, 8, Tile.PLATFORM)
		set_tile(x, 9, Tile.PLATFORM)
	labels.append({pos = Vector2(18, 9), text = "ESTACION MG"})
	# Edificio de la estación sobre las vías
	_bld_special(18, 3, 6, 3, "ESTACION", "station")


func _fill_blocks():
	# === Sobre las vías (y=2-5) ===
	_bld_special(9, 2, 4, 4, "TEATRO", "teatro")
	_bld(26, 2, 5, 4, "")
	_bld(32, 2, 4, 4, "")

	# === Entre andén y Av. Alem (y=10-12): zona gastronómica ===
	_bld_special(9, 10, 5, 3, "VENECIANA", "restaurant")
	_bld(17, 10, 4, 3, "")
	_bld_special(25, 10, 4, 3, "MOSTAZA", "fastfood")
	_bld(31, 10, 5, 3, "")

	# === Entre Alem y Boulevard (y=17-24): centro comercial ===
	_bld_special(9, 17, 5, 3, "KATA STUDIO", "studio")
	_bld(17, 17, 4, 3, "")
	_bld_special(24, 17, 5, 3, "CLUB ATL.", "club")
	_bld(31, 17, 5, 3, "")
	_bld(2, 17, 4, 7, "")
	_bld(38, 17, 4, 7, "")
	_bld(9, 21, 5, 3, "")
	_bld(17, 21, 4, 3, "")
	_bld(24, 21, 5, 3, "")
	_bld(31, 21, 5, 3, "")

	# === Flanqueando la Plaza Mitre (datos reales) ===
	_bld_special(9, 28, 5, 4, "PARROQUIA", "church")
	_bld_special(31, 28, 5, 4, "MUNICIPIO", "govt")
	_bld(2, 28, 4, 9, "")
	_bld(38, 28, 4, 9, "")

	# === Al sur de Las Heras (y=42+): residencial ===
	_bld(2, 42, 5, 4, "")
	_bld(9, 42, 6, 4, "")
	_bld(18, 42, 8, 4, "")
	_bld(29, 42, 6, 4, "")
	_bld(37, 42, 5, 4, "")


func _build_plaza_mitre():
	var cx := PLAZA_CX
	var cy := PLAZA_CY
	# Cuadrada pero en diagonal a las calles -> rombo
	for dy in range(-PLAZA_R, PLAZA_R + 1):
		var w = PLAZA_R - abs(dy)
		for dx in range(-w, w + 1):
			var px = cx + dx
			var py = cy + dy
			if px > 0 and px < MAP_W - 1 and py > 0 and py < MAP_H - 1:
				set_tile(px, py, Tile.PLAZA)
	# Caminos de mosaico blanco (cruz)
	for i in range(-PLAZA_R + 1, PLAZA_R):
		set_tile(cx + i, cy, Tile.SIDEWALK)
		set_tile(cx, cy + i, Tile.SIDEWALK)
	# Fuente octogonal central
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			set_tile(cx + dx, cy + dy, Tile.WATER)
	# Monumentos en las 4 diagonales
	set_tile(cx - 3, cy - 2, Tile.MONUMENT)
	set_tile(cx + 3, cy - 2, Tile.MONUMENT)
	set_tile(cx + 3, cy + 2, Tile.MONUMENT)
	set_tile(cx - 3, cy + 2, Tile.MONUMENT)
	# Ginkgo / ombú histórico
	set_tile(cx + 2, cy - 3, Tile.OMBU)
	set_tile(cx - 2, cy + 3, Tile.OMBU)
	# Bancos alrededor de la fuente
	set_tile(cx - 2, cy, Tile.BENCH)
	set_tile(cx + 2, cy, Tile.BENCH)
	set_tile(cx, cy - 2, Tile.BENCH)
	set_tile(cx, cy + 2, Tile.BENCH)
	labels.append({pos = Vector2(cx - 3, cy - PLAZA_R), text = "PLAZA MITRE"})


func _plant_trees():
	# "Ciudad de los Árboles"
	var positions = [
		Vector2i(20, 27), Vector2i(24, 27), Vector2i(20, 37), Vector2i(24, 37),
		Vector2i(17, 32), Vector2i(27, 32),
		Vector2i(11, 16), Vector2i(19, 16), Vector2i(27, 16), Vector2i(34, 16),
		Vector2i(11, 24), Vector2i(19, 24), Vector2i(27, 24), Vector2i(34, 24),
		Vector2i(11, 39), Vector2i(19, 39), Vector2i(27, 39), Vector2i(34, 39),
		Vector2i(6, 13), Vector2i(26, 13), Vector2i(34, 13),
		Vector2i(6, 30), Vector2i(34, 30),
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
			draw_rect(Rect2(x*T+2, y*T+8, 2, 4), Pal.WOOD)
			draw_rect(Rect2(x*T+12, y*T+8, 2, 4), Pal.WOOD)
			draw_rect(Rect2(x*T+3, y*T+3, 10, 2), Pal.WOOD_DK)


func _draw_building(x: int, y: int, r: Rect2):
	# Variación de color de fachada para alegrar el centro
	var pick = (x * 5 + y * 3) % 3
	var body = Pal.BRICK
	if pick == 1:
		body = Pal.WALL_TAN
	elif pick == 2:
		body = Pal.ROOF
	draw_rect(r, Pal.BRICK_DK)
	draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), body)
	# Techo
	draw_rect(Rect2(x*T, y*T, T, 3), Pal.BRICK_DK)
	# Ventanas / puerta
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
	var is_h = y in h_road_ys
	var is_v = x in v_road_xs
	if is_h and not is_v:
		draw_line(Vector2(x*T, y*T+T-1), Vector2(x*T+T, y*T+T-1), Pal.ROAD_DK, 1.0)
		if x % 3 != 0:
			draw_line(Vector2(x*T+2, y*T+8), Vector2(x*T+T-2, y*T+8), Pal.ROAD_LINE, 1.0)
	elif is_v and not is_h:
		draw_line(Vector2(x*T+T-1, y*T), Vector2(x*T+T-1, y*T+T), Pal.ROAD_DK, 1.0)
		if y % 3 != 0:
			draw_line(Vector2(x*T+8, y*T+2), Vector2(x*T+8, y*T+T-2), Pal.ROAD_LINE, 1.0)
	else:
		draw_line(Vector2(x*T+T-1, y*T), Vector2(x*T+T-1, y*T+T), Pal.ROAD_DK, 1.0)
		draw_line(Vector2(x*T, y*T+T-1), Vector2(x*T+T, y*T+T-1), Pal.ROAD_DK, 1.0)


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
	draw_line(Vector2(x*T+8-wave, y*T+12), Vector2(x*T+12-wave, y*T+12), Pal.WHITE, 1.0)


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
				draw_rect(Rect2(bx+T+4, by+T*2+4, T-8, T-4), Pal.YELLOW)
			"restaurant":
				for i in range(info.w):
					if i % 2 == 0:
						draw_rect(Rect2(bx+i*T, by, T, 3), Pal.RED)
					else:
						draw_rect(Rect2(bx+i*T, by, T, 3), Pal.WHITE)
			"fastfood":
				draw_rect(Rect2(bx, by, bw, 3), Pal.YELLOW)
			"club":
				draw_rect(Rect2(bx, by, bw, 3), Pal.BLUE)
				draw_rect(Rect2(bx+T, by+T, T*3, 2), Pal.WHITE)
			"studio":
				draw_rect(Rect2(bx, by, bw, 3), Pal.PURPLE)
				draw_rect(Rect2(bx+T+2, by+T+2, T*2-4, T-4), Pal.SKY)
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
	player.position = Vector2(21 * T + T / 2, 16 * T + T / 2)
	add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * T
	cam.limit_bottom = MAP_H * T


func _spawn_npcs():
	# Don Carlos - viejo de la plaza
	_create_npc(Vector2(20, 30), "Don Carlos", [
		"¡Eh, pibe! Bienvenido\na la Plaza Mitre.",
		"¿Ves ese busto?\nEs de Bartolomé Mitre.",
		"La plaza es de 1904\ny esta puesta en\ndiagonal a las calles.",
		"¡Monte Grande... la\nCiudad de los Árboles!"
	], Pal.BLUE)

	# La Sole - pizzera de La Veneciana (sobre Alem)
	_create_npc(Vector2(10, 13), "La Sole", [
		"¡Hola, vecino!",
		"¿Venis a La Veneciana?\nLa mejor pizza del\nconurbano sur.",
		"Estamos sobre Alem,\nel corazon comercial\nde Monte Grande."
	], Pal.RED)

	# El Pipe - esperando el Roca en el anden
	_create_npc(Vector2(21, 9), "El Pipe", [
		"Estoy esperando el\nRoca hace 40 minutos.",
		"De aca a Constitucion\nson 28 km... cuando\nel tren aparece.",
		"Para el otro lado va\na El Jaguel y Ezeiza."
	], Pal.YELLOW)

	# El Gordo - hincha del Club Atletico
	_create_npc(Vector2(23, 18), "El Gordo", [
		"¡Vamo' el Club Atletico\nMonte Grande, papa!",
		"Aca se juega al futbol\ndesde 1911.",
		"¿Te venis al proximo\npartido? Hay asado\ndespues."
	], Pal.GRASS_DK)

	# Lucia - desarrolladora en Kata Studio
	_create_npc(Vector2(14, 18), "Lucia", [
		"¡Hola! Trabajo en\nKata Studio.",
		"Estamos haciendo\nun juego sobre\nMonte Grande.",
		"Se llama TinyMont.\nEs open source.\n¿Lo conoces? Je."
	], Pal.PURPLE)

	# Dona Rosa - busca su gato en la plaza
	_create_npc(Vector2(24, 34), "Dona Rosa", [
		"¡Ay, nene! ¿No viste\na mi gato Mostaza?",
		"Se me escapo por\nel monumento...",
		"Es naranja con\nmanchas negras.\nAvisame si lo ves."
	], Pal.PINK)

	# Don Ramon - jubilado junto al ginkgo
	_create_npc(Vector2(21, 35), "Don Ramon", [
		"¿Sabias que ese\narbol es un Ginkgo\nbiloba?",
		"Es de la especie\nmas antigua del\nmundo.",
		"Aca todo es verde.\nPor algo le dicen\nla Ciudad de los\nArboles."
	], Pal.WOOD)

	# Mili - frente al Teatro
	_create_npc(Vector2(13, 4), "Mili", [
		"¡Hoy hay funcion en\nel Teatro!",
		"Hay tango, folklore\ny teatro.",
		"¡No te lo pierdas,\nvecino!"
	], Pal.WATER)

	# ===== Personajes tipicos del conurbano =====

	# Beto - quiosquero sobre Alem
	_create_npc(Vector2(16, 13), "Beto", [
		"Quiosco abierto las\n24hs... menos cuando\nme voy a dormir.",
		"¿Un alfajor? ¿Un\nManaos bien frio?\nLo que precises.",
		"Antes salia dos\nmangos. Ahora ni\nte cuento, pibe."
	], Pal.YELLOW)

	# Ruben - canillita en la estacion
	_create_npc(Vector2(16, 9), "Ruben", [
		"Diarios, revistas\ny figuritas, vecino.",
		"40 anios atendiendo\neste puesto. Vi\npasar de todo.",
		"Antes la gente leia\nel diario. Ahora el\ncelular."
	], Pal.BRICK)

	# Walter - colectivero, parada en Maximo Paz
	_create_npc(Vector2(8, 20), "Walter", [
		"Manejo el 306 hace\n15 anios, del centro\na Constitucion.",
		"Subite que arranco...\nMentira, espero que\nse llene primero.",
		"¡SUBE adelante, BAJA\natras! Y no me rayes\nel piso."
	], Pal.BLUE)

	# Dona Marta - almacenera cerca de Dardo Rocha
	_create_npc(Vector2(30, 22), "Dona Marta", [
		"¿Necesitas algo,\nnene? Tengo fiado\nsi sos del barrio.",
		"Pan, fideos, una\nlatita... lo que\nte falte para hoy.",
		"Saludame a tu mama.\nLlego la yerba que\npidio."
	], Pal.PINK)

	# Tito - jubilado de las bochas
	_create_npc(Vector2(24, 30), "Tito", [
		"¿Jugas a las bochas,\npibe? Veni que armamos\nuna con los muchachos.",
		"Todas las tardes aca,\ncon el mate y la\nradio.",
		"La plaza no cambia,\npor suerte."
	], Pal.GRASS_DK)

	# El Chino - puesto de choripan al sur de la plaza
	_create_npc(Vector2(18, 39), "El Chino", [
		"¡Choripan recien\nhecho! Con chimi\ncasero, jefe.",
		"Pan, chori y una\nGrapa... el desayuno\nde los campeones.",
		"¿Con o sin? Dale\nque se enfria la\nparrilla."
	], Pal.RED)

	# Padre Quique - parroco de la Inmaculada Concepcion
	_create_npc(Vector2(14, 30), "Padre Quique", [
		"Bienvenido a la\nParroquia Inmaculada\nConcepcion, hijo.",
		"Los domingos hay\nmisa a las 10 y\na las 19.",
		"La fe mueve montanias...\ny tambien a los\nmontegrandenses. Je."
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
