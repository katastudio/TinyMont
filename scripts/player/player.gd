extends CharacterBody2D

const TILE_SIZE := 16
const MOVE_SPEED := 80.0

# Colores desde la paleta compartida (Pal)

var is_moving := false
var target_pos := Vector2.ZERO
var facing := Vector2.DOWN


func _ready():
	# Snap to tile center (not corner)
	var tx := int(position.x / TILE_SIZE)
	var ty := int(position.y / TILE_SIZE)
	position = Vector2(tx * TILE_SIZE + TILE_SIZE / 2.0, ty * TILE_SIZE + TILE_SIZE / 2.0)
	target_pos = position


func _draw():
	# Cara (piel)
	draw_rect(Rect2(-6, -3, 12, 10), Pal.SKIN)
	# Overol azul
	draw_rect(Rect2(-6, 3, 12, 4), Pal.BLUE)
	# Gorra roja
	draw_rect(Rect2(-7, -7, 14, 4), Pal.RED)
	draw_rect(Rect2(-2, -8, 8, 2), Pal.RED)
	# Ojos según dirección
	var eye_y := 0.0
	if facing == Vector2.DOWN:
		draw_rect(Rect2(-3, eye_y, 2, 2), Pal.BLACK)
		draw_rect(Rect2(1, eye_y, 2, 2), Pal.BLACK)
	elif facing == Vector2.UP:
		draw_rect(Rect2(-5, -3, 10, 3), Pal.RED)
	elif facing == Vector2.LEFT:
		draw_rect(Rect2(-5, eye_y, 2, 2), Pal.BLACK)
	elif facing == Vector2.RIGHT:
		draw_rect(Rect2(3, eye_y, 2, 2), Pal.BLACK)


func _physics_process(delta):
	if GameManager.is_dialog_active:
		return

	if is_moving:
		position = position.move_toward(target_pos, MOVE_SPEED * delta)
		if position.distance_to(target_pos) < 0.5:
			position = target_pos
			is_moving = false
	else:
		_handle_input()


func _handle_input():
	var dir := Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		dir = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		dir = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		dir = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		dir = Vector2.RIGHT

	if dir != Vector2.ZERO:
		facing = dir
		queue_redraw()

		var next_pos = position + dir * TILE_SIZE
		if _can_move_to(next_pos):
			target_pos = next_pos
			is_moving = true

	if Input.is_action_just_pressed("interact"):
		_interact()


func _can_move_to(pos: Vector2) -> bool:
	var world = get_parent()
	if world.has_method("is_walkable"):
		return world.is_walkable(pos)
	return true


func _interact():
	var face_pos = position + facing * TILE_SIZE
	var world = get_parent()
	if world.has_method("get_npc_at"):
		var npc = world.get_npc_at(face_pos)
		if npc and npc.has_method("interact"):
			npc.interact(global_position)
