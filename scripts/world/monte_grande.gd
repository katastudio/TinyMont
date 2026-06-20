extends Node2D
## Monte Grande - "Ciudad de los Árboles"
## Mapa basado en el centro real: Plaza Mitre, Estación Roca, calles principales

const T := 16
const GB_LIGHTEST := Color("#9bbc0f")
const GB_LIGHT := Color("#8bac0f")
const GB_DARK := Color("#306230")
const GB_DARKEST := Color("#0f380f")

const MAP_W := 44
const MAP_H := 48

# Tile types — expanded for Monte Grande landmarks
enum Tile {
	GRASS, BUILDING, ROAD, TREE, RAIL, PLAZA, WATER,
	SIDEWALK, MONUMENT, BENCH, PLATFORM, OMBU
}

var tiles := PackedInt32Array()
var labels: Array = []
var _redraw_timer := 0.0

# Building metadata: {Vector2i: {name, type}} for special rendering
var building_info := {}

var h_road_ys := [3, 4, 12, 13, 21, 22, 30, 31]
var v_road_xs := [4, 5, 12, 13, 20, 21, 28, 29, 36, 37]


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
		set_tile(x, 1, Tile.TREE)
		set_tile(x, MAP_H - 1, Tile.TREE)
		set_tile(x, MAP_H - 2, Tile.TREE)
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
	labels.append({pos = Vector2(6, 2), text = "MAXIMO PAZ"})
	labels.append({pos = Vector2(6, 11), text = "AV.DARDO ROCHA"})
	labels.append({pos = Vector2(6, 20), text = "M.ACOSTA"})
	labels.append({pos = Vector2(6, 29), text = "DR.KOTTA"})
	labels.append({pos = Vector2(2, 5), text = "DORREGO"})
	labels.append({pos = Vector2(34, 5), text = "RODRIGUEZ"})


func _lay_sidewalks():
	# Sidewalks along horizontal streets
	for sy in [2, 5, 11, 14, 20, 23, 29, 32]:
		for x in MAP_W:
			if get_tile(x, sy) == Tile.GRASS:
				set_tile(x, sy, Tile.SIDEWALK)
	# Sidewalks along vertical streets
	for sx in [3, 6, 11, 14, 19, 22, 27, 30, 35, 38]:
		for y in MAP_H:
			if get_tile(sx, y) == Tile.GRASS:
				set_tile(sx, y, Tile.SIDEWALK)


func _lay_tracks():
	for x in MAP_W:
		if not (x in v_road_xs):
			set_tile(x, 8, Tile.RAIL)
			set_tile(x, 9, Tile.RAIL)


func _build_station():
	# Platform (walkable area between tracks and Dardo Rocha)
	for x in range(15, 20):
		set_tile(x, 10, Tile.PLATFORM)
		set_tile(x, 11, Tile.PLATFORM)
	labels.append({pos = Vector2(15, 10), text = "ESTACION MG"})
	# Station building above tracks
	_bld_special(14, 5, 6, 3, "ESTACION", "station")


func _fill_blocks():
	# === ROW 1A: Above tracks (y=5-7) ===
	_bld_special(7, 5, 4, 3, "TEATRO", "teatro")
	_bld(22, 5, 5, 3, "")
	_bld(30, 5, 5, 3, "")
	_bld(38, 5, 3, 3, "")

	# === ROW 1B: Below tracks (y=10-11) — station area ===
	_bld(7, 10, 4, 2, "")
	_bld(22, 10, 5, 2, "")
	_bld(30, 10, 5, 2, "")

	# === ROW 2: Dardo Rocha → Mariano Acosta (y=14-20) ===
	_bld_special(7, 14, 4, 3, "VENECIANA", "restaurant")
	_bld(7, 18, 4, 2, "")
	_bld(14, 14, 5, 3, "")
	_bld(14, 18, 5, 2, "")
	_bld_special(22, 14, 5, 4, "CLUB ATL.", "club")
	_bld(22, 19, 5, 1, "")
	_bld(30, 14, 5, 3, "")
	_bld(30, 18, 5, 2, "")
	_bld(38, 14, 3, 6, "")
	_bld(1, 14, 2, 6, "")

	# === ROW 3: Mariano Acosta → Dr. Kotta (y=23-29) ===
	_bld(7, 23, 4, 3, "")
	_bld(7, 27, 4, 2, "")
	_bld_special(14, 23, 5, 3, "MOSTAZA", "fastfood")
	_bld(14, 27, 5, 2, "")
	_bld_special(22, 23, 5, 3, "KATA STUDIO", "studio")
	_bld(22, 27, 5, 2, "")
	_bld(30, 23, 5, 6, "")
	_bld(38, 23, 3, 6, "")
	_bld(1, 23, 2, 6, "")

	# === ROW 4: Below Dr. Kotta (y=32+) ===
	_bld(1, 32, 2, 5, "")
	_bld(7, 32, 4, 4, "")
	_bld(30, 32, 5, 4, "")
	_bld(38, 32, 3, 4, "")
	_bld(1, 38, 2, 5, "")
	_bld(7, 38, 3, 4, "")
	_bld(30, 38, 5, 4, "")
	_bld(38, 38, 3, 5, "")


