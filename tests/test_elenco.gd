extends Node
## Elenco completo de la historia (spec 0008 §4): cada misión se puede completar de punta a punta.
## Correr: godot --headless --path . res://tests/test_elenco.tscn

## Nombres reales de las figuras homenajeadas: no pueden aparecer en el juego (spec 0008 R7).
const NOMBRES_REALES := ["Messi", "Duki", "Bizarrap", "Riquelme", "Colapinto", "Mernes", "Becerra",
	"Luck Ra", "Salinas", "Tapari", "Oliván", "Olivan", "Cabak", "Dibu", "Gillespie", "Tiago PZK"]

## mision -> [giver, tipo, dato]: recado (dato = vecino que ayuda), busqueda (dato = nodo Objeto),
## contador, previas o contrarreloj (dato = vecino que da el objeto del recado).
const MISIONES := {
	"salina_zapada": ["DonSalina", "recado", "Gille"],
	"rodri_invitaciones": ["Rodri", "contador", ""],
	"caby_movil": ["Caby", "recado", "JuliNoticias"],
	"atajatodo_guantes": ["ElAtajatodo", "busqueda", "Guantes"],
	"franquito_carrera": ["Franquito", "contrarreloj", "Roman"],
	"duko_freestyle": ["ElDuko", "recado", "Tiaguito"],
	"emi_vincha": ["Emi", "busqueda", "Vincha"],
	"biza_nota": ["ElBiza", "recado", "Gille"],
	"nena_dueto": ["LaNena", "recado", "Emi"],
	"luki_karaoke": ["ElLuki", "contador", ""],
	"roman_practica": ["Roman", "recado", "ElAtajatodo"],
	"juli_entrevista": ["JuliNoticias", "previas", ""],
}

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	GameManager.inventario.clear()
	GameManager.misiones.clear()
	GameManager.contadores.clear()
	GameManager.cuentas.clear()
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	for n in m.get_children():
		n.set_process(false)
		n.set_physics_process(false)

	_check(GameManager.total_misiones() == 20, "el álbum tiene 20 misiones (%d)" % GameManager.total_misiones())

	# Homenajes sin nombres reales, ni en nombres ni en diálogos.
	for n in m.get_children():
		if not ("npc_name" in n):
			continue
		var texto := " ".join([n.npc_name] + n.dialog_lines + n.dialog_encargo + n.dialog_recordatorio + n.dialog_entrega)
		for real in NOMBRES_REALES:
			_check(not (real in texto), "%s no usa el nombre real %s" % [n.npc_name, real])

	var vecinos := ["Npc12Tito", "Npc10Walter", "Npc05DonaRosa", "Npc00DonCarlos"]
	for id in MISIONES:
		if id == "juli_entrevista":
			continue
		var datos: Array = MISIONES[id]
		var giver = m.get_node_or_null(datos[0])
		_check(giver != null and giver.mision_id == id, "%s encarga %s" % [datos[0], id])
		if giver == null:
			continue
		giver.dialogo_lines()
		_check(GameManager.get_estado_mision(id) == "en_curso", "%s: queda en curso" % id)
		match datos[1]:
			"recado", "contrarreloj":
				var ayudante = m.get_node(datos[2])
				ayudante.dialogo_lines()
				_check(GameManager.tiene_item(giver.requisito_item), "%s: %s da el recado (%s)" % [id, datos[2], giver.requisito_item])
				if datos[1] == "contrarreloj":
					_check(GameManager.tiempo_restante(id) > 0.0, "%s: corre el reloj" % id)
			"busqueda":
				var objeto = m.get_node(datos[2])
				_check(objeto.item == giver.requisito_item, "%s: el objeto %s es lo que busca" % [id, datos[2]])
				objeto.interact(Vector2.ZERO)
				GameManager.end_dialog()
			"contador":
				for v in vecinos:
					m.get_node(v).dialogo_lines()
		giver.dialogo_lines()
		_check(GameManager.get_estado_mision(id) == "completada", "%s: se completa" % id)
		_check(GameManager.tiene_item(giver.recompensa_item), "%s: regala %s" % [id, giver.recompensa_item])

	# Juli exige progreso previo: con 11 misiones completadas ya da la entrevista.
	var juli = m.get_node("JuliNoticias")
	_check(juli.requiere_completadas == 5, "Juli exige 5 misiones completadas")
	juli.dialogo_lines()
	_check(GameManager.get_estado_mision("juli_entrevista") == "completada", "Juli hace la entrevista")
	_check(GameManager.tiene_item("portada"), "Juli regala la portada")
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
