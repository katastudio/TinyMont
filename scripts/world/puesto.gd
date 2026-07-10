@tool
extends Node2D
## Puesto callejero (carrito de café), editable 100% en el editor.
## Arrastralo al mapa; en el Inspector configurás el toldo, el cartel y el footprint.
## Se dibuja alineado a la grilla y bloquea el paso (como Lugar).
## Reutilizable: el de Marcos (estación) y el de Sandra (Plaza Mitre) son el mismo nodo.

const T := 16

@export var nombre: String = "CAFE":
	set(v): nombre = v; queue_redraw()
@export var ancho: int = 2:
	set(v): ancho = max(1, v); queue_redraw()
@export var alto: int = 1:
	set(v): alto = max(1, v); queue_redraw()

@export_group("Colores")
@export var toldo: Color = Color("e03020"):
	set(v): toldo = v; queue_redraw()
@export var madera: Color = Color("a05000"):
	set(v): madera = v; queue_redraw()


# Offset para dibujar alineado a la grilla, sin importar dónde caiga el nodo.
func _snap() -> Vector2:
	return Vector2(floor(position.x / T) * T - position.x, floor(position.y / T) * T - position.y)


func _draw() -> void:
	var o := _snap()
	var w := ancho * T
	var cx := o.x + w / 2.0
	var gy := o.y + alto * T            # línea de piso (base del carrito)
	var madera_dk := madera.darkened(0.3)

	# --- Ruedas ---
	draw_circle(Vector2(cx - 7, gy - 1), 3.0, Pal.BLACK)
	draw_circle(Vector2(cx + 7, gy - 1), 3.0, Pal.BLACK)
	draw_circle(Vector2(cx - 7, gy - 1), 1.0, Pal.ROAD)
	draw_circle(Vector2(cx + 7, gy - 1), 1.0, Pal.ROAD)

	# --- Cuerpo del carrito (mostrador) ---
	draw_rect(Rect2(cx - 12, gy - 13, 24, 11), madera)          # cuerpo
	draw_rect(Rect2(cx - 12, gy - 5, 24, 3), madera_dk)         # sombra base
	draw_rect(Rect2(cx - 4, gy - 13, 1, 11), madera_dk)         # tabla
	draw_rect(Rect2(cx + 4, gy - 13, 1, 11), madera_dk)         # tabla
	draw_rect(Rect2(cx - 14, gy - 15, 28, 3), madera_dk)        # tapa del mostrador

	# --- Toldo a rayas sobre dos parantes ---
	draw_rect(Rect2(cx - 11, gy - 30, 1, 14), Pal.ROAD_DK)      # parante izq
	draw_rect(Rect2(cx + 10, gy - 30, 1, 14), Pal.ROAD_DK)      # parante der
	var i := 0
	while i < 28:
		var col: Color = toldo if (i / 4) % 2 == 0 else Pal.WHITE
		draw_rect(Rect2(cx - 14 + i, gy - 32, 4, 5), col)       # lona
		draw_rect(Rect2(cx - 14 + i + 1, gy - 27, 2, 2), col)   # festón
		i += 4
	draw_rect(Rect2(cx - 14, gy - 33, 28, 1), toldo.darkened(0.3))

	# --- Termo de café sobre el mostrador ---
	draw_rect(Rect2(cx - 10, gy - 22, 6, 8), Color("c0c0cc"))   # cuerpo metal
	draw_rect(Rect2(cx - 5, gy - 22, 1, 8), Color("8890a0"))    # brillo/sombra
	draw_rect(Rect2(cx - 11, gy - 23, 8, 1), Color("707888"))   # tapa
	draw_rect(Rect2(cx - 10, gy - 19, 6, 1), toldo)             # banda color
	draw_rect(Rect2(cx - 11, gy - 17, 1, 2), Pal.BLACK)         # canilla
	# vapor
	draw_rect(Rect2(cx - 8, gy - 26, 1, 3), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(cx - 6, gy - 27, 1, 3), Color(1, 1, 1, 0.6))

	# --- Pila de vasitos ---
	draw_rect(Rect2(cx + 2, gy - 19, 6, 5), Pal.WHITE)
	draw_rect(Rect2(cx + 2, gy - 19, 6, 1), Color("d8d8d8"))
	draw_rect(Rect2(cx + 2, gy - 17, 6, 1), Color("d8d8d8"))

	# --- Cartelito ---
	_draw_nombre(cx, gy)


func _draw_nombre(cx: float, gy: float) -> void:
	if nombre.is_empty():
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var tw := nombre.length() * 4 + 4
	var px := cx - tw / 2.0
	var py := gy - 36.0
	draw_rect(Rect2(px - 2, py - 8, tw + 2, 11), Pal.WHITE)
	draw_rect(Rect2(px - 3, py - 9, tw + 4, 13), Pal.BLACK, false, 1.0)
	draw_string(font, Vector2(px, py), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Pal.BLACK)


# El mundo (monte_grande) consulta esto para la colisión por grilla.
func bloquea(tx: int, ty: int) -> bool:
	var ox := int(floor(position.x / T))
	var oy := int(floor(position.y / T))
	return tx >= ox and tx < ox + ancho and ty >= oy and ty < oy + alto
