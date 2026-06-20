extends Node2D

const T := 16
const GB_LIGHTEST := Color("#9bbc0f")
const GB_LIGHT := Color("#8bac0f")
const GB_DARK := Color("#306230")
const GB_DARKEST := Color("#0f380f")

const MAP_W := 24
const MAP_H := 20

enum Tile { GRASS, WALL, WATER, PATH, TREE }

var tiles := PackedInt32Array()


func _ready():
	_build_map()
	_create_colliders()
	_spawn_player()
	_spawn_npcs()
	_add_dialog_box()


func _build_map():
	tiles.resize(MAP_W * MAP_H)
	tiles.fill(Tile.GRASS)

	# Border walls
	for x in MAP_W:
		set_tile(x, 0, Tile.WALL)
		set_tile(x, MAP_H - 1, Tile.WALL)
	for y in MAP_H:
		set_tile(0, y, Tile.WALL)
		set_tile(MAP_W - 1, y, Tile.WALL)

	# Casa del jugador (top-left)
	for x in range(2, 7):
		for y in range(1, 4):
			set_tile(x, y, Tile.WALL)

	# Kiosco de La Sole (top-right)
	for x in range(17, 23):
		for y in range(1, 4):
			set_tile(x, y, Tile.WALL)

	# Estacion de tren (bottom-right)
	for x in range(17, 23):
		for y in range(16, 19):
			set_tile(x, y, Tile.WALL)

	# Plaza central - paths
	for x in range(8, 16):
		set_tile(x, 7, Tile.PATH)
		set_tile(x, 14, Tile.PATH)
	for y in range(7, 15):
		set_tile(8, y, Tile.PATH)
		set_tile(15, y, Tile.PATH)

	# Inner plaza
	for x in range(9, 15):
		for y in range(8, 14):
			set_tile(x, y, Tile.PATH)

	# Fountain
	set_tile(11, 10, Tile.WATER)
	set_tile(12, 10, Tile.WATER)
	set_tile(11, 11, Tile.WATER)
	set_tile(12, 11, Tile.WATER)

	# Trees
	for pos in [
		Vector2i(3, 6), Vector2i(6, 6),
		Vector2i(3, 14), Vector2i(6, 14),
		Vector2i(17, 7), Vector2i(20, 7),
		Vector2i(17, 14), Vector2i(20, 14),
		Vector2i(10, 6), Vector2i(13, 6),
		Vector2i(10, 15), Vector2i(13, 15),
	]:
		set_tile(pos.x, pos.y, Tile.TREE)

	# Side paths (veredas)
	for y in range(4, 16):
		set_tile(1, y, Tile.PATH)
		set_tile(22, y, Tile.PATH)
	for x in range(1, 23):
		set_tile(x, 4, Tile.PATH)
		set_tile(x, 15, Tile.PATH)

	queue_redraw()


func set_tile(x: int, y: int, tile: int):
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		tiles[y * MAP_W + x] = tile


func get_tile(x: int, y: int) -> int:
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		return tiles[y * MAP_W + x]
	return Tile.WALL


func _draw():
	for y in MAP_H:
		for x in MAP_W:
			var r := Rect2(x * T, y * T, T, T)
			match get_tile(x, y):
				Tile.GRASS:
					draw_rect(r, GB_LIGHT)
					# Grass blades
					if (x * 7 + y * 3) % 5 == 0:
						draw_line(
							Vector2(x * T + 5, y * T + 4),
							Vector2(x * T + 5, y * T + 10),
							GB_DARK, 1.0)
					if (x * 3 + y * 7) % 6 == 0:
						draw_line(
							Vector2(x * T + 11, y * T + 6),
							Vector2(x * T + 11, y * T + 12),
							GB_DARK, 1.0)

				Tile.WALL:
					draw_rect(r, GB_DARKEST)
					draw_rect(
						Rect2(x * T + 1, y * T + 1, T - 2, T - 2),
						GB_DARK)
					# Brick pattern
					draw_line(
						Vector2(x * T, y * T + 8),
						Vector2(x * T + T, y * T + 8),
						GB_DARKEST, 1.0)
					var offset = (y % 2) * 8
					draw_line(
						Vector2(x * T + offset, y * T),
						Vector2(x * T + offset, y * T + T),
						GB_DARKEST, 1.0)

				Tile.WATER:
					draw_rect(r, GB_DARKEST)
					var wave = int(Time.get_ticks_msec() / 400.0) % 3
					for i in 3:
						var wx = x * T + 1 + i * 5 + (wave + i) % 3
						draw_line(
							Vector2(wx, y * T + 5),
							Vector2(wx + 3, y * T + 5),
							GB_DARK, 1.0)
						draw_line(
							Vector2(wx + 1, y * T + 10),
							Vector2(wx + 4, y * T + 10),
							GB_DARK, 1.0)

				Tile.PATH:
					draw_rect(r, GB_LIGHTEST)
					# Tile grid lines
					draw_line(
						Vector2(x * T + T - 1, y * T),
						Vector2(x * T + T - 1, y * T + T),
						GB_LIGHT, 1.0)
					draw_line(
						Vector2(x * T, y * T + T - 1),
						Vector2(x * T + T, y * T + T - 1),
						GB_LIGHT, 1.0)

				Tile.TREE:
					# Ground under tree
					draw_rect(r, GB_LIGHT)
					# Trunk
					draw_rect(
						Rect2(x * T + 6, y * T + 10, 4, 6),
						GB_DARK)
					# Crown shadow
					draw_circle(
						Vector2(x * T + 8, y * T + 7),
						7.0, GB_DARK)
					# Crown highlight
					draw_circle(
						Vector2(x * T + 7, y * T + 6),
						4.0, GB_DARKEST)

	# Building labels
	_draw_label(2, 1, "CASA")
	_draw_label(17, 1, "KIOSCO")
	_draw_label(17, 16, "ESTACION")


