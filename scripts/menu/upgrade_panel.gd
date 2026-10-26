class_name UpgradePanel
extends Control
## Tela de melhorias do personagem: gaste as moedas ganhas nas partidas para
## aumentar vida, dano, estamina, recuperação, armadura e força do arco.

signal closed

var _coins_label: Label
var _rows := {}


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

	box.add_child(UiKit.make_label("MELHORIAS", 48, UiKit.GOLD, 10))
	_coins_label = UiKit.make_label("", 32, UiKit.GOLD, 7)
	box.add_child(_coins_label)
	box.add_child(UiKit.make_label("Ganhe moedas abatendo inimigos,\nvencendo ondas e derrotando chefes.", 20, Color(0.85, 0.9, 1), 5))

	for u in GameData.UPGRADES:
		box.add_child(_make_row(u))

	var done := UiKit.make_button("PRONTO", Color(0.2, 0.7, 0.3), 38, Vector2(380, 88))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	box.add_child(done)
	_refresh()
	await get_tree().process_frame
	UiKit.pop_in(panel)


func _make_row(u: Dictionary) -> PanelContainer:
	var id: String = u["id"]
	var row := PanelContainer.new()
	var sb := UiKit.make_style(Color(0.16, 0.2, 0.32), 18, 2, Color(1, 1, 1, 0.15))
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.content_margin_left = 16
	sb.content_margin_right = 10
	row.add_theme_stylebox_override("panel", sb)
	row.custom_minimum_size = Vector2(600, 0)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	h.add_child(info)
	var title := UiKit.make_label(u["name"], 28, Color.WHITE, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(title)
	var desc := UiKit.make_label(u["desc"], 18, Color(0.8, 0.85, 0.95), 4)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(desc)
	var pips := UiKit.make_label("", 22, UiKit.GOLD, 4)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(pips)

	var buy := UiKit.make_button("", Color(0.95, 0.55, 0.12), 26, Vector2(170, 76))
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.pressed.connect(func() -> void:
		if GameData.buy_upgrade(id):
			Sfx.play("unlock", -6.0)
			_pulse(row)
			_refresh()
		else:
			Sfx.play("hurt", -10.0))
	h.add_child(buy)
	_rows[id] = [pips, buy]
	return row


func _pulse(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.05, 1.05), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	_coins_label.text = "Moedas: %d" % GameData.coins
	for id in _rows:
		var pips: Label = _rows[id][0]
		var buy: Button = _rows[id][1]
		var lv := GameData.upgrade_level(id)
		var max_lv: int = (GameData.get_upgrade(id)["cost"] as Array).size()
		pips.text = "Nível %d/%d" % [lv, max_lv]
		var cost := GameData.upgrade_cost(id)
		if cost < 0:
			buy.text = "MÁXIMO"
			buy.disabled = true
		else:
			buy.text = "%d moedas" % cost
			buy.disabled = GameData.coins < cost
