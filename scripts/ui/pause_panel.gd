class_name PausePanel
extends Control
## Tela de pausa: continuar, ligar/desligar som e voltar ao menu.

signal resume_pressed
signal menu_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.make_dim(0.55))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.make_panel()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)

	box.add_child(UiKit.make_label("PAUSADO", 56, Color.WHITE, 10))
	var resume := UiKit.make_button("CONTINUAR", Color(0.2, 0.7, 0.3))
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	box.add_child(resume)
	var sound := UiKit.make_button(_sound_text(), Color(0.25, 0.45, 0.8))
	sound.pressed.connect(func() -> void:
		GameData.set_sound(not GameData.sound_enabled)
		sound.text = _sound_text())
	box.add_child(sound)
	var menu := UiKit.make_button("MENU", Color(0.75, 0.25, 0.25))
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	box.add_child(menu)
	await get_tree().process_frame
	UiKit.pop_in(panel)


func _sound_text() -> String:
	return "SOM: LIGADO" if GameData.sound_enabled else "SOM: DESLIGADO"
