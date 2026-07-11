@tool
extends CharacterBody2D

const TILE_SIZE := 16
const MOVE_SPEED := 80.0
const BICI_FACTOR := 1.7    # en bici va más rápido
const CharacterArt = preload("res://scripts/art/character_art.gd")
const BiciArt = preload("res://scripts/art/bici_art.gd")

# Rasgos del protagonista (el recién llegado). Editables en player.tscn (Inspector).
@export_group("Aspecto")
@export var piel: Color = Color("f4c29a")
@export_enum("short", "curly", "long", "slick", "bald") var pelo: String = "short"
@export var pelo_color: Color = Color("4a3320")
@export_enum("none", "cap", "fedora", "beanie", "headband") var gorra: String = "cap"
@export var gorra_color: Color = Color("e03020")
@export_enum("none", "mustache", "beard", "stubble") var vello_facial: String = "none"
@export var lentes: bool = false
@export var camiseta: Color = Color("2f56d8")
@export var pantalon: Color = Color("394a86")
@export_enum("none", "backpack") var accesorio: String = "backpack"
@export_enum("none", "stripes", "badge") var marca: String = "none"
@export var marca_color: Color = Color("fcfcfc")

@export_group("Animación")
@export var respira: bool = true
@export var respira_amplitud: float = 1.0
@export var respira_velocidad: float = 2.0
@export var parpadea: bool = true
@export var parpadeo_cada: float = 4.0

var is_moving := false
var target_pos := Vector2.ZERO
var facing := Vector2.DOWN
var _t := 0.0
var _bici_ref: Node2D = null    # la bici que Monti tomó (oculta mientras la usa)


func _anim_cfg() -> Dictionary:
	return {
		respira = respira, respira_amp = respira_amplitud, respira_vel = respira_velocidad,
		parpadea = parpadea, parpadeo_cada = parpadeo_cada,
	}


func _descriptor() -> Dictionary:
	return {
		skin = piel, hair = pelo_color, hair_style = pelo,
		hat = gorra, hat_col = gorra_color,
		facial = vello_facial, glasses = lentes,
		shirt = camiseta, pants = pantalon, accessory = accesorio,
		mark = marca, mark_col = marca_color,
	}


func _process(delta):
	_t += delta
	queue_redraw()


func _ready():
	if Engine.is_editor_hint():
		return
	# Snap to tile center (not corner)
	var tx := int(position.x / TILE_SIZE)
	var ty := int(position.y / TILE_SIZE)
	position = Vector2(tx * TILE_SIZE + TILE_SIZE / 2.0, ty * TILE_SIZE + TILE_SIZE / 2.0)
	target_pos = position


func _draw():
	# El protagonista se dibuja desde sus rasgos, con animación (respira / camina).
	var st = CharacterArt.anim_state(_t, _anim_cfg(), is_moving, 0.0)
	if not Engine.is_editor_hint() and GameManager.en_bici:
		# Montado: la bici debajo (ruedas girando: rápido al andar) y Monti sentado más arriba.
		var phase := _t * (10.0 if is_moving else 2.0)
		# lateral: bici al ras del piso; vertical: centrada en el cuerpo (asoma arriba y abajo)
		var base := Vector2(0, -2) if facing.y != 0 else Vector2(0, 7)
		BiciArt.draw_on(self, base, phase, GameManager.bici_color, facing)
		CharacterArt.draw_on(self, CharacterArt.map_rects(_descriptor(), st), Vector2(-8, -13 - st.bob), 1.0)
	else:
		CharacterArt.draw_on(self, CharacterArt.map_rects(_descriptor(), st), Vector2(-8, -10 - st.bob), 1.0)


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	if GameManager.is_dialog_active:
		return

	if is_moving:
		var spd := MOVE_SPEED * (BICI_FACTOR if GameManager.en_bici else 1.0)
		position = position.move_toward(target_pos, spd * delta)
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


func _can_move_to(pos: Vector2) -> bool:
	var world = get_parent()
	if world.has_method("is_walkable"):
		return world.is_walkable(pos)
	return true


# Interacción por evento (no polling): consume la tecla para que el diálogo
# no la reciba en el mismo frame (evita saltear la primera línea al abrir).
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if GameManager.is_dialog_active:
		return
	if event.is_action_pressed("toggle_bici"):
		_toggle_bici()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()


func _interact():
	var face_pos = position + facing * TILE_SIZE
	var world = get_parent()
	if world.has_method("get_npc_at"):
		var npc = world.get_npc_at(face_pos)
		if npc and npc.has_method("interact"):
			npc.interact(global_position)


# ==================== BICI (botón B) ====================

func _toggle_bici() -> void:
	if GameManager.en_bici:
		_bajar_bici()
	else:
		_subir_bici()


# Buscar una bici en la celda actual o adyacente (radio 1 tile).
func _bici_cercana() -> Node2D:
	var world = get_parent()
	var ptx := int(position.x / TILE_SIZE)
	var pty := int(position.y / TILE_SIZE)
	for child in world.get_children():
		if child.has_method("es_bici") and child.visible:
			var t: Vector2i = child.tile()
			if absi(t.x - ptx) <= 1 and absi(t.y - pty) <= 1:
				return child
	return null


func _subir_bici() -> void:
	var bici := _bici_cercana()
	if bici == null:
		return   # no hay bici cerca: no pasa nada
	GameManager.en_bici = true
	GameManager.bici_color = bici.color
	bici.visible = false
	bici.set_process(false)      # pausa su animación mientras está "guardada"
	_bici_ref = bici
	queue_redraw()


func _bajar_bici() -> void:
	GameManager.en_bici = false
	if _bici_ref:
		# dejar la bici estacionada en la celda actual
		var tx := int(position.x / TILE_SIZE)
		var ty := int(position.y / TILE_SIZE)
		_bici_ref.position = Vector2(tx * TILE_SIZE + TILE_SIZE / 2.0, ty * TILE_SIZE + TILE_SIZE / 2.0)
		_bici_ref.visible = true
		_bici_ref.set_process(true)
	_bici_ref = null
	queue_redraw()
