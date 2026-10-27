extends Node2D
## Menu inicial: título animado, duelo de stickmen ao fundo, botão JOGAR,
## escolha de flechas, melhorias do personagem, recorde e opção de som.
## Nunca mostra anúncio.

const LEFT_SPOT := Vector2(135, 700)
const RIGHT_SPOT := Vector2(585, 640)

var _left: Stickman
var _right: Stickman
var _world: Node2D
var _ui: CanvasLayer
var _duel_timer := 1.6
var _left_turn := true
var _shooter: Stickman = null
var _draw_time := 0.0
var _sound_button: Button
var _coins_label: Label


func _ready() -> void:
	randomize()
	add_child(SkyBackground.new())
	_world = Node2D.new()
	add_child(_world)
	_world.add_child(Fx.new())

	_left = _make_archer(LEFT_SPOT, false, Color(0.12, 0.35, 0.85), Stickman.Accessory.BANDANA, Color(0.98, 0.78, 0.1), Vector2(-400, 0))
	PlayerArcher.apply_rank_look(_left)
	_right = _make_archer(RIGHT_SPOT, true, Color(0.82, 0.12, 0.12), Stickman.Accessory.HAT, Color(0.2, 0.2, 0.22), Vector2(400, 0))
	_build_ui()


func _make_archer(spot: Vector2, left: bool, color: Color, acc: Stickman.Accessory, acc_color: Color, from: Vector2) -> Stickman:
	var p := FloatingPlatform.new()
	_world.add_child(p)
	p.enter(spot, from, 0.3)
	var s := Stickman.new()
	# Os tiros do menu acertam, mas não causam dano.
	s.hit_layer = Arrow.LAYER_ENEMY
	s.max_hp = 1e9
	s.facing_left = left
	s.body_color = color
	s.accessory = acc
	s.accessory_color = acc_color
	p.add_child(s)
	return s


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var logo := TitleLogo.new()
	UiKit.anchor(logo, Control.PRESET_CENTER_TOP, -360, 70, 360, 330)
	root.add_child(logo)

	var rec_text := tr("Recorde: %d   •   Melhor onda: %d") % [GameData.best_score, GameData.best_wave]
	var rec := UiKit.make_label(rec_text, 26, Color(1, 0.92, 0.7), 7)
	UiKit.anchor(rec, Control.PRESET_CENTER_TOP, -340, 340, 340, 380)
	root.add_child(rec)
	_coins_label = UiKit.make_label("", 28, UiKit.GOLD, 7)
	UiKit.anchor(_coins_label, Control.PRESET_CENTER_TOP, -340, 382, 340, 420)
	root.add_child(_coins_label)
	_refresh_coins()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	UiKit.anchor(box, Control.PRESET_CENTER_BOTTOM, -230, -570, 230, -90)
	box.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(box)

	var play := UiKit.make_button("JOGAR", Color(0.95, 0.5, 0.1), 60, Vector2(460, 132))
	play.pressed.connect(_on_play)
	box.add_child(play)

	var arrows := UiKit.make_button("FLECHAS", Color(0.45, 0.3, 0.8), 38, Vector2(460, 96))
	arrows.pressed.connect(_on_arrows)
	box.add_child(arrows)

	var upgrades := UiKit.make_button("MELHORIAS", Color(0.15, 0.6, 0.45), 38, Vector2(460, 96))
	upgrades.pressed.connect(_on_upgrades)
	box.add_child(upgrades)

	# Som e idioma lado a lado.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_sound_button = UiKit.make_button(_sound_text(), Color(0.22, 0.45, 0.75), 24, Vector2(224, 80))
	_sound_button.pressed.connect(func() -> void:
		GameData.set_sound(not GameData.sound_enabled)
		_sound_button.text = _sound_text())
	row.add_child(_sound_button)
	var lang := UiKit.make_button(tr("IDIOMA: %s") % Lang.LANGUAGE_NAMES[Lang.current()], Color(0.22, 0.45, 0.75), 24, Vector2(224, 80))
	lang.pressed.connect(func() -> void:
		Lang.cycle()
		# Recarrega o menu para todos os textos mudarem de idioma.
		get_tree().reload_current_scene())
	row.add_child(lang)

	var hint := UiKit.make_label("Puxe o dedo para trás e solte para atirar.\nAcerte as frutas: vermelha = vida, amarela = estamina.", 20, Color(1, 1, 1, 0.9), 5)
	UiKit.anchor(hint, Control.PRESET_BOTTOM_WIDE, 0, -80, 0, -20)
	root.add_child(hint)

	# Entrada animada dos botões e pulsação do JOGAR.
	await get_tree().process_frame
	var delay := 0.9
	for b in [play, arrows, upgrades, _sound_button, lang]:
		UiKit.pop_in(b, delay)
		delay += 0.12
	var pulse := play.create_tween().set_loops()
	pulse.tween_interval(1.5)
	pulse.tween_property(play, "scale", Vector2(1.07, 1.07), 0.35).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)


func _sound_text() -> String:
	return "SOM: LIGADO" if GameData.sound_enabled else "SOM: DESLIGADO"


func _on_play() -> void:
	Sfx.play("unlock", -6.0)
	UiKit.fade_to_scene(self, "res://scenes/game.tscn")


func _refresh_coins() -> void:
	_coins_label.text = tr("Moedas: %d") % GameData.coins


func _on_upgrades() -> void:
	_open_arsenal(Arsenal.Tab.HERO)


func _on_arrows() -> void:
	_open_arsenal(Arsenal.Tab.ARROWS)


func _open_arsenal(tab: Arsenal.Tab) -> void:
	var arsenal := Arsenal.new()
	arsenal.start_tab = tab
	arsenal.closed.connect(func() -> void:
		_refresh_coins()
		PlayerArcher.apply_rank_look(_left))
	_ui.add_child(arsenal)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


## Duelo decorativo: os dois arqueiros trocam tiros (sem dano), usando a
## flecha escolhida pelo jogador.
func _process(delta: float) -> void:
	if _shooter == null:
		_duel_timer -= delta
		if _duel_timer <= 0.0:
			_shooter = _left if _left_turn else _right
			_left_turn = not _left_turn
			_shooter.is_aiming = true
			_draw_time = 0.0
		return
	var other := _right if _shooter == _left else _left
	var start := _shooter.get_arrow_spawn_global()
	var target := other.get_chest_global() + Vector2(randf_range(-6, 6), 0)
	var t := 0.75
	var velocity := (target - start) / t - Vector2(0, 0.5 * Arrow.GRAVITY * t)
	_draw_time += delta
	_shooter.aim_angle = lerp_angle(_shooter.aim_angle, velocity.angle(), minf(delta * 8.0, 1.0))
	_shooter.draw_power = clampf(_draw_time / 0.7, 0.0, 1.0)
	if _draw_time >= 0.8:
		var arrow := Arrow.new()
		_world.add_child(arrow)
		arrow.launch(_shooter.get_arrow_spawn_global(), velocity, GameData.get_arrow(GameData.selected_arrow), 0.0, true)
		arrow.collision_mask = Arrow.LAYER_ENEMY
		Sfx.play("shoot", -10.0)
		_shooter.is_aiming = false
		_shooter.draw_power = 0.0
		_shooter.play_shot_recoil()
		_shooter = null
		_duel_timer = randf_range(1.2, 2.0)
