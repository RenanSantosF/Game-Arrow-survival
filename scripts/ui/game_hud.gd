class_name GameHud
extends CanvasLayer
## Interface durante a partida: vida, estamina, pontuação, moedas, onda e era,
## barra de vida do chefe, botão de pausa, seletor de flechas e avisos animados.

signal pause_pressed

var hp_bar: StatBar
var stamina_bar: StatBar

var _root: Control
var _score_label: Label
var _kills_label: Label
var _best_label: Label
var _next_label: Label
var _pause_button: Button
var _arrow_bar: PanelContainer
var _arrow_box: HBoxContainer
var _coins_label: Label
var _wave_label: Label
var _era_label: Label
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: BossBar
var _kills := 0
var _wave_left := 0
var _wave_total := 0
var _arrow_buttons := {}
var _banner: PanelContainer
var _banner_label: Label
var _vignette: ColorRect
var _blockers: Array[Control] = []
var _shown_score := 0.0
var _target_score := 0


## Barra de vida do chefe (vermelha) com a resistência do escudo (azul) por cima.
class BossBar:
	extends Control
	var ratio := 1.0
	var shown := 1.0
	var shield := 0.0

	func _process(delta: float) -> void:
		shown = move_toward(shown, ratio, delta * 0.8)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r.grow(3.0), Color(0.05, 0.05, 0.1, 0.85))
		draw_rect(Rect2(r.position, Vector2(size.x * shown, size.y)), Color(1, 0.85, 0.6))
		draw_rect(Rect2(r.position, Vector2(size.x * ratio, size.y)), Color(0.85, 0.12, 0.15))
		if shield > 0.0:
			draw_rect(Rect2(r.position + Vector2(0, size.y - 7), Vector2(size.x * shield, 7)), Color(0.45, 0.75, 1.0))


func _ready() -> void:
	layer = 10
	# Clarão de dano e sombra do topo cobrem a tela inteira (inclusive o notch).
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(0.8, 0, 0, 0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)
	add_child(_make_top_shade())

	# O resto do HUD fica dentro da área segura, longe do notch e da câmera.
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.fit_safe_area(_root)
	add_child(_root)

	var bars := VBoxContainer.new()
	bars.position = Vector2(18, 22)
	bars.add_theme_constant_override("separation", 6)
	_root.add_child(bars)
	hp_bar = StatBar.new(Color(0.92, 0.2, 0.25), StatBar.Icon.HEART)
	hp_bar.custom_minimum_size = Vector2(250, 40)
	stamina_bar = StatBar.new(Color(1.0, 0.8, 0.15), StatBar.Icon.BOLT)
	stamina_bar.custom_minimum_size = Vector2(250, 34)
	bars.add_child(hp_bar)
	bars.add_child(stamina_bar)

	_coins_label = UiKit.make_label("0", 26, UiKit.GOLD, 6)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiKit.anchor(_coins_label, Control.PRESET_TOP_LEFT, 22, 108, 260, 140)
	_root.add_child(_coins_label)

	_wave_label = UiKit.make_label("", 36, Color.WHITE, 8)
	UiKit.anchor(_wave_label, Control.PRESET_TOP_LEFT, 278, 16, 606, 60)
	_root.add_child(_wave_label)
	_era_label = UiKit.make_label("", 20, Color(0.75, 0.9, 1.0), 5)
	UiKit.anchor(_era_label, Control.PRESET_TOP_LEFT, 278, 58, 606, 86)
	_root.add_child(_era_label)

	_score_label = UiKit.make_label("0", 64, Color.WHITE, 12)
	UiKit.anchor(_score_label, Control.PRESET_CENTER_TOP, -120, 104, 120, 184)
	_score_label.pivot_offset = Vector2(120, 40)
	_root.add_child(_score_label)

	_kills_label = UiKit.make_label(tr("Abates seguidos: 0"), 24, Color(1, 0.9, 0.7), 6)
	UiKit.anchor(_kills_label, Control.PRESET_CENTER_TOP, -200, 180, 200, 214)
	_root.add_child(_kills_label)

	_best_label = UiKit.make_label(tr("Recorde: %d") % GameData.best_score, 22, Color(1, 1, 1, 0.85), 6)
	UiKit.anchor(_best_label, Control.PRESET_TOP_RIGHT, -330, 112, -20, 142)
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_best_label)

	_pause_button = UiKit.make_button("II", Color(0.2, 0.25, 0.4), 38, Vector2(84, 84))
	UiKit.anchor(_pause_button, Control.PRESET_TOP_RIGHT, -104, 18, -20, 102)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_root.add_child(_pause_button)
	_blockers.append(_pause_button)

	_arrow_bar = UiKit.make_panel(Color(0.08, 0.1, 0.18, 0.8))
	UiKit.anchor(_arrow_bar, Control.PRESET_CENTER_BOTTOM, 0, -24, 0, -24)
	_arrow_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_arrow_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_root.add_child(_arrow_bar)
	# No máximo 5 flechas equipadas: cabem todas, sem rolagem.
	_arrow_box = HBoxContainer.new()
	_arrow_box.add_theme_constant_override("separation", 8)
	_arrow_bar.add_child(_arrow_box)
	_blockers.append(_arrow_bar)

	_next_label = UiKit.make_label("", 22, Color(1, 1, 1, 0.9), 6)
	UiKit.anchor(_next_label, Control.PRESET_BOTTOM_WIDE, 0, -196, 0, -164)
	_root.add_child(_next_label)

	_boss_box = VBoxContainer.new()
	_boss_box.add_theme_constant_override("separation", 4)
	UiKit.anchor(_boss_box, Control.PRESET_CENTER_TOP, -230, 220, 230, 290)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	_root.add_child(_boss_box)
	_boss_name = UiKit.make_label("", 26, Color(1, 0.55, 0.45), 7)
	_boss_box.add_child(_boss_name)
	_boss_bar = BossBar.new()
	_boss_bar.custom_minimum_size = Vector2(460, 22)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_child(_boss_bar)

	_banner = UiKit.make_panel(Color(0.35, 0.2, 0.05, 0.92))
	UiKit.anchor(_banner, Control.PRESET_CENTER_TOP, 0, 310, 0, 310)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label = UiKit.make_label("", 30, UiKit.GOLD, 8)
	_banner.add_child(_banner_label)
	_root.add_child(_banner)

	rebuild_arrow_bar()