func _build_plaza_mitre():
	var cx := 21
	var cy := 40
	var radius := 6
	# Diamond shape — like the real rotated square
	for dy in range(-radius, radius + 1):
		var w = radius - abs(dy)
		for dx in range(-w, w + 1):
			var px = cx + dx
			var py = cy + dy
			if px > 0 and px < MAP_W - 1 and py > 0 and py < MAP_H - 1:
				set_tile(px, py, Tile.PLAZA)
	# White mosaic paths (cross pattern inside plaza)
	for i in range(-radius + 1, radius):
		set_tile(cx + i, cy, Tile.SIDEWALK)
		set_tile(cx, cy + i, Tile.SIDEWALK)
	# Octagonal fountain (real: fuente octogonal celeste)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			set_tile(cx + dx, cy + dy, Tile.WATER)
	# Busto de Mitre (monument)
	set_tile(cx - 3, cy - 2, Tile.MONUMENT)
	# Monumento a la Madre
	set_tile(cx + 3, cy - 2, Tile.MONUMENT)
	# Monumento al Bombero
	set_tile(cx + 3, cy + 2, Tile.MONUMENT)
	# Monumento a Sarmiento
	set_tile(cx - 3, cy + 2, Tile.MONUMENT)
	# Ombú / Ginkgo biloba histórico
	set_tile(cx + 2, cy - 3, Tile.OMBU)
	set_tile(cx - 2, cy + 3, Tile.OMBU)
	# Benches around the fountain
	set_tile(cx - 2, cy, Tile.BENCH)
	set_tile(cx + 2, cy, Tile.BENCH)
	set_tile(cx, cy - 2, Tile.BENCH)
	set_tile(cx, cy + 2, Tile.BENCH)
	labels.append({pos = Vector2(cx - 3, cy - radius), text = "PLAZA MITRE"})


