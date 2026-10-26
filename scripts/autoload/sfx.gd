extends Node
## Efeitos sonoros gerados por código (sintetizados), sem arquivos de áudio.
## Uso: Sfx.play("shoot")

const MIX_RATE := 22050
const VOICES := 10

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build_sounds()


func play(sound: String, volume_db := 0.0, pitch_variation := 0.08) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()


func _build_sounds() -> void:
	_streams["shoot"] = _make(0.22, func(t: float, _i: int) -> float:
		var env := exp(-t * 18.0)
		var twang := sin(TAU * (190.0 + 60.0 * exp(-t * 30.0)) * t) * env
		var click := randf_range(-1, 1) * exp(-t * 120.0) * 0.6
		return twang * 0.7 + click)
	_streams["draw"] = _make(0.25, func(t: float, _i: int) -> float:
		var env := minf(t * 8.0, 1.0) * exp(-t * 6.0)
		return randf_range(-1, 1) * env * 0.12 + sin(TAU * 90.0 * t) * env * 0.1)
	_streams["hit"] = _make(0.16, func(t: float, _i: int) -> float:
		var env := exp(-t * 28.0)
		return (randf_range(-1, 1) * 0.5 + sin(TAU * 95.0 * t)) * env * 0.8)
	_streams["headshot"] = _make(0.3, func(t: float, _i: int) -> float:
		var env := exp(-t * 14.0)
		var crack := randf_range(-1, 1) * exp(-t * 60.0)
		var ping := sin(TAU * 1250.0 * t) * env * 0.35
		return crack * 0.7 + ping + sin(TAU * 80.0 * t) * env * 0.5)
	_streams["wood"] = _make(0.1, func(t: float, _i: int) -> float:
		var env := exp(-t * 55.0)
		return (sin(TAU * 420.0 * t) * 0.6 + randf_range(-1, 1) * 0.4) * env * 0.6)
	_streams["fruit"] = _make(0.35, func(t: float, _i: int) -> float:
		var squish := randf_range(-1, 1) * exp(-t * 35.0) * 0.5
		var f := 660.0 if t < 0.12 else 990.0
		var chime := sin(TAU * f * t) * exp(-fmod(t, 0.12) * 10.0) * 0.4
		return squish + chime)
	_streams["hurt"] = _make(0.22, func(t: float, _i: int) -> float:
		var env := exp(-t * 10.0)
		var f := 150.0 - t * 200.0
		return signf(sin(TAU * f * t)) * env * 0.35 + randf_range(-1, 1) * exp(-t * 40.0) * 0.4)
	_streams["death"] = _make(0.7, func(t: float, _i: int) -> float:
		var f := 700.0 * exp(-t * 2.2) + 120.0
		return sin(TAU * f * t) * (1.0 - t / 0.7) * 0.35)
	_streams["explosion"] = _make(0.7, func(t: float, i: int) -> float:
		var env := exp(-t * 5.0)
		var rumble := sin(TAU * 55.0 * t) * env
		var noise := randf_range(-1, 1) * env
		# Ruído "abafado": média com a amostra anterior simulada pelo índice.
		return (noise * 0.7 + rumble * 0.6) * (0.8 + 0.2 * sin(i * 0.05)))
	_streams["freeze"] = _make(0.45, func(t: float, _i: int) -> float:
		var env := exp(-t * 6.0)
		return (sin(TAU * 1800.0 * t) + sin(TAU * 2400.0 * t) * 0.6) * env * 0.18 + randf_range(-1, 1) * env * 0.1)
	_streams["bone"] = _make(0.2, func(t: float, _i: int) -> float:
		var crack := randf_range(-1, 1) * exp(-t * 70.0)
		var snap := randf_range(-1, 1) * exp(-maxf(t - 0.04, 0.0) * 90.0) * (1.0 if t > 0.04 else 0.0)
		return (crack * 0.8 + snap * 0.6 + sin(TAU * 140.0 * t) * exp(-t * 25.0) * 0.4))
	_streams["zap"] = _make(0.3, func(t: float, _i: int) -> float:
		var env := exp(-t * 9.0)
		var buzz := signf(sin(TAU * 140.0 * t)) * 0.3 + randf_range(-1, 1) * 0.5
		return buzz * env * (0.6 + 0.4 * signf(sin(TAU * 31.0 * t))))
	_streams["shield"] = _make(0.18, func(t: float, _i: int) -> float:
		var env := exp(-t * 22.0)
		return (sin(TAU * 820.0 * t) * 0.5 + sin(TAU * 1310.0 * t) * 0.3 + randf_range(-1, 1) * 0.3) * env)
	_streams["shield_break"] = _make(0.5, func(t: float, _i: int) -> float:
		var env := exp(-t * 7.0)
		return (randf_range(-1, 1) * 0.6 + sin(TAU * 600.0 * t * (1.0 - t)) * 0.4) * env)
	_streams["boss"] = _make(1.4, func(t: float, _i: int) -> float:
		var env := minf(t * 6.0, 1.0) * exp(-t * 1.6)
		var f := 70.0 + 10.0 * sin(t * 9.0)
		return (sin(TAU * f * t) + signf(sin(TAU * f * 1.5 * t)) * 0.25) * env * 0.55)
	_streams["wave"] = _make(0.7, func(t: float, _i: int) -> float:
		var notes := [392.0, 523.0, 659.0]
		var idx := mini(int(t / 0.14), 2)
		var lt := t - idx * 0.14
		return (sin(TAU * notes[idx] * t) + sin(TAU * notes[idx] * 2.0 * t) * 0.2) * exp(-lt * 5.0) * 0.3)
	_streams["fire"] = _make(0.4, func(t: float, _i: int) -> float:
		var env := minf(t * 10.0, 1.0) * exp(-t * 5.0)
		return randf_range(-1, 1) * env * 0.4)
	_streams["unlock"] = _make(0.8, func(t: float, _i: int) -> float:
		var notes := [523.25, 659.25, 783.99, 1046.5]
		var idx := mini(int(t / 0.14), 3)
		var lt := t - idx * 0.14
		return sin(TAU * notes[idx] * t) * exp(-lt * 6.0) * 0.35)
	_streams["click"] = _make(0.07, func(t: float, _i: int) -> float:
		return sin(TAU * 880.0 * t) * exp(-t * 60.0) * 0.4)
	_streams["spawn"] = _make(0.35, func(t: float, _i: int) -> float:
		var f := 200.0 + t * 900.0
		return sin(TAU * f * t) * (1.0 - t / 0.35) * 0.18)
	_streams["gameover"] = _make(1.2, func(t: float, _i: int) -> float:
		var notes := [392.0, 349.23, 311.13, 261.63]
		var idx := mini(int(t / 0.28), 3)
		var lt := t - idx * 0.28
		return (sin(TAU * notes[idx] * t) + 0.3 * sin(TAU * notes[idx] * 2.0 * t)) * exp(-lt * 3.5) * 0.3)
	_streams["record"] = _make(1.0, func(t: float, _i: int) -> float:
		var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
		var idx := mini(int(t / 0.12), 4)
		var lt := t - idx * 0.12
		return sin(TAU * notes[idx] * t) * exp(-lt * 4.0) * 0.3)


## Cria um som a partir de uma função f(tempo, índice) -> amostra entre -1 e 1.
func _make(duration: float, generator: Callable) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / MIX_RATE
		var s := clampf(generator.call(t, i), -1.0, 1.0)
		# Suaviza o fim para não dar estalo.
		var fade := minf(1.0, float(count - i) / 200.0)
		data.encode_s16(i * 2, int(s * fade * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
