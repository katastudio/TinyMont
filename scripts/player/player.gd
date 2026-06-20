extends CharacterBody2D

const TILE_SIZE := 16
const MOVE_SPEED := 80.0

const GB_LIGHTEST := Color("#9bbc0f")
const GB_LIGHT := Color("#8bac0f")
const GB_DARK := Color("#306230")
const GB_DARKEST := Color("#0f380f")

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
	# Body
	draw_rect(Rect2(-7, -7, 14, 14), GB_LIGHT)
	# Shirt
	draw_rect(Rect2(-6, 1, 12, 6), GB_DARK)
	# Hair/cap
	draw_rect(Rect2(-5, -7, 10, 4), GB_DARKEST)
	# Eyes based on facing direction
	var eye_y := -1.0
	if facing == Vector2.DOWN:
		draw_rect(Rect2(-3, eye_y, 2, 2), GB_DARKEST)
		draw_rect(Rect2(1, eye_y, 2, 2), GB_DARKEST)
	elif facing == Vector2.UP:
		draw_rect(Rect2(-5, -7, 10, 6), GB_DARKEST)
	elif facing == Vector2.LEFT:
		draw_rect(Rect2(-5, eye_y, 2, 2), GB_DARKEST)
	elif facing == Vector2.RIGHT:
		draw_rect(Rect2(3, eye_y, 2, 2), GB_DARKEST)


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
