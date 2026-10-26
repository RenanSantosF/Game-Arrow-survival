class_name ArrowSelectPanel
extends Control
## Tela de flechas: escolher, MELHORAR (com moedas) e comprar as bloqueadas.
## Flechas bloqueadas também podem ser liberadas com abates seguidos (sem morrer).
## Cada nível de melhoria dá +12% de dano, -6% de estamina e +15% de efeito.

signal closed

var _cards := {}
var _coins_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.make_dim(0.65))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.make_panel()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(UiKit.make_label("FLECHAS", 44, UiKit.GOLD, 10))
	_coins_label = UiKit.make_label("", 30, UiKit.GOLD, 7)
	box.add_child(_coins_label)
	box.add_child(UiKit.make_label("Toque numa flecha para equipar. Melhore com moedas:\n+12% dano, -6% estamina e efeito mais forte por nível.", 18, Color(0.85, 0.9, 1), 5))

	# Com muitas flechas a grade rola para cima e para baixo.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 820)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 14
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for def in GameData.ARROWS:
		grid.add_child(_make_card(def))

	var done := UiKit.make_button("PRONTO", Color(0.2, 0.7, 0.3), 36, Vector2(360, 80))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	box.add_child(done)
	_refresh()
	await get_tree().process_frame
	UiKit.pop_in(panel)


func _make_card(def: Dictionary) -> Button:
	var id: String = def["id"]
	var b := Button.new()
	b.custom_minimum_size = Vector2(198, 262)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiKit.make_style(Color(0.16, 0.2, 0.32), 20, 3, Color(1, 1, 1, 0.2)))
	b.add_theme_stylebox_override("hover", UiKit.make_style(Color(0.2, 0.24, 0.38), 20, 3, Color(1, 1, 1, 0.3)))
	b.add_theme_stylebox_override("pressed", UiKit.make_style(Color(0.12, 0.15, 0.25), 20, 3, Color(1, 1, 1, 0.3)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8
	v.offset_bottom = -8
	v.offset_left = 6
	v.offset_right = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)

	var icon := ArrowIcon.new(id)
	icon.custom_minimum_size = Vector2(66, 66)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var title := UiKit.make_label(def["name"], 23, Color.WHITE, 6)
	v.add_child(title)
	var desc := UiKit.make_label("", 14, Color(0.8, 0.85, 0.95), 4)
	v.add_child(desc)
	var status := UiKit.make_label("", 15, UiKit.GOLD, 5)
	v.add_child(status)

	# Botão de melhorar/comprar dentro do cartão (recebe o toque antes do cartão).
	var action := UiKit.make_button("", Color(0.95, 0.55, 0.12), 17, Vector2(176, 44))
	action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action.mouse_filter = Control.MOUSE_FILTER_STOP
	action.pressed.connect(func() -> void:
		var ok := GameData.buy_arrow_upgrade(id) if GameData.is_unlocked(id) else GameData.buy_arrow(id)
		if ok:
			Sfx.play("unlock", -6.0)
			_pulse(b)
			if GameData.arrow_level(id) == 0:
				GameData.select_arrow(id)
			_refresh()
		else:
			Sfx.play("hurt", -10.0))
	v.add_child(action)

	b.pressed.connect(func() -> void:
		if GameData.is_unlocked(id):
			GameData.select_arrow(id)
			Sfx.play("unlock", -8.0)
			_refresh()
		else:
			Sfx.play("hurt", -10.0)
			var tw := b.create_tween()
			tw.tween_property(b, "rotation", 0.05, 0.05)
			tw.tween_property(b, "rotation", -0.05, 0.08)
			tw.tween_property(b, "rotation", 0.0, 0.05))
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	_cards[id] = [icon, status, b, title, desc, action]
	return b


func _pulse(c: Control) -> void:
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.06, 1.06), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	_coins_label.text = "Moedas: %d" % GameData.coins
	for id in _cards:
		var def := GameData.get_arrow(id)
		var icon: ArrowIcon = _cards[id][0]
		var status: Label = _cards[id][1]
		var title: Label = _cards[id][3]
		var desc: Label = _cards[id][4]
		var action: Button = _cards[id][5]
		var unlocked := GameData.is_unlocked(id)
		var selected: bool = id == GameData.selected_arrow
		var lv := GameData.arrow_level(id)
		icon.locked = not unlocked
		icon.selected = selected
		title.text = def["name"] + (" +%d" % lv if lv > 0 else "")
		title.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.6, 0.6, 0.65))
		if unlocked:
			desc.text = def["desc"]
			desc.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
			status.text = "EQUIPADA" if selected else "Dano %d  •  Estamina %d" % [int(GameData.arrow_damage(def)), int(round(GameData.arrow_stamina(def)))]
			status.add_theme_color_override("font_color", UiKit.GOLD if selected else Color(0.7, 0.9, 0.7))
			var cost := GameData.arrow_upgrade_cost(id)
			if cost < 0:
				action.text = "NÍVEL MÁXIMO"
				action.disabled = true
			else:
				action.text = "MELHORAR: %d" % cost
				action.disabled = GameData.coins < cost
		else:
			desc.text = "%d abates seguidos\nou compre com moedas" % def["unlock"]
			desc.add_theme_color_override("font_color", Color(0.95, 0.75, 0.4))
			status.text = "BLOQUEADA"
			status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
			var price := GameData.arrow_unlock_cost(id)
			action.text = "COMPRAR: %d" % price
			action.disabled = GameData.coins < price
