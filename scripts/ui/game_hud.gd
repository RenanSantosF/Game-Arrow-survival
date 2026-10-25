class_name GameHud
extends CanvasLayer
## Interface durante a partida: vida, estamina, pontuação, botão de pausa,
## seletor de flechas e avisos animados (desbloqueios, combos).

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
var _arrow_buttons := {}
var _banner: PanelContainer
var _banner_label: Label
var _vignette: ColorRect
var _blockers: Array[Control] = []
var _shown_score := 0.0
var _target_score := 0


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(0.8, 0, 0, 0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vignette)

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

	_score_label = UiKit.make_label("0", 64, Color.WHITE, 12)
	UiKit.anchor(_score_label, Control.PRESET_CENTER_TOP, -120, 104, 120, 184)
	_score_label.pivot_offset = Vector2(120, 40)
	_root.add_child(_score_label)

	_kills_label = UiKit.make_label("Abates seguidos: 0", 24, Color(1, 0.9, 0.7), 6)
	UiKit.anchor(_kills_label, Control.PRESET_CENTER_TOP, -200, 180, 200, 214)
	_root.add_child(_kills_label)

	_best_label = UiKit.make_label("Recorde: %d" % GameData.best_score, 22, Color(1, 1, 1, 0.85), 6)
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
	_arrow_box = HBoxContainer.new()
	_arrow_box.add_theme_constant_override("separation", 10)
	_arrow_bar.add_child(_arrow_box)
	_blockers.append(_arrow_bar)

	_next_label = UiKit.make_label("", 22, Color(1, 1, 1, 0.9), 6)
	UiKit.anchor(_next_label, Control.PRESET_BOTTOM_WIDE, 0, -196, 0, -164)
	_root.add_child(_next_label)

	_banner = UiKit.make_panel(Color(0.35, 0.2, 0.05, 0.92))
	UiKit.anchor(_banner, Control.PRESET_CENTER_TOP, 0, 250, 0, 250)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label = UiKit.make_label("", 30, UiKit.GOLD, 8)
	_banner.add_child(_banner_label)
	_root.add_child(_banner)

	rebuild_arrow_bar()


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
	for def in GameData.ARROWS:
		if not GameData.is_unlocked(def["id"]):
			continue
		var id: String = def["id"]
		var b := Button.new()
		b.custom_minimum_size = Vector2(92, 104)
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		var icon := ArrowIcon.new(id)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_bottom = -18
		b.add_child(icon)
		var cost := UiKit.make_label(str(int(def["stamina"])), 18, Color(1, 0.85, 0.3), 5)
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
	_kills_label.text = "Abates seguidos: %d" % kills
	if score > GameData.best_score and GameData.best_score > 0:
		_best_label.text = "NOVO RECORDE!"
		_best_label.add_theme_color_override("font_color", UiKit.GOLD)
	var next := _next_unlock(kills)
	if next.is_empty():
		_next_label.text = ""
	else:
		_next_label.text = "Próxima flecha: %s em %d abates" % [next["name"], int(next["unlock"]) - kills]


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
