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

# Misión data-driven. Un mismo NPC puede ser el que ENCARGA (giver) o un
# AYUDANTE (helper) que entrega un objeto. Si mision_id está vacío, es ambiental.
@export_group("Misión")
@export var mision_id: String = ""                 # vacío = NPC ambiental (solo dialog_lines)
@export var dialog_encargo: Array = []             # giver: al encargar (no_iniciada -> en_curso)
@export var dialog_recordatorio: Array = []        # misión en curso, aún sin cumplir
@export var dialog_entrega: Array = []             # giver: al cumplir; helper: al dar el objeto
@export var requisito_item: String = ""            # giver: objeto que pide para completar
@export var recompensa_item: String = ""           # giver: objeto que regala al completar
@export var otorga_item: String = ""               # helper: objeto que entrega durante la misión

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
	_mirar(player_pos)

	# NPC ambiental (sin misión): diálogo simple.
	if mision_id == "":
		_decir(dialog_lines)
		return

	var estado := GameManager.get_estado_mision(mision_id)

	# AYUDANTE: entrega su objeto mientras la misión está en curso (ej: Sandra da los vasitos).
	if otorga_item != "":
		if estado == "en_curso" and not GameManager.tiene_item(otorga_item):
			GameManager.agregar_item(otorga_item)
			_decir(dialog_entrega)
		elif estado == "en_curso":
			_decir(dialog_recordatorio)      # ya lo tenés, llevalo
		else:
			_decir(dialog_lines)             # ambiental (antes/después de la misión)
		return

	# GIVER: encarga, recuerda y completa la misión (ej: Marcos).
	match estado:
		"no_iniciada":
			GameManager.set_estado_mision(mision_id, "en_curso")
			_decir(dialog_encargo)
		"en_curso":
			if requisito_item != "" and GameManager.tiene_item(requisito_item):
				GameManager.quitar_item(requisito_item)
				GameManager.set_estado_mision(mision_id, "completada")
				if recompensa_item != "":
					GameManager.agregar_item(recompensa_item)
				_decir(dialog_entrega)
			else:
				_decir(dialog_recordatorio)
		_:
			_decir(dialog_lines)             # misión completada: charla post-misión


func _mirar(player_pos: Vector2) -> void:
	var dir = (player_pos - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		facing = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if dir.y > 0 else Vector2.UP


func _decir(lines: Array) -> void:
	var l: Array = lines if not lines.is_empty() else dialog_lines
	GameManager.start_dialog(npc_name, l, camiseta)
