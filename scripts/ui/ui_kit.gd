class_name UiKit
extends RefCounted
## Funções para criar elementos de interface com o mesmo estilo em todo o jogo.

const GOLD := Color(1.0, 0.82, 0.25)
const DARK := Color(0.08, 0.1, 0.16)


static func make_label(text: String, size := 32, color := Color.WHITE, outline := 8) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", DARK)
	label.add_theme_constant_override("outline_size", outline)
	return label


static func make_style(color: Color, radius := 22, border := 0, border_color := Color.WHITE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = border_color
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


## Botão arredondado com animação de toque (encolhe e volta).
static func make_button(text: String, color := Color(0.95, 0.55, 0.12), size := 40, min_size := Vector2(380, 96)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.85))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", DARK)
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_stylebox_override("normal", make_style(color, 26, 4, color.lightened(0.35)))
	b.add_theme_stylebox_override("hover", make_style(color.lightened(0.08), 26, 4, color.lightened(0.45)))
	b.add_theme_stylebox_override("pressed", make_style(color.darkened(0.15), 26, 4, color.lightened(0.2)))
	b.add_theme_stylebox_override("disabled", make_style(Color(0.4, 0.4, 0.45), 26, 4, Color(0.55, 0.55, 0.6)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.button_down.connect(func() -> void:
		Sfx.play("click")
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.92, 0.92), 0.06))
	b.button_up.connect(func() -> void:
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	return b


static func make_panel(color := Color(0.1, 0.13, 0.22, 0.92)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := make_style(color, 30, 4, Color(1, 1, 1, 0.25))
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	p.add_theme_stylebox_override("panel", sb)
	return p


## Fundo escuro de tela inteira (bloqueia toques no jogo atrás).
static func make_dim(alpha := 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


## Faz um Control "saltar" para dentro da tela.
static func pop_in(node: Control, delay := 0.0) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(0.3, 0.3)
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Margens da área segura (notch, câmera furada, cantos arredondados) em pixels
## da tela do jogo: position = (esquerda, topo), size = (direita, baixo).
## No computador é zero; "--notch" na linha de comando simula um notch para testes.
static func safe_insets(vp: Viewport) -> Rect2:
	var vis := vp.get_visible_rect().size
	if OS.get_cmdline_user_args().has("--notch"):
		return Rect2(0, 90, 0, 40)
	if not OS.has_feature("mobile"):
		return Rect2()
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.x <= 0.0 or safe.size.x <= 0.0:
		return Rect2()
	var k := vis.x / win.x
	var lim := vis.y * 0.15
	return Rect2(
		clampf(safe.position.x * k, 0.0, lim), clampf(safe.position.y * k, 0.0, lim),
		clampf((win.x - safe.end.x) * k, 0.0, lim), clampf((win.y - safe.end.y) * k, 0.0, lim))


## Faz um Control ocupar a tela toda menos o notch e as bordas que o aparelho
## esconde, e se ajusta se a tela mudar (girar, dividir tela...).
## Chame antes de colocar o Control na árvore.
static func fit_safe_area(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var apply := func() -> void:
		var ins := safe_insets(c.get_viewport())
		c.offset_left = ins.position.x
		c.offset_top = ins.position.y
		c.offset_right = -ins.size.x
		c.offset_bottom = -ins.size.y
	c.ready.connect(func() -> void:
		apply.call()
		c.get_viewport().size_changed.connect(apply), CONNECT_ONE_SHOT)


## Ancora um Control e define suas margens (offsets) em relação às âncoras.
static func anchor(c: Control, preset: Control.LayoutPreset, left: float, top: float, right: float, bottom: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = left
	c.offset_top = top
	c.offset_right = right
	c.offset_bottom = bottom


## Escurece a tela, troca de cena e clareia de novo (transição suave).
static func fade_to_scene(from: Node, path: String) -> void:
	var tree := from.get_tree()
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.color = Color(0.03, 0.04, 0.08, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(rect)
	tree.root.add_child(layer)
	var tw := layer.create_tween()
	tw.tween_property(rect, "color:a", 1.0, 0.3)
	tw.tween_callback(func() -> void:
		tree.paused = false
		Engine.time_scale = 1.0
		tree.change_scene_to_file(path))
	tw.tween_interval(0.1)
	tw.tween_property(rect, "color:a", 0.0, 0.35)
	tw.tween_callback(layer.queue_free)
