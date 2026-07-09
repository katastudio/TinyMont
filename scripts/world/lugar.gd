@tool
extends Node2D
## Un LUGAR del mapa (edificio con nombre), editable 100% en el editor.
## Arrastralo a su posición e configurá en el Inspector: nombre, tamaño (ancho/alto),
## tipo (marquesina, clínica, teatro, club, cultural, juguetería...) y colores.
## Se dibuja alineado a la grilla y bloquea el paso según su footprint.

const PlaceArt = preload("res://scripts/art/place_art.gd")
const T := 16

@export var nombre: String = "LUGAR":
	set(v): nombre = v; queue_redraw()
@export var ancho: int = 3:
	set(v): ancho = max(1, v); queue_redraw()
@export var alto: int = 2:
	set(v): alto = max(1, v); queue_redraw()
@export_enum("generico", "comida", "fastfood", "heladeria", "teatro", "cultural", "club", "clinica", "jugueteria")
var tipo: String = "generico":
	set(v): tipo = v; queue_redraw()

@export_group("Colores")
@export var fachada: Color = Color("d8b088"):
	set(v): fachada = v; queue_redraw()
@export var techo: Color = Color("a04030"):
	set(v): techo = v; queue_redraw()
@export var cartel: Color = Color("e03020"):
	set(v): cartel = v; queue_redraw()


func _descriptor() -> Dictionary:
	return {w = ancho, h = alto, tipo = tipo, fachada = fachada, techo = techo, cartel = cartel}


# Offset para dibujar alineado a la grilla, sin importar dónde caiga el nodo.
func _snap() -> Vector2:
	return Vector2(floor(position.x / T) * T - position.x, floor(position.y / T) * T - position.y)


func _draw():
	var o := _snap()
	PlaceArt.draw_on(self, PlaceArt.rects(_descriptor()), o, 1.0)
	_draw_nombre(o)


func _draw_nombre(o: Vector2):
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var tw := nombre.length() * 4 + 4
	var px := o.x + ancho * T / 2.0 - tw / 2.0
	var py := o.y - 4.0
	draw_rect(Rect2(px - 2, py - 8, tw + 2, 11), Color("fcfcfc"))
	draw_rect(Rect2(px - 3, py - 9, tw + 4, 13), Color("181018"), false, 1.0)
	draw_string(font, Vector2(px, py), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("181018"))


# El mundo (monte_grande) consulta esto para la colisión por grilla.
func bloquea(tx: int, ty: int) -> bool:
	var ox := int(floor(position.x / T))
	var oy := int(floor(position.y / T))
	return tx >= ox and tx < ox + ancho and ty >= oy and ty < oy + alto