func _plant_trees():
	# "Ciudad de los Árboles" — lots of trees!
	var positions = [
		# Plaza perimeter trees
		Vector2i(16, 37), Vector2i(26, 37),
		Vector2i(15, 39), Vector2i(27, 39),
		Vector2i(15, 41), Vector2i(27, 41),
		Vector2i(16, 43), Vector2i(26, 43),
		Vector2i(18, 35), Vector2i(24, 35),
		Vector2i(18, 45), Vector2i(24, 45),
		# Boulevard trees on Dardo Rocha (main avenue)
		Vector2i(8, 14), Vector2i(10, 14),
		Vector2i(16, 14), Vector2i(18, 14),
		Vector2i(24, 14), Vector2i(26, 14),
		Vector2i(32, 14), Vector2i(34, 14),
		# Trees along Mariano Acosta
		Vector2i(8, 23), Vector2i(16, 23), Vector2i(32, 23),
		# Trees along sidewalks
		Vector2i(8, 5), Vector2i(24, 5), Vector2i(32, 5),
		Vector2i(8, 32), Vector2i(24, 32),
		# Scattered residential trees
		Vector2i(9, 17), Vector2i(17, 17), Vector2i(33, 17),
		Vector2i(9, 27), Vector2i(17, 27), Vector2i(33, 27),
		Vector2i(9, 35), Vector2i(33, 35),
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
			draw_rect(r, GB_LIGHT)
			if (x * 7 + y * 3) % 5 == 0:
				draw_line(Vector2(x*T+5, y*T+3), Vector2(x*T+5, y*T+9), GB_DARK, 1.0)
			if (x * 3 + y * 11) % 7 == 0:
				draw_line(Vector2(x*T+11, y*T+6), Vector2(x*T+11, y*T+12), GB_DARK, 1.0)
			if (x * 13 + y * 5) % 11 == 0:
				draw_line(Vector2(x*T+8, y*T+2), Vector2(x*T+8, y*T+7), GB_DARK, 1.0)
		Tile.BUILDING:
			_draw_building(x, y, r)
		Tile.ROAD:
			_draw_road(x, y, r)
		Tile.SIDEWALK:
			draw_rect(r, GB_LIGHTEST)
			# Tile pattern
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), GB_LIGHT)
		Tile.TREE:
			draw_rect(r, GB_LIGHT)
			draw_rect(Rect2(x*T+6, y*T+10, 4, 6), GB_DARK)
			draw_circle(Vector2(x*T+8, y*T+6), 6.0, GB_DARK)
			draw_circle(Vector2(x*T+7, y*T+5), 4.0, GB_DARKEST)
		Tile.OMBU:
			# Giant ombú / Ginkgo tree — larger crown
			draw_rect(r, GB_LIGHT)
			draw_rect(Rect2(x*T+5, y*T+10, 6, 6), GB_DARK)
			draw_circle(Vector2(x*T+8, y*T+5), 7.0, GB_DARKEST)
			draw_circle(Vector2(x*T+6, y*T+4), 4.0, GB_DARK)
			draw_circle(Vector2(x*T+10, y*T+6), 3.0, GB_DARK)
		Tile.RAIL:
			_draw_rail(x, y, r)
		Tile.PLATFORM:
			# Train platform — concrete with yellow safety line
			draw_rect(r, GB_DARK)
			draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), GB_LIGHT)
			draw_line(Vector2(x*T, y*T), Vector2(x*T+T, y*T), GB_LIGHTEST, 2.0)
		Tile.PLAZA:
			draw_rect(r, GB_LIGHTEST)
			# Mosaic pattern (like the real white mosaic paths)
			draw_rect(Rect2(x*T+1, y*T+1, 6, 6), GB_LIGHT)
			draw_rect(Rect2(x*T+9, y*T+9, 6, 6), GB_LIGHT)
		Tile.WATER:
			_draw_fountain(x, y, r)
		Tile.MONUMENT:
			draw_rect(r, GB_LIGHTEST)
			# Monument base
			draw_rect(Rect2(x*T+4, y*T+8, 8, 8), GB_DARK)
			draw_rect(Rect2(x*T+5, y*T+9, 6, 6), GB_DARKEST)
			# Bust/statue on top
			draw_rect(Rect2(x*T+6, y*T+3, 4, 6), GB_DARKEST)
			draw_circle(Vector2(x*T+8, y*T+3), 3.0, GB_DARKEST)
		Tile.BENCH:
			draw_rect(r, GB_LIGHTEST)
			# Park bench
			draw_rect(Rect2(x*T+2, y*T+6, 12, 2), GB_DARK)
			draw_rect(Rect2(x*T+2, y*T+8, 2, 4), GB_DARK)
			draw_rect(Rect2(x*T+12, y*T+8, 2, 4), GB_DARK)
			draw_rect(Rect2(x*T+3, y*T+3, 10, 2), GB_DARKEST)


func _draw_building(x: int, y: int, r: Rect2):
	draw_rect(r, GB_DARKEST)
	draw_rect(Rect2(x*T+1, y*T+1, T-2, T-2), GB_DARK)
	# Brick pattern
	draw_line(Vector2(x*T, y*T+8), Vector2(x*T+T, y*T+8), GB_DARKEST, 1.0)
	var boff = (y % 2) * 8
	draw_line(Vector2(x*T+boff, y*T), Vector2(x*T+boff, y*T+T), GB_DARKEST, 1.0)
	# Windows
	if (x + y) % 3 == 0:
		draw_rect(Rect2(x*T+3, y*T+2, 4, 5), GB_DARKEST)
		draw_rect(Rect2(x*T+4, y*T+3, 2, 3), GB_LIGHT)
		draw_rect(Rect2(x*T+9, y*T+2, 4, 5), GB_DARKEST)
		draw_rect(Rect2(x*T+10, y*T+3, 2, 3), GB_LIGHT)
	elif (x + y) % 3 == 1:
		# Door
		draw_rect(Rect2(x*T+5, y*T+6, 6, 10), GB_DARKEST)
		draw_rect(Rect2(x*T+6, y*T+7, 4, 8), GB_LIGHT)