## Faixa escura em degradê no topo para os textos se destacarem do céu.
func _make_top_shade() -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.45))
	grad.set_color(1, Color(0, 0, 0, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	var shade := TextureRect.new()
	shade.texture = tex
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := 170.0 + UiKit.safe_insets(get_viewport()).position.y
	UiKit.anchor(shade, Control.PRESET_TOP_WIDE, 0, 0, 0, h)
	return shade


## Diz se um ponto da tela está sobre um botão (o jogador não mira ali).
func blocks_point(p: Vector2) -> bool:
	for c in _blockers:
		if c.visible and c.get_global_rect().has_point(p):
			return true
	return false


func rebuild_arrow_bar() -> void:
	for child in _arrow_box.get_children():
		child.queue_free()
	_arrow_buttons.clear()
	# Só as flechas equipadas (espaços de flecha) vão para a partida.
	for id: String in GameData.loadout:
		var def := GameData.get_arrow(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(84, 100)
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		var icon := ArrowIcon.new(id)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_bottom = -18
		b.add_child(icon)
		var cost := UiKit.make_label(str(int(round(GameData.arrow_stamina(def)))), 18, Color(1, 0.85, 0.3), 5)
		cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		cost.offset_top = -24
		b.add_child(cost)
		b.pressed.connect(func() -> void:
			GameData.select_arrow(id)
			Sfx.play("click")
			_refresh_arrow_selection())
		_arrow_box.add_child(b)
		_arrow_buttons[id] = icon
	_arrow_bar.visible = _arrow_buttons.size() > 1
	_refresh_arrow_selection()


func _refresh_arrow_selection() -> void:
	for id in _arrow_buttons:
		(_arrow_buttons[id] as ArrowIcon).selected = id == GameData.selected_arrow


func set_score(score: int, kills: int) -> void:
	if score != _target_score:
		var tw := _score_label.create_tween()
		tw.tween_property(_score_label, "scale", Vector2(1.35, 1.35), 0.08)
		tw.tween_property(_score_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_target_score = score
	_kills = kills
	_refresh_kills_label()
	if score > GameData.best_score and GameData.best_score > 0:
		_best_label.text = tr("NOVO RECORDE!")
		_best_label.add_theme_color_override("font_color", UiKit.GOLD)
	var next := _next_unlock(kills)
	if next.is_empty():
		_next_label.text = ""
	else:
		_next_label.text = tr("Próxima flecha: %s em %d abates") % [tr(next["name"]), int(next["unlock"]) - kills]


func _refresh_kills_label() -> void:
	if _wave_left > 0:
		_kills_label.text = tr("Abates: %d   •   Restam: %d") % [_kills, _wave_left]
	else:
		_kills_label.text = tr("Abates seguidos: %d") % _kills


func set_coins(run_coins: int) -> void:
	_coins_label.text = tr("Moedas: +%d") % run_coins


func set_wave(wave: int, era_name: String, left: int, total: int) -> void:
	_wave_label.text = tr("ONDA %d") % wave if wave > 0 else ""
	_era_label.text = era_name if wave > 0 else ""
	_wave_left = left
	_wave_total = total
	_refresh_kills_label()


func show_boss(boss_name: String) -> void:
	_boss_name.text = boss_name
	_boss_bar.ratio = 1.0
	_boss_bar.shown = 1.0
	_boss_box.visible = true
	_boss_box.modulate.a = 0.0
	_boss_box.create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.5)


func set_boss_hp(ratio: float, shield_ratio: float) -> void:
	_boss_bar.ratio = clampf(ratio, 0.0, 1.0)
	_boss_bar.shield = clampf(shield_ratio, 0.0, 1.0)


func hide_boss() -> void:
	_boss_bar.ratio = 0.0
	var tw := _boss_box.create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(_boss_box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: _boss_box.visible = false)


func _next_unlock(kills: int) -> Dictionary:
	for def in GameData.ARROWS:
		if not GameData.is_unlocked(def["id"]) and def["unlock"] > kills:
			return def
	return {}


func flash_damage() -> void:
	_vignette.color.a = 0.32
	var tw := _vignette.create_tween()
	tw.tween_property(_vignette, "color:a", 0.0, 0.4)


func show_banner(text: String, color := UiKit.GOLD, duration := 2.2) -> void:
	_banner_label.text = text
	_banner_label.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner.offset_left = 0
	_banner.offset_right = 0
	_banner.reset_size()
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2(0.2, 0.2)
	_banner.modulate.a = 1.0
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: _banner.visible = false)


func set_controls_visible(v: bool) -> void:
	_pause_button.visible = v
	_arrow_bar.visible = v and _arrow_buttons.size() > 1


func _process(delta: float) -> void:
	_shown_score = move_toward(_shown_score, _target_score, maxf(delta * 120.0, absf(_target_score - _shown_score) * delta * 8.0))
	_score_label.text = str(int(round(_shown_score)))
