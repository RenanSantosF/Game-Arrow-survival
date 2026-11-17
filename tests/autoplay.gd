extends Node
## Robô: abre o jogo e atira sem parar (toques simulados) por SECONDS segundos.
## Rodar: godot --headless --path . res://tests/autoplay.tscn -- --seconds=180
var seconds := 180.0
var _t := 0.0
var _shot_t := 0.0
var _game: Node
var _acc_frames := 0
var _acc_proc := 0.0
var _last_report := 0.0

func _ready() -> void:
	if "--lite" in OS.get_cmdline_user_args():
		GameData.lite_mode = true
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		Engine.max_fps = 30
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.get_slice("=", 1))
	await get_tree().create_timer(2.5).timeout
	_game = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(_game)
	print("[AUTO] partida iniciada")

func _process(delta: float) -> void:
	_t += delta
	if _t >= seconds:
		print("[AUTO] FIM OK t=%.0f nos=%d fps=%d" % [_t, get_tree().get_node_count(), Engine.get_frames_per_second()])
		get_tree().quit()
		return
	if _game == null or not is_instance_valid(_game):
		return
	_shot_t += delta
	if _shot_t > 0.55:
		_shot_t = 0.0
		_shoot()
	_acc_frames += 1
	_acc_proc += Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	if _t - _last_report >= 10.0:
		_last_report = _t
		print("[PERF] t=%.0f fps=%d proc_ms=%.2f draws=%d prims=%d nos=%d" % [_t, Engine.get_frames_per_second(), 1000.0 * _acc_proc / maxf(_acc_frames, 1), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), get_tree().get_node_count()])
		_acc_frames = 0
		_acc_proc = 0.0

func _shoot() -> void:
	var start := Vector2(randf_range(200, 520), randf_range(500, 900))
	var pull := Vector2(randf_range(-260, -60), randf_range(20, 220))
	var t := InputEventScreenTouch.new(); t.index = 0; t.position = start; t.pressed = true
	Input.parse_input_event(t)
	for i in 4:
		var d := InputEventScreenDrag.new(); d.index = 0; d.position = start + pull * (i + 1) / 4.0
		Input.parse_input_event(d)
	var r := InputEventScreenTouch.new(); r.index = 0; r.position = start + pull; r.pressed = false
	Input.parse_input_event(r)
