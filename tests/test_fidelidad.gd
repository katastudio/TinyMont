extends Node
## Fidelidad del centro de Monte Grande (spec 0007), según Wikipedia (Plaza Mitre y Parroquia
## Inmaculada Concepción): la plaza está rodeada por el Palacio Municipal, la Escuela N°1, la
## Comisaría 1ª, la Parroquia y el ex Hospital San José (Casa de la Cultura); hay bancos en el
## entorno; en el centro hay una fuente octogonal celeste con bordes blancos.
## Correr: godot --headless --path . res://tests/test_fidelidad.tscn

const FUENTE := Vector2i(22, 33)
const CERCA := 16    # distancia máxima (Manhattan) a la fuente para "rodear la plaza"

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	WorldClock.set_process(false)
	var m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var cerca := {}
	for anchor in m.building_info:
		var b = m.building_info[anchor]
		var d: Vector2i = anchor - FUENTE
		if absi(d.x) + absi(d.y) <= CERCA:
			cerca[str(b.type)] = true
	for n in m.get_children():
		if n.has_method("bloquea") and "nombre" in n:
			var d: Vector2i = m.celda_de(n.position) - FUENTE
			if absi(d.x) + absi(d.y) <= CERCA:
				cerca[str(n.nombre)] = true
	for tipo in ["govt", "school", "police", "church"]:
		_check(cerca.has(tipo), "la plaza está rodeada por: %s" % tipo)
	_check(cerca.has("CASA DE LA CULTURA"), "la Casa de la Cultura (ex Hospital San José) está junto a la plaza")
	_check(cerca.has("BANCO PROVINCIA"), "el Banco Provincia está junto a la plaza")

	var fuente: Rect2i = m.fuente_rect()
	_check(fuente.size == Vector2i(3, 3) and fuente.has_point(FUENTE), "la fuente ocupa el centro de la plaza")
	var octogono: PackedVector2Array = m.fuente_octogono()
	_check(octogono.size() == 8, "la fuente es octogonal")
	var npcs: int = m.get_children().filter(func(n): return "npc_name" in n).size()
	_check(npcs >= 12, "hay al menos 12 vecinos (%d)" % npcs)
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)
