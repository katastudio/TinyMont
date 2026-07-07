@tool
extends StaticBody2D
## Un personaje editable 100% en el editor de Godot.
## Seleccioná el nodo y editá sus rasgos en el Inspector (grupo "Aspecto"):
## menús para gorra/pelo/vello facial/marca/accesorio, checkbox de lentes y
## selectores de color. El sprite se actualiza EN VIVO en el editor.

const CharacterArt = preload("res://scripts/art/character_art.gd")

@export var npc_name: String = "Vecino"
@export var dialog_lines: Array = ["¡Hola!"]

@export_group("Aspecto")
@export var piel: Color = Color("f4c29a")
@export_enum("short", "curly", "long", "slick", "bald") var pelo: String = "short"
@export var pelo_color: Color = Color("3a2a1a")
@export_enum("none", "cap", "fedora", "beanie", "headband") var gorra: String = "none"
@export var gorra_color: Color = Color("e03020")
@export_enum("none", "mustache", "beard", "stubble") var vello_facial: String = "none"
@export var lentes: bool = false
@export var camiseta: Color = Color("2f56d8")
@export_enum("none", "stripes", "badge") var marca: String = "none"
@export var marca_color: Color = Color("fcfcfc")
@export var pantalon: Color = Color("394a86")
@export_enum("none", "backpack") var accesorio: String = "none"

@export_group("Animación")
@export var respira: bool = true
@export var respira_amplitud: float = 1.0
@export var respira_velocidad: float = 2.0
@export var parpadea: bool = true
@export var parpadeo_cada: float = 4.0

var facing := Vector2.DOWN
var _t := 0.0


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
		shirt = camiseta, pants = pantalon,
		mark = marca, mark_col = marca_color, accessory = accesorio,
	}


func _process(delta):
	# Avanza la animación (respiración/parpadeo). Corre también en el editor (@tool).
	_t += delta
	queue_redraw()


func _draw():
	var st = CharacterArt.anim_state(_t, _anim_cfg(), false, float(get_index()) * 0.6)
	CharacterArt.draw_on(self, CharacterArt.map_rects(_descriptor(), st), Vector2(-8, -10 - st.bob), 1.0)


func interact(player_pos: Vector2):
	# Mira hacia el jugador y abre el diálogo.
	var dir = (player_pos - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		facing = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if dir.y > 0 else Vector2.UP
	GameManager.start_dialog(npc_name, dialog_lines, camiseta)