func _draw_road(x: int, y: int, r: Rect2):
	draw_rect(r, GB_LIGHTEST)
	# Determine if horizontal or vertical road
	var is_h = y in h_road_ys
	var is_v = x in v_road_xs
	if is_h and not is_v:
		# Horizontal road — dashed center line
		draw_line(Vector2(x*T, y*T+T-1), Vector2(x*T+T, y*T+T-1), GB_LIGHT, 1.0)
		if y in [3, 12, 21, 30] and x % 3 != 0:
			draw_line(Vector2(x*T+2, y*T+8), Vector2(x*T+T-2, y*T+8), GB_DARK, 1.0)
	elif is_v and not is_h:
		# Vertical road — dashed center line
		draw_line(Vector2(x*T+T-1, y*T), Vector2(x*T+T-1, y*T+T), GB_LIGHT, 1.0)
		if x in [4, 12, 20, 28, 36] and y % 3 != 0:
			draw_line(Vector2(x*T+8, y*T+2), Vector2(x*T+8, y*T+T-2), GB_DARK, 1.0)
	else:
		# Intersection
		draw_line(Vector2(x*T+T-1, y*T), Vector2(x*T+T-1, y*T+T), GB_LIGHT, 1.0)
		draw_line(Vector2(x*T, y*T+T-1), Vector2(x*T+T, y*T+T-1), GB_LIGHT, 1.0)


func _draw_rail(x: int, y: int, r: Rect2):
	draw_rect(r, GB_DARK)
	# Sleepers (durmientes)
	for i in 4:
		draw_rect(Rect2(x*T + i*4, y*T+1, 2, T-2), GB_DARKEST)
	# Rails (rieles metálicos)
	draw_line(Vector2(x*T, y*T+4), Vector2(x*T+T, y*T+4), GB_LIGHTEST, 1.0)
	draw_line(Vector2(x*T, y*T+12), Vector2(x*T+T, y*T+12), GB_LIGHTEST, 1.0)


func _draw_fountain(x: int, y: int, r: Rect2):
	# Octagonal fountain (fuente octogonal celeste)
	draw_rect(r, GB_DARK)
	draw_rect(Rect2(x*T+2, y*T+2, T-4, T-4), GB_DARKEST)
	# Animated water jets
	var t = int(Time.get_ticks_msec() / 300.0)
	var jet_h = 3 + (t % 3)
	draw_rect(Rect2(x*T+7, y*T+8-jet_h, 2, jet_h), GB_LIGHT)
	# Water ripples
	var wave = t % 4
	draw_line(
		Vector2(x*T+3+wave, y*T+10),
		Vector2(x*T+6+wave, y*T+10), GB_DARK, 1.0)
	draw_line(
		Vector2(x*T+8-wave, y*T+12),
		Vector2(x*T+12-wave, y*T+12), GB_DARK, 1.0)


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
				# Station roof line
				draw_line(Vector2(bx, by), Vector2(bx+bw, by), GB_LIGHTEST, 2.0)
				draw_line(Vector2(bx, by+bh), Vector2(bx+bw, by+bh), GB_LIGHTEST, 1.0)
			"teatro":
				# Teatro marquee top
				draw_line(Vector2(bx, by), Vector2(bx+bw, by), GB_LIGHTEST, 2.0)
				# Entrance arch
				draw_rect(Rect2(bx+T*1+4, by+T*2+4, T-8, T-4), GB_LIGHTEST)
			"restaurant":
				# La Veneciana — checkered awning
				for i in range(info.w):
					if i % 2 == 0:
						draw_rect(Rect2(bx+i*T, by, T, 3), GB_LIGHTEST)
			"fastfood":
				# Mostaza — yellow top stripe
				draw_rect(Rect2(bx, by, bw, 3), GB_LIGHTEST)
			"club":
				# Athletic club — pitch lines
				draw_rect(Rect2(bx+T, by+T, T*3, 2), GB_LIGHTEST)
			"studio":
				# Kata Studio — screen glow effect
				draw_rect(Rect2(bx+T+2, by+T+2, T*2-4, T-4), GB_LIGHT)


