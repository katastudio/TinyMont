@tool
extends Node2D
## Tren de la Línea Roca que cruza la vía cada cierto tiempo (100% procedural).
## Colocalo sobre la vía (Tile.RAIL): corre a lo largo de la FILA donde lo pongas,
## de una punta a la otra del mapa. En espera NO redibuja (no gasta frames).
## Editable en el Inspector: intervalo, velocidad, vagones, color.

const T := 16
const ALTO := 11        # alto del cuerpo del vagón (px)
const LARGO_VAG := 22   # largo de cada vagón
const SEP := 3          # enganche entre vagones

@export var intervalo := 40.0:      ## segundos entre pasadas
	set(v):
		intervalo = maxf(3.0, v)
@export var velocidad := 110.0      ## px por segundo
@export_range(1, 6) var vagones := 3:
	set(v):
		vagones = v
		queue_redraw()
@export var color := Color("2f7d4f"):        ## verde Roca
	set(v):
		color = v
		queue_redraw()
@export var color_techo := Color("e8e2d0")   ## crema

var _corriendo := false
var _der := true          # dirección de la próxima/actual pasada
var _t := 0.0             # temporizador de espera
var _left := 0.0          # borde IZQUIERDO del tren, en coords del mundo
var _row_top := 0.0       # y (mundo) del techo del tile de vía


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# esperar un frame: el mapa carga sus tiles en su propio _ready (después de los hijos)
	_t = intervalo * 0.4   # primera pasada no inmediata pero pronto


func _largo_total() -> float:
	return vagones * LARGO_VAG + (vagones - 1) * SEP


func _mundo_x() -> Vector2:
	# rango horizontal a cubrir (bordes del mapa), en coords del mundo
	var mapa := get_parent()
	var ancho := 44 * T
	if mapa and "MAP_W" in mapa:
		ancho = mapa.MAP_W * T
	return Vector2(0, ancho)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _corriendo:
		var largo := _largo_total()
		_left += (velocidad if _der else -velocidad) * delta
		var rango := _mundo_x()
		# fin de pasada cuando el tren salió por completo del lado opuesto
		if _der and _left > rango.y:
			_terminar()
		elif not _der and _left + largo < rango.x:
			_terminar()
		queue_redraw()
	else:
		_t += delta
		if _t >= intervalo:
			_arrancar()


func _arrancar() -> void:
	var rango := _mundo_x()
	var largo := _largo_total()
	_row_top = floor(position.y / T) * T
	if _der:
		_left = rango.x - largo          # entra desde la izquierda
	else:
		_left = rango.y                  # entra desde la derecha
	_corriendo = true


func _terminar() -> void:
	_corriendo = false
	_t = 0.0
	_der = not _der                      # alterna el sentido en la próxima pasada
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		# vista previa estática para ubicarlo en el editor
		var largo := _largo_total()
		var row: float = floor(position.y / T) * T - position.y
		_dibujar_tren(-largo / 2.0, row, true)
		return
	if not _corriendo:
		return
	# convertir de mundo a local (el _draw dibuja en coords locales del nodo)
	_dibujar_tren(_left - position.x, _row_top - position.y, _der)


func _dibujar_tren(left: float, row_top: float, mira_der: bool) -> void:
	var n := vagones
	var loco_idx := (n - 1) if mira_der else 0
	for i in n:
		var vx := left + i * (LARGO_VAG + SEP)
		_dibujar_vagon(vx, row_top, i == loco_idx, mira_der)
	# enganches entre vagones
	var dk := color.darkened(0.55)
	for i in n - 1:
		var ex := left + i * (LARGO_VAG + SEP) + LARGO_VAG
		draw_rect(Rect2(ex, row_top + 6, SEP, 2), dk)


func _dibujar_vagon(vx: float, row_top: float, es_loco: bool, mira_der: bool) -> void:
	var body_top := row_top + 1
	var dk := color.darkened(0.4)
	var vidrio := Color("bcd8ea")

	# cuerpo + techo + contorno
	draw_rect(Rect2(vx, body_top, LARGO_VAG, ALTO), color)
	draw_rect(Rect2(vx, body_top, LARGO_VAG, 2), color_techo)          # techo crema
	draw_rect(Rect2(vx, body_top + ALTO - 1, LARGO_VAG, 1), dk)        # sombra baja
	draw_rect(Rect2(vx, body_top, LARGO_VAG, ALTO), dk, false, 1.0)    # contorno

	# ventanas (fila de vidrios)
	var wy := body_top + 3
	var wx := vx + 3
	while wx + 4 <= vx + LARGO_VAG - 3:
		draw_rect(Rect2(wx, wy, 4, 4), vidrio)
		draw_rect(Rect2(wx, wy, 4, 4), dk, false, 1.0)
		wx += 6

	# frente de la locomotora + faro
	if es_loco:
		var fx := (vx + LARGO_VAG - 3) if mira_der else vx
		draw_rect(Rect2(fx, body_top + 1, 3, ALTO - 2), dk)           # cabina/frente
		var lx := (vx + LARGO_VAG - 2) if mira_der else (vx + 1)
		draw_rect(Rect2(lx, body_top + ALTO - 4, 1, 2), Color("ffe066"))  # faro
	else:
		# puerta central en vagones de pasajeros
		draw_rect(Rect2(vx + LARGO_VAG / 2.0 - 1, body_top + 2, 2, ALTO - 3), dk)

	# ruedas
	var wheel_y := body_top + ALTO
	draw_circle(Vector2(vx + 5, wheel_y), 2.0, dk)
	draw_circle(Vector2(vx + LARGO_VAG - 5, wheel_y), 2.0, dk)
	draw_circle(Vector2(vx + 5, wheel_y), 0.8, color_techo)
	draw_circle(Vector2(vx + LARGO_VAG - 5, wheel_y), 0.8, color_techo)
