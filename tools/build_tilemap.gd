extends SceneTree
## Generador (uso unico / regenerable): crea el TileSet de swatches con textura
## EMBEBIDA (sin PNG externo ni import) y reescribe scenes/main.tscn con un
## TileMapLayer "MapaLayer" ya pintado a partir de data/map.txt (semilla).
##
## Correr:  godot --headless --path . --script tools/build_tilemap.gd
## La PALETTE (orden/colores) se lee de monte_grande.gd: una sola fuente.

const TS := 16
const COLS := 8
const MG_PATH := "res://scripts/world/monte_grande.gd"
const TILESET_PATH := "res://tilesets/monte_tiles.tres"
const SCENE_PATH := "res://scenes/main.tscn"
const SEED_TXT := "res://data/map.txt"

# char del .txt -> indice en PALETTE
const CHAR_IDX := {
	".": 0, "#": 1, ":": 2, "T": 3, "O": 4, "=": 5, "_": 6, "P": 7, "~": 8,
	"M": 9, "b": 10, "S": 11, "A": 12, "V": 13, "F": 14, "K": 15, "C": 16,
	"Q": 17, "I": 18, "G": 19, "H": 20,
}


func _initialize():
	var mg = load(MG_PATH)
	var palette: Array = mg.get_script_constant_map()["PALETTE"]
	print("PALETTE: ", palette.size(), " tiles")

	var rows := int(ceil(float(palette.size()) / COLS))
	var img := Image.create(COLS * TS, rows * TS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in palette.size():
		var col := i % COLS
		var row := i / COLS
		var c: Color = palette[i].color
		_fill_swatch(img, col, row, c, palette[i].btype != "")

	var tex := PortableCompressedTexture2D.new()
	tex.keep_compressed_buffer = true
	tex.create_from_image(img, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	# --- TileSet ---
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TS, TS)
	for i in palette.size():
		src.create_tile(Vector2i(i % COLS, i / COLS))
	var sid := ts.add_source(src, 0)
	var err := ResourceSaver.save(ts, TILESET_PATH)
	print("TileSet guardado (", error_string(err), ") source_id=", sid)

	# --- Escena con la capa pintada desde la semilla ---
	var ts_loaded = load(TILESET_PATH)
	var root := Node2D.new()
	root.name = "MonteGrande"
	root.set_script(mg)

	var layer := TileMapLayer.new()
	layer.name = "MapaLayer"
	layer.tile_set = ts_loaded

	var painted := _paint_from_seed(layer, sid)
	root.add_child(layer)
	layer.owner = root

	var ps := PackedScene.new()
	ps.pack(root)
	err = ResourceSaver.save(ps, SCENE_PATH)
	print("Escena guardada (", error_string(err), ") celdas pintadas=", painted)
	quit()


func _fill_swatch(img: Image, col: int, row: int, c: Color, is_bld: bool):
	var ox := col * TS
	var oy := row * TS
	for y in TS:
		for x in TS:
			var px := c
			# borde fino para distinguir celdas
			if x == 0 or y == 0 or x == TS - 1 or y == TS - 1:
				px = c.darkened(0.35)
			# techo oscuro arriba para los edificios
			elif is_bld and y < 4:
				px = c.darkened(0.45)
			img.set_pixel(ox + x, oy + y, px)


func _paint_from_seed(layer: TileMapLayer, sid: int) -> int:
	var f := FileAccess.open(SEED_TXT, FileAccess.READ)
	if f == null:
		push_error("No se encontro la semilla " + SEED_TXT)
		return 0
	var raw := f.get_as_text()
	f.close()
	var grid: Array = []
	for line in raw.split("\n"):
		if line.begins_with(";"):
			continue
		if line.strip_edges() == "" and grid.is_empty():
			continue
		grid.append(line)
	while not grid.is_empty() and grid[grid.size() - 1].strip_edges() == "":
		grid.pop_back()

	var count := 0
	for y in grid.size():
		var rowstr: String = grid[y]
		for x in rowstr.length():
			var ch := rowstr[x]
			if CHAR_IDX.has(ch):
				var idx: int = CHAR_IDX[ch]
				layer.set_cell(Vector2i(x, y), sid, Vector2i(idx % COLS, idx / COLS))
				count += 1
	return count
