@tool
class_name MapaSecundario
extends Node2D
## Mapa secundario (spec 0006, ADR-0005): interiores de edificios y otros barrios.
## Se arma desde un plano de texto y se dibuja por código (sin assets). Implementa la misma
## interfaz que MonteGrande para que el jugador y los NPCs funcionen igual: is_walkable,
## get_npc_at, ocupacion, camino, celda_de, pos_de, es_transitable_estatica.
##
## Plano: una fila de texto por fila de celdas.
##   #  pared        .  piso          =  alfombra      M  mesa         C  mostrador
##   P  planta       X  salida        G  pasto         R  calle        V  vereda
##   H  casa         A  árbol         F  arco          L  línea de cancha
## La salida (X) no se pisa: caminar contra ella vuelve al barrio. Monti entra por la
## celda transitable vecina a la primera X.

const T := 16
const TRANSITABLES := ".=GRVL"
const COLORES := {
	"#": Color("6a4a3a"), ".": Color("d8b890"), "=": Color("b04040"), "M": Color("8a5a2a"),
	"C": Color("5a3a2a"), "P": Color("2f8a3f"), "X": Color("3a2a1a"), "G": Color("58d858"),
	"R": Color("9c9c9c"), "V": Color("e8d8b0"), "H": Color("d85820"), "A": Color("1c9c1c"),
	"F": Color("fcfcfc"), "L": Color("48b848"),
}

@export var nombre_mapa: String = ""
@export_multiline var plano: String = "#X#"

var ocupacion := GrillaOcupacion.new()
var astar := AStarGrid2D.new()
var semilla: int = 1
var pois: Array = []          # sin puntos de interés: el cerebro del barrio vive en el mapa principal
var ancho: int = 0
var alto: int = 0
var celda_entrada := Vector2i.ZERO
var _filas: PackedStringArray = []
var _salidas: Array[Vector2i] = []


func _ready() -> void:
	_leer_plano()
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_armar_astar()
	_registrar_interactuables()
	_crear_jugador()


func _leer_plano() -> void:
	_filas = PackedStringArray()
	for linea in plano.split("\n"):
		if linea.strip_edges() != "":
			_filas.append(linea.strip_edges())
	alto = _filas.size()
	ancho = 0
	for f in _filas:
		ancho = maxi(ancho, f.length())
	_salidas.clear()
	for y in alto:
		for x in ancho:
			if letra(Vector2i(x, y)) == "X":
				_salidas.append(Vector2i(x, y))
	if not _salidas.is_empty():
		celda_entrada = Vector2i(-1, -1)
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var c: Vector2i = _salidas[0] + d
			if es_transitable_estatica(c):
				celda_entrada = c
				break
		if celda_entrada == Vector2i(-1, -1):
			push_error("%s: la salida no tiene una celda transitable al lado" % nombre_mapa)
			celda_entrada = Vector2i.ZERO


func letra(celda: Vector2i) -> String:
	if celda.y < 0 or celda.y >= alto or celda.x < 0 or celda.x >= _filas[celda.y].length():
		return "#"
	return _filas[celda.y][celda.x]


func _armar_astar() -> void:
	astar.region = Rect2i(0, 0, ancho, alto)
	astar.cell_size = Vector2(T, T)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	for y in alto:
		for x in ancho:
			if not es_transitable_estatica(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)


func _registrar_interactuables() -> void:
	for child in get_children():
		if child.has_method("interact"):
			ocupacion.reservar(celda_de(child.position), child)


func _crear_jugador() -> void:
	var player = preload("res://scenes/player/player.tscn").instantiate()
	player.position = pos_de(celda_entrada)
	add_child(player)
	player.facing = Vector2.UP
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = -T * 4
	cam.limit_top = -int(GameManager.safe_top_frac() * get_viewport_rect().size.y + 24.0) - T * 4
	cam.limit_right = (ancho + 4) * T
	cam.limit_bottom = (alto + 4) * T
	cam.make_current()


# ==================== Interfaz común con MonteGrande ====================

func celda_de(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / T, int(world_pos.y) / T)


func pos_de(celda: Vector2i) -> Vector2:
	return Vector2(celda.x * T + T / 2.0, celda.y * T + T / 2.0)