func _draw_label(tx: int, ty: int, text: String):
	var font = ThemeDB.fallback_font
	if font:
		var pos = Vector2(tx * T + 2, ty * T + 10)
		# Background
		draw_rect(
			Rect2(pos.x - 1, pos.y - 7, text.length() * 5 + 2, 9),
			GB_LIGHTEST)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GB_DARKEST)


func _create_colliders():
	for y in MAP_H:
		for x in MAP_W:
			var tile = get_tile(x, y)
			if tile in [Tile.WALL, Tile.WATER, Tile.TREE]:
				var body = StaticBody2D.new()
				body.position = Vector2(x * T + T / 2, y * T + T / 2)
				var col = CollisionShape2D.new()
				var shape = RectangleShape2D.new()
				shape.size = Vector2(T, T)
				col.shape = shape
				body.add_child(col)
				add_child(body)


func _spawn_player():
	var player = preload("res://scenes/player/player.tscn").instantiate()
	player.position = Vector2(4 * T + T / 2, 5 * T + T / 2)
	add_child(player)

	# Camera limits
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * T
	cam.limit_bottom = MAP_H * T


func _spawn_npcs():
	# Don Carlos - viejo de la plaza
	_create_npc(
		Vector2(11, 13),
		"Don Carlos",
		[
			"¡Eh, pibe! ¿Qué hacés\npor acá?",
			"Esto es la plaza de\nMonte Grande, papá.",
			"Antes acá era todo\ncampo, ¿sabías?",
			"Ahora hay un shopping\ny todo... ¡Mirá cómo\ncambian las cosas!"
		],
		GB_DARK
	)

	# La Sole - kiosquera
	_create_npc(
		Vector2(16, 5),
		"La Sole",
		[
			"¡Hola, vecino!",
			"El kiosco está cerrado,\nvolvé más tarde.",
			"¿Querés un Manaos?\nMentira, no tengo. Je."
		],
		GB_LIGHT
	)

	# El Pipe - pibe del barrio
	_create_npc(
		Vector2(4, 10),
		"El Pipe",
		[
			"Ey, ¿viste que en la\nestación pasan cosas\nraras de noche?",
			"Yo no fui a fijarme...\n¿Vos te animás, loco?"
		],
		GB_LIGHTEST
	)

	# Doña Rosa - señora del barrio
	_create_npc(
		Vector2(14, 9),
		"Doña Rosa",
		[
			"¡Ay, nene! ¿No viste\na mi gato?",
			"Se me escapó hace\nuna hora...",
			"Si lo encontrás,\navisame. Es naranja\ncon manchas negras."
		],
		GB_DARK
	)


func _create_npc(tile_pos: Vector2, npc_name: String, lines: Array, color: Color):
	var npc = preload("res://scenes/npc/npc.tscn").instantiate()
	npc.position = Vector2(tile_pos.x * T + T / 2, tile_pos.y * T + T / 2)
	npc.npc_name = npc_name
	npc.dialog_lines = lines
	npc.npc_color = color
	add_child(npc)


func _add_dialog_box():
	var dialog = preload("res://scenes/ui/dialog_box.tscn").instantiate()
	add_child(dialog)


func _process(_delta):
	queue_redraw()
