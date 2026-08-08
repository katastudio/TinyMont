extends Node
## MusicManager — música y SFX chiptune 100% procedurales, estilo Game Boy/NES.
## Cero assets de audio: cada tema se sintetiza en runtime a AudioStreamWAV
## (16-bit PCM mono @ 22050 Hz) y se cachea. Voces: onda cuadrada con duty
## variable (melodía/armonía), triángulo (bajo) y ruido LFSR (percusión).
## Los SFX cortos se renderizan sync en _ready; los temas largos se renderizan
## por chunks en _process (presupuesto por frame) para no trabar ningún frame.
## Las partituras son datos GDScript (abajo): tocalas y experimentá.
## Tecla M = mute/unmute global.

signal enabled_changed(enabled: bool)

const MIX_RATE := 22050
const MUSIC_DB := -13.0
const SFX_DB := -6.0
const SFX_VOICES := 4     # polifonía simple para SFX (round-robin)
const FADE_S := 0.3
const BUDGET_USEC := 6000 # tope de trabajo de síntesis por frame (~6 ms)
const LFSR_SEED := 0x1FA3 # semilla del ruido POR canal (timbre determinista)

var _cache := {}          # id -> AudioStreamWAV ya renderizado
var _music: AudioStreamPlayer
var _sfx: Array = []
var _sfx_i := 0
var _actual := ""
var _esperando := ""      # tema pedido que todavía se está renderizando
var _enabled := true
var _fade: Tween
var _cola: Array = []     # ids pendientes de render incremental
var _job := {}            # render en curso: {id, mix, bytes, ops, i, enc, loop, us}
var _gen_us := 0          # tiempo total de síntesis (se reporta en consola)
var _peor_frame_us := 0   # frame más caro del render incremental


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		_sfx.append(p)
	_add_key_action("toggle_musica", KEY_M)
	# SFX y jingle cortos sync (unos pocos ms); los temas largos van por
	# chunks en _process, en orden de primer uso (título -> pueblo -> encuentro).
	for id in ["blip_dialogo", "campanita_objeto", "bocina_tren", "timbre_bici",
			"jingle_mision", "menu_move", "encuentro_inicio"]:
		_ensure(id)
	_cola = ["tema_titulo", "tema_pueblo", "tema_encuentro", "fanfarria_victoria"]


