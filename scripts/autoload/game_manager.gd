extends Node

signal dialog_started
signal dialog_ended

var is_dialog_active: bool = false
var dialog_box = null


func _ready():
	_setup_input()


func _setup_input():
	_add_key_action("move_up", KEY_UP)
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_DOWN)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("interact", KEY_Z)
	_add_key_action("interact", KEY_ENTER)
	_add_key_action("interact", KEY_SPACE)
	_add_key_action("menu", KEY_X)
	_add_key_action("menu", KEY_ESCAPE)


func _add_key_action(action_name: String, key: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	InputMap.action_add_event(action_name, event)


func start_dialog(speaker_name: String, lines: Array, color: Color = Color.WHITE):
	is_dialog_active = true
	dialog_started.emit()
	if dialog_box:
		dialog_box.show_dialog(speaker_name, lines, color)


func end_dialog():
	is_dialog_active = false
	dialog_ended.emit()
