extends Control
## Flechita "continuar diálogo" (▼) dibujada por código (procedural).
## Antes era un Label con el carácter "▼": en web la fuente no tiene ese glyph
## y se veía como un cuadrado con basura ("tofu"). El triángulo se ve igual en todos lados.

var color: Color = Color("181018")


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x / 2.0, size.y),
	]), color)
