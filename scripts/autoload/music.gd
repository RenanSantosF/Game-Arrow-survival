extends Node
## Música de fundo gerada por código (sem arquivos de áudio), no mesmo estilo dos
## efeitos sonoros. Uma trilha de ação em lá menor, 8 compassos em loop:
## baixo, arpejo, melodia simples e bateria leve.
##
## A trilha é sintetizada numa thread separada ao abrir o jogo (leva ~1 s) e
## começa com fade. No menu toca mais baixa; na partida, um pouco mais alta.
## O botão SOM do jogo silencia tudo (música e efeitos).

const MIX_RATE := 22050
const BPM := 112.0
const BARS := 8
## Acordes (um a cada compasso): Am, F, C, G, Am, F, G, E.
const CHORDS := [
	[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62],
	[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59],
]
## Melodia: [colcheia em que começa, nota MIDI, duração em colcheias]; -1 = pausa.
const MELODY := [
	[0, 76, 3], [3, 74, 1], [4, 72, 2], [6, 71, 2],
	[8, 72, 3], [11, 74, 1], [12, 76, 4],
	[16, 79, 3], [19, 76, 1], [20, 74, 2], [22, 72, 2],
	[24, 71, 4], [28, 74, 4],
	[32, 76, 3], [35, 74, 1], [36, 72, 2], [38, 71, 2],
	[40, 72, 3], [43, 74, 1], [44, 76, 4],
	[48, 74, 2], [50, 76, 2], [52, 79, 4],
	[56, 76, 4], [60, 68, 4],
]
const MENU_DB := -17.0
const GAME_DB := -12.0

var _player: AudioStreamPlayer
var _target_db := MENU_DB
var _thread: Thread


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.volume_db = -60.0
	add_child(_player)
	_thread = Thread.new()
	_thread.start(_build)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## Volume da música para cada tela.
func set_mode(in_game: bool) -> void:
	_target_db = GAME_DB if in_game else MENU_DB


func _process(delta: float) -> void:
	if _player.playing:
		_player.volume_db = move_toward(_player.volume_db, _target_db, delta * 20.0)


func _build() -> void:
	var stream := _synthesize()
	call_deferred("_start", stream)


func _start(stream: AudioStreamWAV) -> void:
	_thread.wait_to_finish()
	_player.stream = stream
	_player.play()


static func _freq(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


func _synthesize() -> AudioStreamWAV:
	var eighth := 60.0 / BPM / 2.0
	var bar := eighth * 8.0
	var total := int(bar * BARS * MIX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Baixo: colcheias na fundamental (uma oitava abaixo), onda quadrada suave.
	for b in BARS:
		var root: float = CHORDS[b][0] - 24
		for e in 8:
			var note := root + (12.0 if e % 4 == 3 else 0.0)
			_note(buf, (b * 8 + e) * eighth, eighth * 0.9, _freq(note), 0.16, 1)
	# Arpejo: semicolcheias subindo pelos tons do acorde, onda triangular.
	for b in BARS:
		var chord: Array = CHORDS[b]
		for s in 16:
			var note: float = chord[[0, 1, 2, 1][s % 4]] + 12.0 * float(s / 8)
			_note(buf, b * bar + s * eighth / 2.0, eighth * 0.45, _freq(note), 0.07, 2)
	# Melodia: onda quadrada com vibrato leve.
	for m in MELODY:
		if m[1] > 0:
			_note(buf, m[0] * eighth, m[2] * eighth * 0.95, _freq(m[1]), 0.09, 3)
	# Bateria: bumbo nos tempos 1 e 3, caixa nos 2 e 4, chimbal nas colcheias.
	for b in BARS:
		for e in 8:
			var t := b * bar + e * eighth
			if e == 0 or e == 4 or (e == 6 and b % 2 == 1):
				_kick(buf, t)
			if e == 2 or e == 6:
				_noise(buf, t, 0.12, 0.13, 18.0, rng)
			_noise(buf, t, 0.03, 0.035, 70.0, rng)

	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total
	return stream


## Soma uma nota ao buffer. wave: 1 = quadrada, 2 = triangular, 3 = quadrada com vibrato.
func _note(buf: PackedFloat32Array, start: float, length: float, freq: float, vol: float, wave: int) -> void:
	var i0 := int(start * MIX_RATE)
	var n := int(length * MIX_RATE)
	var phase := 0.0
	for k in n:
		var i := i0 + k
		if i >= buf.size():
			return
		var t := float(k) / MIX_RATE
		var env := minf(t * 200.0, 1.0) * minf(float(n - k) / 300.0, 1.0) * exp(-t * 2.5)
		var f := freq
		if wave == 3:
			f *= 1.0 + 0.004 * sin(t * 30.0)
		phase = fmod(phase + f / MIX_RATE, 1.0)
		var s: float
		match wave:
			2:
				s = 4.0 * absf(phase - 0.5) - 1.0
			_:
				s = (1.0 if phase < 0.5 else -1.0) * 0.6 + sin(phase * TAU) * 0.4
		buf[i] += s * env * vol


func _kick(buf: PackedFloat32Array, start: float) -> void:
	var i0 := int(start * MIX_RATE)
	var n := int(0.18 * MIX_RATE)
	var phase := 0.0
	for k in n:
		var i := i0 + k
		if i >= buf.size():
			return
		var t := float(k) / MIX_RATE
		phase += (50.0 + 110.0 * exp(-t * 35.0)) / MIX_RATE
		buf[i] += sin(phase * TAU) * exp(-t * 18.0) * 0.32


func _noise(buf: PackedFloat32Array, start: float, length: float, vol: float, decay: float, rng: RandomNumberGenerator) -> void:
	var i0 := int(start * MIX_RATE)
	var n := int(length * MIX_RATE)
	for k in n:
		var i := i0 + k
		if i >= buf.size():
			return
		var t := float(k) / MIX_RATE
		buf[i] += rng.randf_range(-1.0, 1.0) * exp(-t * decay) * vol
