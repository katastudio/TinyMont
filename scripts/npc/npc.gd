extends StaticBody2D

@export var npc_name: String = "Vecino"
@export var dialog_lines: Array = ["¡Hola!"]
@export var npc_color: Color = Color("#8bac0f")

const GB_DARKEST := Color("#0f380f")

var facing := Vector2.DOWN


func _draw():
	# Body
	draw_rect(Rect2(-7, -7, 14, 14), npc_color)
	# Eyes based on facing
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


func interact(player_pos: Vector2):
	# Face toward the player
	var dir = (player_pos - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		facing = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if dir.y > 0 else Vector2.UP
	queue_redraw()

	GameManager.start_dialog(npc_name, dialog_lines)