func es_transitable_estatica(celda: Vector2i) -> bool:
	return letra(celda) in TRANSITABLES


func is_walkable(world_pos: Vector2) -> bool:
	var c := celda_de(world_pos)
	return es_transitable_estatica(c) and ocupacion.esta_libre(c)


func get_npc_at(world_pos: Vector2):
	var quien = ocupacion.ocupante(celda_de(world_pos))
	return quien if quien != null and quien.has_method("interact") else null


func camino(desde: Vector2i, hasta: Vector2i, _esquivar_ocupadas: bool = false) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	if not astar.is_in_boundsv(desde) or not astar.is_in_boundsv(hasta):
		return resultado
	var path := astar.get_id_path(desde, hasta)
	for i in range(1, path.size()):
		resultado.append(path[i])
	return resultado


## Caminar contra la salida vuelve al barrio.
func cruzar_portal(celda: Vector2i, _quien: Node) -> bool:
	if celda in _salidas:
		GameManager.volver_al_barrio()
		return true
	return false


func vecinos() -> Array:
	return get_children().filter(func(n): return "npc_name" in n)


## Una celda transitable y libre al lado de `celda` (para pararse a hablar).
func celda_libre_junto_a(celda: Vector2i) -> Vector2i:
	for d in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		var c: Vector2i = celda + d
		if es_transitable_estatica(c) and ocupacion.esta_libre(c):
			return c
	return celda


func _draw() -> void:
	if _filas.is_empty():
		_leer_plano()
	draw_rect(Rect2(-T * 40, -T * 40, (ancho + 80) * T, (alto + 80) * T), Color("1a1a20"))   # cubre toda la vista
	for y in alto:
		for x in ancho:
			var l := letra(Vector2i(x, y))
			var r := Rect2(x * T, y * T, T, T)
			draw_rect(r, COLORES.get(l, Color("1a1a20")))
			match l:
				".", "=":
					draw_rect(Rect2(r.position.x, r.position.y + T - 1, T, 1), Color(0, 0, 0, 0.08))
				"#":
					draw_rect(Rect2(r.position.x, r.position.y + T - 3, T, 3), Color("4a3428"))
				"M":
					draw_rect(r.grow(-2), Color("b07a3a"))
				"C":
					draw_rect(Rect2(r.position.x, r.position.y, T, 4), Color("8a6a4a"))
				"P":
					draw_rect(Rect2(r.position.x + 5, r.position.y + 10, 6, 5), Color("a05a2a"))
					draw_circle(r.get_center() + Vector2(0, -2), 5.0, Color("3fb84f"))
				"X":
					draw_rect(Rect2(r.position.x + 3, r.position.y + 2, T - 6, T - 2), Color("8a5a2a"))
					draw_rect(Rect2(r.position.x + T - 6, r.position.y + 8, 2, 2), Color("ffd23c"))
				"R":
					draw_rect(Rect2(r.position.x + 6, r.position.y + 7, 4, 2), Color("fcfcfc"))
				"H":
					draw_rect(Rect2(r.position.x, r.position.y, T, 5), Color("a02000"))
					draw_rect(Rect2(r.position.x + 5, r.position.y + 8, 6, 5), Color("6ab0f0"))
				"A":
					draw_rect(r, Color("58d858"))
					draw_circle(r.get_center(), 7.0, Color("1c9c1c"))
				"F":
					draw_rect(r, Color("48b848"))
					draw_rect(Rect2(r.position.x + 1, r.position.y + 2, T - 2, 2), Color("fcfcfc"))
					draw_rect(Rect2(r.position.x + 1, r.position.y + 2, 2, T - 4), Color("fcfcfc"))
					draw_rect(Rect2(r.position.x + T - 3, r.position.y + 2, 2, T - 4), Color("fcfcfc"))
				"L":
					draw_rect(Rect2(r.position.x, r.position.y + 7, T, 2), Color("fcfcfc"))
	if nombre_mapa != "":
		var font := ThemeDB.fallback_font
		if font:
			draw_string(font, Vector2(4, -6), nombre_mapa, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ecece4"))
