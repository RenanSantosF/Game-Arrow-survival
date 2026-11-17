class_name ContinuePanel
extends Control
## Oferta depois de morrer: "CONTINUAR?" com uma barra que vai encolhendo.
## O jogador pode ver um anúncio premiado para voltar à partida de onde parou
## (uma vez por partida). Se o tempo acabar ou ele recusar, vai para a derrota.
## Se o anúncio ainda não carregou, espera um pouco por ele; se não vier, avisa.

signal accepted
signal declined

const TIME := 5.0
const AD_WAIT := 8.0

var _left := TIME
var _waiting_ad := 0.0
var _done := false
var _bar: ProgressBar
var _seconds: Label
var _button: Button
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := UiKit.make_dim(0.0)
	add_child(dim)
	dim.create_tween().tween_property(dim, "color:a", 0.55, 0.3)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.make_panel()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	box.add_child(UiKit.make_label(tr("CONTINUAR?"), 64, UiKit.GOLD, 12))
	box.add_child(UiKit.make_label(tr("Volte com 60% da vida,\nna mesma onda"), 26, Color(0.85, 0.9, 1.0), 6))

	_button = UiKit.make_button(tr("CONTINUAR (ver anúncio)"), Color(0.55, 0.3, 0.85), 30, Vector2(480, 104))
	_button.pressed.connect(_on_accept)
	box.add_child(_button)

	# Barra que vai fechando (contagem regressiva).
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(480, 22)
	_bar.show_percentage = false
	_bar.max_value = TIME
	_bar.value = TIME
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(11)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiKit.GOLD
	fill.set_corner_radius_all(11)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	_seconds = UiKit.make_label("5", 30, Color.WHITE, 6)
	box.add_child(_seconds)

	_info = UiKit.make_label("", 22, Color(1, 0.7, 0.6), 5)
	_info.visible = false
	box.add_child(_info)

	var no := UiKit.make_button(tr("Não, obrigado"), Color(0.3, 0.33, 0.45), 26, Vector2(300, 70))
	no.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	no.pressed.connect(_decline)
	box.add_child(no)

	Ads.request_rewarded()
	await get_tree().process_frame
	UiKit.pop_in(panel)
	_button.pivot_offset = _button.size / 2.0
	var tw := _button.create_tween().set_loops()
	tw.tween_property(_button, "scale", Vector2(1.06, 1.06), 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_button, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if _done:
		return
	if _waiting_ad > 0.0:
		# Tocou em continuar mas o anúncio ainda está carregando.
		_waiting_ad -= delta
		if Ads.is_rewarded_ready():
			_finish(true)
		elif _waiting_ad <= 0.0:
			_info.text = tr("Anúncio indisponível agora")
			_info.visible = true
			_done = true
			get_tree().create_timer(1.4, true, false, true).timeout.connect(func() -> void:
				declined.emit())
		return
	_left = maxf(_left - delta, 0.0)
	_bar.value = _left
	_seconds.text = str(ceili(_left))
	if _left <= 0.0:
		_decline()


func _on_accept() -> void:
	if _done or _waiting_ad > 0.0:
		return
	if Ads.is_rewarded_ready():
		_finish(true)
	else:
		_waiting_ad = AD_WAIT
		_button.text = tr("Carregando anúncio...")
		Ads.request_rewarded()


func _decline() -> void:
	if _done:
		return
	_finish(false)


func _finish(accept: bool) -> void:
	_done = true
	if accept:
		accepted.emit()
	else:
		declined.emit()