# Render incremental: reparte la síntesis entre frames con presupuesto de
# tiempo (nada de renderizar un tema entero en un frame -> sin hitch).
func _process(_delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < BUDGET_USEC:
		if _job.is_empty():
			if _cola.is_empty():
				set_process(false)
				print("MusicManager: síntesis completa en %d ms (peor frame: %d ms)"
						% [_gen_us / 1000, _peor_frame_us / 1000])
				break
			var id: String = _cola.pop_front()
			if not _cache.has(id):
				_job = _make_job(id, _song(id))
		elif not _run_paso(_job):
			_finalizar_job()
	var dt := int(Time.get_ticks_usec() - t0)
	_gen_us += dt
	_peor_frame_us = maxi(_peor_frame_us, dt)


func _finalizar_job() -> void:
	var id: String = _job.id
	_cache[id] = _wav_de_job(_job)
	print("MusicManager: %s renderizado en %d ms (incremental)" % [id, _job.us / 1000])
	_job = {}
	if _esperando == id:
		_esperando = ""
		_iniciar_con_fade(id)


# Mismo patrón que GameManager._add_key_action (acciones registradas en runtime).
func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	InputMap.action_add_event(action_name, event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_musica"):
		set_enabled(not _enabled)


# ==================== API ====================

func play_music(id: String) -> void:
	if id == _actual and (_music.playing or _esperando == id):
		return
	_actual = id
	if not _cache.has(id):
		# Aún renderizándose: NO se renderiza sync (ese era el hitch);
		# arranca solo al completar el render, con el fade normal.
		_esperando = id
		if _job.get("id", "") != id and not _cola.has(id):
			_cola.append(id)
			set_process(true)
		return
	_esperando = ""
	_iniciar_con_fade(id)


func _iniciar_con_fade(id: String) -> void:
	if _fade:
		_fade.kill()
	if _music.playing:
		# mini fade: bajar, swapear, volver
		_fade = create_tween()
		_fade.tween_property(_music, "volume_db", -40.0, FADE_S)
		_fade.tween_callback(_swap_music.bind(id))
	else:
		_swap_music(id)


func _swap_music(id: String) -> void:
	_music.stream = _ensure(id)
	_music.volume_db = MUSIC_DB
	_music.play()


# Reinicia el tema desde el principio aunque ya sea el actual (autoplay web:
# el primer gesto del usuario reanuda el AudioContext y se vuelve a arrancar).
func restart_music(id: String) -> void:
	_actual = ""
	_esperando = ""
	if _fade:
		_fade.kill()
	_music.stop()
	play_music(id)


func stop_music() -> void:
	_actual = ""
	_esperando = ""
	if _fade:
		_fade.kill()
	if _music.playing:
		_fade = create_tween()
		_fade.tween_property(_music, "volume_db", -40.0, FADE_S)
		_fade.tween_callback(_music.stop)


func play_sfx(id: String) -> void:
	var p: AudioStreamPlayer = _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = _ensure(id)
	p.play()


func set_enabled(v: bool) -> void:
	_enabled = v
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not v)
	enabled_changed.emit(v)


func is_enabled() -> bool:
	return _enabled


# ==================== PARTITURAS (datos, tocá acá) ====================
# Cada canal: wave (square/tri/noise), duty, vol, attack/decay (envolvente, en s),
# gate (fracción de la nota que suena; el resto es silencio -> staccato) y
# notes = [[nota, duración_en_beats], ...] (tercer elemento opcional = gate por
# nota). Nota: nombre ("C4", "F#3"), número MIDI, "r" (silencio) o "kick"/"hat"
# en el canal de ruido.

# Acordes como [fundamental, tercera, quinta] en MIDI (registro medio-bajo).
const CHORDS := {
	"C": [48, 52, 55], "Am": [45, 48, 52], "F": [45, 48, 53],
	"G": [43, 47, 50], "D": [50, 54, 57],
	"Dm": [50, 53, 57], "E": [52, 56, 59],
}

# Pueblo relajado pero juguetón: forma A-A-B-A (4+4+8+4 compases de 4/4).
const PROG_A: Array = ["C", "F", "C", "G"]
const PROG_B: Array = ["Am", "F", "C", "G", "Am", "F", "D", "G"]
const PROG_TITULO: Array = ["C", "F", "Am", "G", "F", "G"]

# Frase A (Do mayor, diatónica): la semilla E-G-C5 del juego en pregunta
# (2 compases) y respuesta (2), con silencios reales para que respire.
const FRASE_A: Array = [
	["E4", 0.5], ["G4", 0.5], ["C5", 1.5], ["A4", 0.5], ["G4", 1],
	["E4", 0.5], ["G4", 0.5], ["A4", 2], ["r", 1],
	["D5", 0.5], ["C5", 0.5], ["A4", 1.5], ["G4", 0.5], ["E4", 1],
	["G4", 0.5], ["A4", 0.5], ["G4", 1], ["r", 2],
]

# Frase B: contraste en La menor, ecos con silencios y el salto de octava
# juguetón C4->C5; el F#4 aparece solo como tercera del D (V/V) que empuja
# de vuelta a la frase A.
const FRASE_B: Array = [
	["E5", 0.5], ["r", 0.5], ["D5", 0.5], ["C5", 0.5], ["A4", 2],
	["A4", 0.5], ["C5", 0.5], ["F5", 1.5], ["E5", 0.5], ["r", 1],
	["G4", 0.5], ["C5", 0.5], ["E5", 1.5], ["D5", 0.5], ["C5", 1],
	["B4", 0.5], ["A4", 0.5], ["G4", 1], ["r", 2],
	["C4", 0.5], ["C5", 0.5], ["r", 0.5], ["A4", 0.5], ["E4", 2],
	["F4", 0.5], ["A4", 0.5], ["C5", 1], ["A4", 0.5], ["F4", 1.5],
	["F#4", 0.5], ["A4", 0.5], ["D5", 1.5], ["A4", 0.5], ["F#4", 1],
	["G4", 0.5], ["A4", 0.5], ["B4", 1], ["r", 2],
]

# Título: la misma semilla E-G-C5, más liviana y a menor tempo (6 compases).
const MELODIA_TITULO: Array = [
	["E4", 0.5], ["G4", 0.5], ["C5", 1], ["r", 0.5], ["A4", 0.5], ["G4", 1],
	["A4", 0.5], ["C5", 1], ["A4", 0.5], ["F4", 1], ["C4", 1],
	["E4", 0.5], ["A4", 0.5], ["C5", 0.5], ["B4", 0.5], ["A4", 1], ["E4", 1],
	["D4", 0.5], ["G4", 0.5], ["B4", 0.5], ["A4", 0.5], ["G4", 1], ["F#4", 0.5], ["G4", 0.5],
	["A4", 1], ["G4", 0.5], ["F4", 0.5], ["C5", 1], ["A4", 1],
	["G4", 0.5], ["A4", 0.5], ["B4", 1], ["D5", 1], ["r", 1],
]

# Encuentro estilo subsuelo: Do menor, 12 compases de 4/4 (48 beats).
# Riff staccato con salto de octava y silencios marcados, conectores
# cromáticos entre frases y un compás de solo percusión. Melodía y bajos
# tocan las MISMAS notas a distinta octava (unísono punchy).
const MELODIA_ENCUENTRO: Array = [
	# A: riff punchy + respiro (F#->G cromático cierra la frase)
	["C4", 0.5], ["C5", 0.5], ["r", 0.5], ["G4", 0.5], ["r", 0.5], ["D#4", 0.5], ["r", 0.5], ["F4", 0.5],
	["F#4", 0.5], ["G4", 0.5], ["r", 3],
	# A': mismo riff, bajada cromática como conector
	["C4", 0.5], ["C5", 0.5], ["r", 0.5], ["G4", 0.5], ["r", 0.5], ["D#4", 0.5], ["r", 0.5], ["F4", 0.5],
	["F4", 0.5], ["E4", 0.5], ["D#4", 0.5], ["D4", 0.5], ["r", 2],
	# B: respuesta una cuarta arriba (B->C cromático)
	["F4", 0.5], ["F5", 0.5], ["r", 0.5], ["C5", 0.5], ["r", 0.5], ["G#4", 0.5], ["r", 0.5], ["A#4", 0.5],
	["B4", 0.5], ["C5", 0.5], ["r", 3],
	# subida cromática completa + compás de solo percusión
	["C4", 0.5], ["C#4", 0.5], ["D4", 0.5], ["D#4", 0.5], ["E4", 0.5], ["F4", 0.5], ["F#4", 0.5], ["G4", 0.5],
	["r", 4],
	# A otra vez
	["C4", 0.5], ["C5", 0.5], ["r", 0.5], ["G4", 0.5], ["r", 0.5], ["D#4", 0.5], ["r", 0.5], ["F4", 0.5],
	["F#4", 0.5], ["G4", 0.5], ["r", 3],
	# variante alta + caída cromática que empuja al Do del loop
	["C4", 0.5], ["C5", 0.5], ["r", 0.5], ["A#4", 0.5], ["r", 0.5], ["G#4", 0.5], ["r", 0.5], ["G4", 0.5],
	["D#4", 0.5], ["D4", 0.5], ["C#4", 0.5], ["r", 2.5],
]


func _song(id: String) -> Dictionary:
	match id:
		"tema_pueblo":
			# Suave y juguetón: 124 bpm, Do mayor, A-A-B-A (~38.7 s de loop).
			# Gate largo (apenas separado), arpegios en negras y percusión discreta.
			var prog: Array = PROG_A + PROG_A + PROG_B + PROG_A
			return {bpm = 124, loop = true, channels = [
				{wave = "square", duty = 0.5, vol = 0.20, decay = 0.5, gate = 0.82,
					notes = FRASE_A + FRASE_A + FRASE_B + FRASE_A},
				{wave = "square", duty = 0.25, vol = 0.08, decay = 0.5, gate = 0.85,
					notes = _arp(prog)},
				{wave = "tri", vol = 0.26, decay = 0.55, gate = 0.8, notes = _bajo(prog)},
				{wave = "noise", vol = 0.07, notes = _perc(prog.size())},
			]}
		"tema_titulo":
			# Misma semilla, dulce: 94 bpm, 6 compases (~15.3 s), sin percusión.
			return {bpm = 94, loop = true, channels = [
				{wave = "square", duty = 0.5, vol = 0.22, decay = 0.6, gate = 0.8,
					notes = MELODIA_TITULO},
				{wave = "square", duty = 0.25, vol = 0.09, decay = 0.5, gate = 0.85,
					notes = _arp(PROG_TITULO)},
				{wave = "tri", vol = 0.26, decay = 0.7, gate = 0.85, notes = _bajo(PROG_TITULO)},
			]}
		"tema_encuentro":
			# Subsuelo: 160 bpm, Do menor, riff en octavas con gate corto (~18.0 s).
			# Textura rala: sin acompañamiento continuo, el silencio es parte del groove.
			return {bpm = 160, loop = true, channels = [
				{wave = "square", duty = 0.5, vol = 0.20, decay = 0.3, gate = 0.5,
					notes = MELODIA_ENCUENTRO},
				{wave = "square", duty = 0.25, vol = 0.09, decay = 0.3, gate = 0.5,
					notes = _transp(MELODIA_ENCUENTRO, -12)},
				{wave = "tri", vol = 0.26, decay = 0.35, gate = 0.55,
					notes = _transp(MELODIA_ENCUENTRO, -24)},
				{wave = "noise", vol = 0.08, notes = _perc_subsuelo()},
			]}
		"jingle_mision":
			# Arpegio ascendente de Do mayor (~1.5 s).
			return {bpm = 120, channels = [
				{wave = "square", duty = 0.5, vol = 0.26, decay = 0.5,
					notes = [["G4", 0.5], ["C5", 0.5], ["E5", 0.5], ["G5", 1.5]]},
				{wave = "square", duty = 0.25, vol = 0.14, decay = 0.5,
					notes = [["E4", 0.5], ["G4", 0.5], ["C5", 0.5], ["E5", 1.5]]},
				{wave = "tri", vol = 0.30, decay = 0.8, notes = [["C3", 3.0]]},
			]}
		"fanfarria_victoria":
			# Fanfarria triunfal (~3 s): sol-sol-sol-DO, mi-re-mi-SOL.
			return {bpm = 128, channels = [
				{wave = "square", duty = 0.5, vol = 0.26, decay = 1.0, notes = [
					["G4", 0.5], ["G4", 0.5], ["G4", 0.5], ["C5", 1.5],
					["E5", 0.5], ["D5", 0.5], ["E5", 0.5], ["G5", 2.0]]},
				{wave = "square", duty = 0.25, vol = 0.14, decay = 1.0, notes = [
					["E4", 0.5], ["E4", 0.5], ["E4", 0.5], ["G4", 1.5],
					["C5", 0.5], ["B4", 0.5], ["C5", 0.5], ["E5", 2.0]]},
				{wave = "tri", vol = 0.32, decay = 0.9, notes = [
					["C3", 0.5], ["C3", 0.5], ["C3", 0.5], ["C3", 1.5],
					["G2", 1.5], ["C3", 2.0]]},
				{wave = "noise", vol = 0.12, notes = [
					["kick", 0.5], ["kick", 0.5], ["kick", 0.5], ["hat", 1.5],
					["kick", 0.5], ["hat", 0.5], ["kick", 0.5], ["kick", 2.0]]},
			]}
		"blip_dialogo":
			# ~40 ms, para el typewriter del diálogo.
			return {bpm = 150, channels = [
				{wave = "square", duty = 0.25, vol = 0.30, attack = 0.002, decay = 0.025,
					notes = [["D6", 0.1]]},
			]}
		"campanita_objeto":
			# Ding-ding brillante al recoger un objeto.
			return {bpm = 120, channels = [
				{wave = "square", duty = 0.125, vol = 0.28, decay = 0.22,
					notes = [["B5", 0.25], ["E6", 1.0]]},
			]}
		"bocina_tren":
			# Bocina diésel: dos tonos a una tercera menor, más baja y corta.
			return {bpm = 120, channels = [
				{wave = "square", duty = 0.5, vol = 0.10, attack = 0.02, decay = 1.8,
					notes = [["G#3", 1.3]]},
				{wave = "square", duty = 0.5, vol = 0.10, attack = 0.02, decay = 1.8,
					notes = [["B3", 1.3]]},
			]}
		"timbre_bici":
			# Ring-ring metálico de timbre de bici.
			return {bpm = 120, channels = [
				{wave = "square", duty = 0.125, vol = 0.30, decay = 0.10,
					notes = [["E6", 0.12], ["r", 0.06], ["E6", 0.5]]},
			]}
		"menu_move":
			# Blip grave cortito (~40 ms) al mover el cursor del menú del encuentro.
			return {bpm = 150, channels = [
				{wave = "square", duty = 0.5, vol = 0.24, attack = 0.002, decay = 0.03,
					notes = [["A4", 0.1]]},
			]}
		"encuentro_inicio":
			# Barrido ascendente rápido (~0.4 s) al abrir la pantalla de encuentro.
			return {bpm = 600, channels = [
				{wave = "square", duty = 0.25, vol = 0.22, attack = 0.002, decay = 0.12,
					notes = [["C4", 0.5], ["E4", 0.5], ["G4", 0.5], ["C5", 0.5],
						["E5", 0.5], ["G5", 0.5], ["C6", 1.0]]},
			]}
	push_error("MusicManager: id desconocido '" + id + "'")
	return {bpm = 120, channels = []}


# Armonía tranquila: arpegio tercera-quinta-octava-quinta en negras,
# un compás por acorde.
func _arp(prog: Array) -> Array:
	var out := []
	for c in prog:
		var ch: Array = CHORDS[c]
		out += [[ch[1], 1.0], [ch[2], 1.0], [ch[0] + 12, 1.0], [ch[2], 1.0]]
	return out


# Bajo que CAMINA en triángulo: fundamental-quinta-sexta-quinta (boogie suave).
func _bajo(prog: Array) -> Array:
	var out := []
	for c in prog:
		var r: int = CHORDS[c][0] - 12
		out += [[r, 1.0], [r + 7, 1.0], [r + 9, 1.0], [r + 7, 1.0]]
	return out


# Transpone una partitura en semitonos (silencios quedan igual; conserva
# el gate por nota si lo hay). Mismas duraciones -> mismo total de beats.
func _transp(notes: Array, semis: int) -> Array:
	var out := []
	for ev in notes:
		if ev[0] is String and ev[0] == "r":
			out.append(ev)
		else:
			var nuevo: Array = ev.duplicate()
			nuevo[0] = _midi(ev[0]) + semis
			out.append(nuevo)
	return out


# Percusión subsuelo: hat en corcheas con kick marcando el riff (1 y 3);
# fill de kicks en los compases de respiro (8 y 12).
func _perc_subsuelo() -> Array:
	var base := [["kick", 0.5], ["hat", 0.5], ["hat", 0.5], ["hat", 0.5],
		["kick", 0.5], ["hat", 0.5], ["hat", 0.5], ["hat", 0.5]]
	var fill := [["kick", 0.5], ["kick", 0.5], ["hat", 0.5], ["kick", 0.5],
		["hat", 0.5], ["hat", 0.5], ["kick", 0.5], ["hat", 0.5]]
	var out := []
	for b in 12:
		out += fill if (b == 7 or b == 11) else base
	return out


# Percusión discreta: kick solo en el 1, hat suave en 2 y 4.
func _perc(bars: int) -> Array:
	var bar := [["kick", 1.0], ["hat", 1.0], ["r", 1.0], ["hat", 1.0]]
	var out := []
	for b in bars:
		out += bar
	return out


# ==================== SÍNTESIS ====================

# Devuelve el stream cacheado; si falta, lo renderiza sync (retomando el job
# incremental si estaba a medias). Es el fallback para SFX/jingles cortos:
# los temas largos entran por la cola incremental y casi nunca pasan por acá.
func _ensure(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var t0 := Time.get_ticks_usec()
	var job: Dictionary
	if not _job.is_empty() and _job.id == id:
		job = _job
		_job = {}
	else:
		job = _make_job(id, _song(id))
	_cola.erase(id)
	while _run_paso(job):
		pass
	_cache[id] = _wav_de_job(job)
	var dt := int(Time.get_ticks_usec() - t0)
	_gen_us += dt
	print("MusicManager: %s renderizado en %d ms" % [id, dt / 1000])
	return _cache[id]


# Prepara el render de un tema: mezcla en float con headroom (se clampea al
# pasar a 16 bits) y una lista de ops (una nota por op) que permite repartir
# el trabajo entre frames. El estado del LFSR de ruido es POR canal, así el
# timbre de la percusión no depende del orden ni del intercalado del render.
func _make_job(id: String, song: Dictionary) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var beat_s: float = 60.0 / song.bpm
	# duración = canal más largo (todos deberían medir lo mismo)
	var beats := 0.0
	for ch in song.channels:
		var b := 0.0
		for ev in ch.notes:
			b += ev[1]
		beats = maxf(beats, b)
	var total := int(round(beats * beat_s * MIX_RATE))
	var mix := PackedFloat32Array()
	mix.resize(total)
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	var ops: Array = []
	for ch in song.channels:
		var vol: float = ch.get("vol", 0.25)
		var wave: String = ch.get("wave", "square")
		var duty: float = ch.get("duty", 0.5)
		var attack: float = ch.get("attack", 0.004)
		var decay: float = ch.get("decay", 0.4)
		var gate: float = ch.get("gate", 1.0)
		var estado := {lfsr = LFSR_SEED}
		var t := 0.0
		for ev in ch.notes:
			var dur: float = ev[1] * beat_s
			var g: float = ev[2] if ev.size() > 2 else gate
			var s0 := int(round(t * MIX_RATE))
			var s1 := mini(int(round((t + dur * g) * MIX_RATE)), total)
			t += dur
			var n = ev[0]
			if n is String and n == "r":
				continue   # silencio
			if wave == "noise":
				ops.append([1, s0, s1, n, vol, estado])
			else:
				ops.append([0, s0, s1, wave == "tri", duty, _freq(n), vol, attack, decay])
	var job := {id = id, mix = mix, bytes = bytes, ops = ops, i = 0, enc = 0,
			loop = song.get("loop", false), us = 0}
	job.us += int(Time.get_ticks_usec() - t0)
	return job


# Un paso de trabajo del render (una nota, o un bloque de encode a 16 bits).
# Devuelve false cuando el job está terminado.
func _run_paso(job: Dictionary) -> bool:
	var t0 := Time.get_ticks_usec()
	if job.i < job.ops.size():
		var op: Array = job.ops[job.i]
		job.i += 1
		if op[0] == 0:
			_render_tone(job.mix, op[1], op[2], op[3], op[4], op[5], op[6], op[7], op[8])
		else:
			_render_perc(job.mix, op[1], op[2], op[3], op[4], op[5])
	elif job.enc < job.mix.size():
		_encode_16(job, 8192)
	else:
		return false
	job.us += int(Time.get_ticks_usec() - t0)
	return true


# Una nota: oscilador por acumulador de fase + envolvente
# (ataque lineal, decay exponencial y fade corto final anti-click).
func _render_tone(mix: PackedFloat32Array, s0: int, s1: int, es_tri: bool, duty: float,
		freq: float, vol: float, attack: float, decay: float) -> void:
	var n := s1 - s0
	if n <= 0:
		return
	var inc := freq / MIX_RATE
	var ph := 0.0
	var atk := maxi(1, int(attack * MIX_RATE))
	var dmul := exp(-1.0 / (decay * MIX_RATE))
	var fade := maxi(1, mini(330, n >> 2))   # release anti-click (~15 ms máx)
	var env := 0.0
	for i in n:
		if i < atk:
			env = float(i) / atk
		else:
			env *= dmul
		var e := env
		if i >= n - fade:
			e *= float(n - i) / fade
		var v := (4.0 * absf(ph - 0.5) - 1.0) if es_tri else (1.0 if ph < duty else -1.0)
		mix[s0 + i] += v * e * vol
		ph += inc
		if ph >= 1.0:
			ph -= 1.0


func _render_perc(mix: PackedFloat32Array, s0: int, s1: int, kind: String, vol: float,
		estado: Dictionary) -> void:
	var n := s1 - s0
	if kind == "kick":
		# golpe grave: triángulo con barrido descendente de tono y decay rápido
		var m := mini(n, int(0.09 * MIX_RATE))
		var ph := 0.0
		var f := 150.0
		var df := (150.0 - 45.0) / maxi(1, m)
		var env := 1.0
		var dmul := exp(-1.0 / (0.035 * MIX_RATE))
		for i in m:
			mix[s0 + i] += (4.0 * absf(ph - 0.5) - 1.0) * env * vol * 1.8
			env *= dmul
			ph += f / MIX_RATE
			if ph >= 1.0:
				ph -= 1.0
			f -= df
	else:
		# hat: ruido LFSR de 15 bits (como el canal de ruido del Game Boy)
		var m := mini(n, int(0.045 * MIX_RATE))
		var lfsr: int = estado.lfsr
		var env := 1.0
		var dmul := exp(-1.0 / (0.014 * MIX_RATE))
		for i in m:
			var bit := (lfsr ^ (lfsr >> 1)) & 1
			lfsr = (lfsr >> 1) | (bit << 14)
			mix[s0 + i] += (1.0 if (lfsr & 1) == 1 else -1.0) * env * vol
			env *= dmul
		estado.lfsr = lfsr


# Pasa un bloque de la mezcla float a PCM 16 bits (también con presupuesto).
func _encode_16(job: Dictionary, cant: int) -> void:
	var mix: PackedFloat32Array = job.mix
	var bytes: PackedByteArray = job.bytes
	var fin: int = mini(job.enc + cant, mix.size())
	for i in range(job.enc, fin):
		bytes.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))
	job.enc = fin


func _wav_de_job(job: Dictionary) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = job.bytes
	if job.loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = job.mix.size()   # loop perfecto: exactamente el largo del tema
	return wav


# ==================== NOTAS ====================

const SEMIS := {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
	"F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


func _midi(n) -> int:
	if n is int:
		return n
	var s: String = n
	var oct := int(s.substr(s.length() - 1))
	return 12 * (oct + 1) + SEMIS[s.substr(0, s.length() - 1)]


func _freq(n) -> float:
	return 440.0 * pow(2.0, (float(_midi(n)) - 69.0) / 12.0)
