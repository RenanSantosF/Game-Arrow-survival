class_name ArrowSelectPanel
extends Control
## Tela de escolha de flechas. Flechas bloqueadas mostram quantos abates
## seguidos (sem morrer) são necessários para desbloquear.

signal closed

var _cards := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.make_dim(0.65))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.make_panel()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	box.add_child(UiKit.make_label("ESCOLHA SUA FLECHA", 44, UiKit.GOLD, 10))
	box.add_child(UiKit.make_label("Desbloqueie novas flechas abatendo\ninimigos seguidos, sem morrer!", 22, Color(0.85, 0.9, 1), 5))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for def in GameData.ARROWS:
		grid.add_child(_make_card(def))

	var done := UiKit.make_button("PRONTO", Color(0.2, 0.7, 0.3), 38, Vector2(380, 84))
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
	var unlocked := GameData.is_unlocked(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(196, 196)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiKit.make_style(Color(0.16, 0.2, 0.32), 20, 3, Color(1, 1, 1, 0.2)))
	b.add_theme_stylebox_override("hover", UiKit.make_style(Color(0.2, 0.24, 0.38), 20, 3, Color(1, 1, 1, 0.3)))
	b.add_theme_stylebox_override("pressed", UiKit.make_style(Color(0.12, 0.15, 0.25), 20, 3, Color(1, 1, 1, 0.3)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 10
	v.offset_bottom = -10
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)

	var icon := ArrowIcon.new(id)
	icon.locked = not unlocked
	icon.custom_minimum_size = Vector2(72, 72)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	v.add_child(UiKit.make_label(def["name"], 24, Color.WHITE if unlocked else Color(0.6, 0.6, 0.65), 6))
	var desc := UiKit.make_label(def["desc"] if unlocked else "Faça %d abates\nseguidos" % def["unlock"], 15, Color(0.8, 0.85, 0.95) if unlocked else Color(0.95, 0.75, 0.4), 4)
	v.add_child(desc)
	var status := UiKit.make_label("", 16, UiKit.GOLD, 5)
	v.add_child(status)

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
	_cards[id] = [icon, status, b]
	return b


func _refresh() -> void:
	for id in _cards:
		var icon: ArrowIcon = _cards[id][0]
		var status: Label = _cards[id][1]
		var selected: bool = id == GameData.selected_arrow
		icon.selected = selected
		if not GameData.is_unlocked(id):
			status.text = "BLOQUEADA"
			status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		elif selected:
			status.text = "EQUIPADA"
			status.add_theme_color_override("font_color", UiKit.GOLD)
		else:
			status.text = "Toque para equipar"
			status.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
