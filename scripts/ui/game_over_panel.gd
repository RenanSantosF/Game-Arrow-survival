class_name GameOverPanel
extends Control
## Tela de derrota: pontuação (contando animada), recorde, estatísticas e botões.

signal revive_pressed
signal retry_pressed
signal menu_pressed

var score := 0
var kills := 0
var headshots := 0
var seconds := 0.0
var is_record := false
var can_revive := false
var new_arrows: Array = []

var _score_label: Label
var _shown := 0.0
var _counting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := UiKit.make_dim(0.0)
	add_child(dim)
	dim.create_tween().tween_property(dim, "color:a", 0.6, 0.4)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.make_panel()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := UiKit.make_label("VOCÊ CAIU!", 62, Color(1, 0.4, 0.35), 12)
	box.add_child(title)
	box.add_child(UiKit.make_label("PONTUAÇÃO", 26, Color(1, 1, 1, 0.8), 6))
	_score_label = UiKit.make_label("0", 86, Color.WHITE, 14)
	box.add_child(_score_label)

	if is_record:
		var rec := UiKit.make_label("NOVO RECORDE!", 40, UiKit.GOLD, 10)
		box.add_child(rec)
		rec.resized.connect(func() -> void: rec.pivot_offset = rec.size / 2.0)
		var rec_tw := rec.create_tween().set_loops()
		rec_tw.tween_property(rec, "scale", Vector2(1.12, 1.12), 0.45).set_trans(Tween.TRANS_SINE)
		rec_tw.tween_property(rec, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
	else:
		box.add_child(UiKit.make_label("Recorde: %d" % GameData.best_score, 32, UiKit.GOLD, 8))

	var stats := "Abates seguidos: %d   •   Na cabeça: %d\nTempo: %d:%02d" % [kills, headshots, int(seconds) / 60, int(seconds) % 60]
	box.add_child(UiKit.make_label(stats, 24, Color(0.85, 0.9, 1.0), 6))
	for def in new_arrows:
		box.add_child(UiKit.make_label("Flecha desbloqueada: %s!" % def["name"], 26, Color(0.6, 1, 0.5), 6))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)

	if can_revive:
		var revive := UiKit.make_button("CONTINUAR (ver anúncio)", Color(0.55, 0.3, 0.85), 30, Vector2(460, 92))
		revive.pressed.connect(func() -> void: revive_pressed.emit())
		box.add_child(revive)
	var retry := UiKit.make_button("JOGAR DE NOVO", Color(0.2, 0.7, 0.3), 40, Vector2(460, 100))
	retry.pressed.connect(func() -> void: retry_pressed.emit())
	box.add_child(retry)
	var menu := UiKit.make_button("MENU", Color(0.25, 0.4, 0.75), 34, Vector2(460, 84))
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	box.add_child(menu)

	panel.modulate.a = 0.0
	await get_tree().process_frame
	UiKit.pop_in(panel)
	var tw := panel.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void: _counting = true)


func _process(delta: float) -> void:
	if not _counting:
		return
	var before := int(_shown)
	_shown = move_toward(_shown, score, maxf(score * delta * 1.2, delta * 40.0))
	_score_label.text = str(int(_shown))
	if int(_shown) != before and int(_shown) % 5 == 0:
		Sfx.play("click", -14.0, 0.0)
	if int(_shown) == score:
		_counting = false
		if is_record:
			Sfx.play("record")