func _draw_labels():
	var font = ThemeDB.fallback_font
	if not font:
		return
	for lbl in labels:
		var pos = Vector2(lbl.pos.x * T + 2, lbl.pos.y * T + 10)
		var tw = lbl.text.length() * 4 + 4
		draw_rect(Rect2(pos.x - 2, pos.y - 8, tw + 2, 11), GB_LIGHTEST)
		draw_rect(Rect2(pos.x - 3, pos.y - 9, tw + 4, 13), GB_DARKEST, false, 1.0)
		draw_string(font, pos, lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GB_DARKEST)


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
	player.position = Vector2(21 * T + T / 2, 25 * T + T / 2)
	add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * T
	cam.limit_bottom = MAP_H * T


func _spawn_npcs():
	# Don Carlos — viejo de la plaza, junto al busto de Mitre
	_create_npc(Vector2(20, 38), "Don Carlos", [
		"¡Eh, pibe! Bienvenido\na la Plaza Mitre.",
		"¿Ves ese busto?\nEs de Bartolomé Mitre.",
		"La plaza antes se\nllamaba Nueva Escocia,\npor los escoceses.",
		"¡Monte Grande... la\nCiudad de los Árboles!"
	], GB_DARK)

	# La Sole — pizzera de La Veneciana
	_create_npc(Vector2(6, 15), "La Sole", [
		"¡Hola, vecino!",
		"¿Venís a La Veneciana?\nLa mejor pizza del\nconurbano sur.",
		"Pedite una muzzarella\ncon fainá. ¡Clasicazo!"
	], GB_LIGHT)

	# El Pipe — esperando el Roca en la estación
	_create_npc(Vector2(17, 11), "El Pipe", [
		"Estoy esperando el\nRoca hace 40 minutos.",
		"Dice 'próximo tren\nen 5 min' hace rato...",
		"Constitución queda\na 28 km pero parece\nque fueran 280."
	], GB_LIGHTEST)

	# El Gordo — hincha del Club Atlético
	_create_npc(Vector2(22, 17), "El Gordo", [
		"¡Vamo' el Club Atlético\nMonte Grande, papá!",
		"Acá se juega al fútbol\ndesde 1911.",
		"¿Te venís al próximo\npartido? Hay asado\ndespués."
	], GB_DARK)

	# Lucía — desarrolladora en Kata Studio
	_create_npc(Vector2(22, 26), "Lucía", [
		"¡Hola! Trabajo en\nKata Studio Click.",
		"Estamos haciendo\nun juego sobre\nMonte Grande.",
		"Se llama TinyMont.\nEs open source.\n¿Lo conocés? Je."
	], GB_LIGHT)

	# Doña Rosa — señora de la plaza buscando su gato
	_create_npc(Vector2(22, 42), "Doña Rosa", [
		"¡Ay, nene! ¿No viste\na mi gato Mostaza?",
		"Se me escapó por\nel monumento a\nla Madre...",
		"Es naranja con\nmanchas negras.\nAvisame si lo ves."
	], GB_DARK)

	# Don Ramón — jubilado en un banco de la plaza
	_create_npc(Vector2(19, 40), "Don Ramón", [
		"¿Sabías que este\nárbol es un Ginkgo\nbiloba?",
		"Lo plantaron por\n1910. Es de la especie\nmás antigua del mundo.",
		"Fue el único que\nbrotó después de\nHiroshima."
	], GB_DARK)

	# Mili — chica cerca del Teatro Greison
	_create_npc(Vector2(6, 6), "Mili", [
		"¡Hoy hay función en\nel Teatro Greison!",
		"Entran 1200 personas.\nHay tango, folklore\ny teatro.",
		"Está en Dardo Rocha\n135. ¡No te lo pierdas!"
	], GB_LIGHTEST)


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
