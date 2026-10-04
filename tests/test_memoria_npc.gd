extends Node
## Test unitario de MemoriaNPC: hechos, rumores, olvido y relaciones (spec 0010, F3).
## Correr: godot --headless --path . res://tests/test_memoria_npc.tscn

const DIA := 24 * 60

var _fallas := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("OK: " + msg)
	else:
		_fallas += 1
		push_error("FALLA: " + msg)


func _ready() -> void:
	_test_sembrar_y_aprender()
	_test_charla_intercambia_y_suma_relacion()
	_test_rumor_viaja_por_tres()
	_test_olvido()
	_test_rumor_para_el_jugador()
	_test_serializacion()
	print("---- fallas: %d ----" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _test_sembrar_y_aprender() -> void:
	var m := MemoriaNPC.new()
	m.sembrar(["La plaza es de 1904."], 0, "Don Carlos")
	_check(m.conoce("La plaza es de 1904."), "conoce sus rumores semilla")
	_check(m.aprender("Hay feria el sábado.", 10, "Tito"), "aprende un hecho nuevo")
	_check(not m.aprender("Hay feria el sábado.", 20, "Rosa"), "no duplica un hecho conocido")
	_check(m.hechos.size() == 2, "guarda dos hechos")


func _test_charla_intercambia_y_suma_relacion() -> void:
	var a := MemoriaNPC.new()
	var b := MemoriaNPC.new()
	a.sembrar(["A sabe esto."], 0, "A")
	b.sembrar(["B sabe aquello."], 0, "B")
	var aprendidos := MemoriaNPC.charlar(a, "A", b, "B", 100)
	_check(aprendidos == 2, "en una charla cada uno aprende un hecho del otro")
	_check(a.conoce("B sabe aquello.") and b.conoce("A sabe esto."), "los dos hechos cruzaron")
	_check(a.relacion_con("B") == 1 and b.relacion_con("A") == 1, "la relación sube uno para ambos")
	_check(MemoriaNPC.charlar(a, "A", b, "B", 200) == 0, "sin novedades no aprenden nada")
	_check(a.relacion_con("B") == 2, "pero la relación sigue creciendo")


func _test_rumor_viaja_por_tres() -> void:
	var a := MemoriaNPC.new()
	var b := MemoriaNPC.new()
	var c := MemoriaNPC.new()
	a.sembrar(["Secreto de A."], 0, "A")
	MemoriaNPC.charlar(a, "A", b, "B", 10)
	MemoriaNPC.charlar(b, "B", c, "C", 20)
	_check(c.conoce("Secreto de A."), "un rumor aprendido se difunde a un tercero")
	_check(c.hechos.back().fuente == "B", "el tercero recuerda quién se lo contó")


func _test_olvido() -> void:
	var m := MemoriaNPC.new()
	m.sembrar(["Mi historia."], 0, "Yo")
	m.aprender("Chisme viejo.", 0, "Otro")
	m.aprender("Chisme nuevo.", 3 * DIA, "Otro")
	m.olvidar_viejos(3 * DIA + 1)
	_check(not m.conoce("Chisme viejo."), "olvida rumores ajenos de más de 3 días")
	_check(m.conoce("Chisme nuevo."), "recuerda rumores recientes")
	_check(m.conoce("Mi historia."), "nunca olvida sus propios hechos semilla")


func _test_rumor_para_el_jugador() -> void:
	var m := MemoriaNPC.new()
	m.sembrar(["Lo mío."], 0, "Yo")
	_check(m.ultimo_rumor_ajeno().is_empty(), "sin rumores ajenos no hay chisme")
	m.aprender("Primero.", 10, "Otro")
	m.aprender("Último.", 20, "Otro")
	_check(m.ultimo_rumor_ajeno().get("texto") == "Último.", "cuenta el rumor ajeno más reciente")


func _test_serializacion() -> void:
	var m := MemoriaNPC.new()
	m.sembrar(["Uno."], 0, "Yo")
	m.aprender("Dos.", 5, "Otro")
	m.ajustar_relacion("Otro", 3)
	var copia := MemoriaNPC.desde_dict(JSON.parse_string(JSON.stringify(m.a_dict())))
	_check(copia.conoce("Dos.") and copia.relacion_con("Otro") == 3, "la memoria sobrevive a JSON")
	_check(copia.a_dict() == m.a_dict(), "la serialización es estable")
