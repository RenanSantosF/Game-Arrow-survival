class_name Arsenal
extends Control
## Arsenal: tela cheia para melhorar o arqueiro e as flechas.
##
## - Aba ARQUEIRO: o arqueiro animado (o visual evolui com as melhorias) e um
##   cartão colorido por melhoria, com o que muda e o preço.
## - Aba FLECHAS: os ESPAÇOS de flecha (só as equipadas vão para a partida;
##   espaços extras são caros), a grade de flechas e, embaixo, os detalhes da
##   flecha tocada com os botões EQUIPAR / MELHORAR / COMPRAR.
## Toda compra tem brilho, som e o contador de moedas animado; quando falta
## dinheiro, a tela diz quanto falta.
## Melhorar não é só pagar: cada flecha precisa de EXPERIÊNCIA (ganha usando-a
## nas partidas) e o arqueiro precisa ter alcançado certas ondas. No nível
## máximo a flecha vira MESTRE.

signal closed

enum Tab { HERO, ARROWS }

const BG_TOP := Color(0.11, 0.13, 0.27)
const BG_BOTTOM := Color(0.04, 0.05, 0.11)
const CARD := Color(0.15, 0.18, 0.31)
const GREEN := Color(0.2, 0.72, 0.36)
const GRAY := Color(0.3, 0.33, 0.42)
const RANKS := [[0, "Aprendiz"], [6, "Caçador"], [14, "Cavaleiro"], [24, "Rei Arqueiro"]]

## Cor e ícone de cada melhoria do arqueiro.
const UPGRADE_LOOK := {
	"hp": Color(0.92, 0.25, 0.32),
	"damage": Color(0.98, 0.55, 0.15),
	"stamina": Color(1.0, 0.78, 0.15),
	"regen": Color(0.3, 0.8, 0.42),
	"armor": Color(0.45, 0.62, 0.9),
	"bow": Color(0.68, 0.42, 0.95),
}

var start_tab := Tab.HERO

var _tab := Tab.HERO
var _coin_label: Label
var _coin_pill: PanelContainer
var _shown_coins := 0.0
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _fx_layer: Control

# Aba ARQUEIRO
var _hero: Stickman
var _hero_time := 0.0
var _rank_label: Label
var _rank_bar: RankBar
var _rank_next: Label
var _upgrade_cards := {}

# Aba FLECHAS
var _slot_title: Label
var _slots: Array[Button] = []
var _arrow_cards := {}
var _detail_id := "normal"
var _detail_icon: ArrowIcon
var _detail_name: Label
var _detail_pips: Pips
var _detail_desc: Label
var _detail_stats: Label
var _detail_xp_bar: RankBar
var _detail_xp_label: Label
var _free_btn: Button
var _ad_check := 0.0
var _equip_btn: Button
var _main_btn: Button
var _main_price: PriceTag


# --- Peças desenhadas -------------------------------------------------------------

## Fundo em degradê com pontinhos de luz subindo devagar.
class Backdrop:
	extends Control
	var top := Color.BLACK
	var bottom := Color.BLACK
	var _dots: Array = []
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 26:
			_dots.append([randf(), randf(), randf_range(2.0, 5.0), randf_range(0.02, 0.06)])

	func _process(delta: float) -> void:
		_t += delta
		for d in _dots:
			d[1] = fposmod(d[1] - d[3] * delta, 1.0)
		queue_redraw()

	func _draw() -> void:
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([top, top, bottom, bottom]))
		for d in _dots:
			var a := 0.12 + 0.1 * sin(_t * 2.0 + d[0] * 20.0)
			draw_circle(Vector2(d[0] * size.x, d[1] * size.y), d[2], Color(1, 0.9, 0.6, a))


## Moeda dourada desenhada.
class CoinIcon:
	extends Control
	func _init(px := 30.0) -> void:
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_circle(c + Vector2(0, 2), r, Color(0.55, 0.35, 0.05))
		draw_circle(c, r, Color(1.0, 0.78, 0.18))
		draw_circle(c, r * 0.7, Color(1.0, 0.86, 0.35))
		draw_arc(c, r * 0.7, 0, TAU, 24, Color(0.85, 0.6, 0.1), maxf(r * 0.12, 1.5), true)
		draw_line(c + Vector2(0, -r * 0.35), c + Vector2(0, r * 0.35), Color(0.85, 0.6, 0.1), maxf(r * 0.18, 2.0), true)


## Preço com moeda: [moeda] 400
class PriceTag:
	extends HBoxContainer
	var label: Label
	var coin: CoinIcon

	func _init(font_size := 26) -> void:
		alignment = BoxContainer.ALIGNMENT_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override("separation", 8)
		coin = CoinIcon.new(font_size * 1.05)
		coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(coin)
		label = UiKit.make_label("", font_size, Color.WHITE, 7)
		add_child(label)

	func show_text(text: String, with_coin: bool) -> void:
		label.text = text
		coin.visible = with_coin


## Bolinhas de nível: ● ● ● ○ ○
class Pips:
	extends Control
	var count := 5
	var filled := 0
	var color := Color.WHITE
	var align_left := false

	func _init(p_count := 5, p_color := Color.WHITE, height := 16.0) -> void:
		count = p_count
		color = p_color
		custom_minimum_size = Vector2(0, height)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_value(v: int, total: int) -> void:
		filled = v
		count = total
		queue_redraw()

	func _draw() -> void:
		var r := size.y / 2.0 - 1.0
		var step := r * 2.0 + 6.0
		var x0 := r + 1.0 if align_left else (size.x - step * count + 6.0) / 2.0 + r
		for i in count:
			var p := Vector2(x0 + i * step, size.y / 2.0)
			if i < filled:
				draw_circle(p, r, color)
				draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(1, 1, 1, 0.5))
			else:
				draw_circle(p, r, Color(0, 0, 0, 0.35))
				draw_arc(p, r, 0, TAU, 16, Color(color, 0.5), 1.5, true)


## Selo verde com "visto": flecha levada para a partida.
class CheckBadge:
	extends Control
	func _init() -> void:
		custom_minimum_size = Vector2(30, 30)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c + Vector2(0, 2), 14.0, Color(0, 0, 0, 0.35))
		draw_circle(c, 14.0, Color(0.25, 0.8, 0.4))
		draw_polyline(PackedVector2Array([c + Vector2(-7, 0), c + Vector2(-2, 6), c + Vector2(8, -6)]), Color.WHITE, 3.5, true)


## Ícone de cada melhoria do arqueiro, num círculo colorido.
class StatIcon:
	extends Control
	var kind := "hp"
	var color := Color.WHITE

	func _init(p_kind: String, p_color: Color, px := 64.0) -> void:
		kind = p_kind
		color = p_color
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_circle(c, r, color.darkened(0.45))
		draw_circle(c, r - 4.0, color.darkened(0.2))
		var w := Color.WHITE
		var s := r * 0.55
		match kind:
			"hp":
				draw_circle(c + Vector2(-s * 0.45, -s * 0.15), s * 0.5, w)
				draw_circle(c + Vector2(s * 0.45, -s * 0.15), s * 0.5, w)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.93, 0), c + Vector2(s * 0.93, 0), c + Vector2(0, s * 0.95)]), w)
			"damage":
				draw_line(c + Vector2(-s, s), c + Vector2(s * 0.5, -s * 0.5), w, 5.0, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(s, -s), c + Vector2(s * 0.15, -s * 0.65), c + Vector2(s * 0.65, -s * 0.15)]), w)
				draw_line(c + Vector2(-s, s * 0.45), c + Vector2(-s * 0.45, s), w, 4.0, true)
			"stamina":
				draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, -s), c + Vector2(-s * 0.55, s * 0.15), c + Vector2(-s * 0.05, s * 0.15),
					c + Vector2(-s * 0.2, s), c + Vector2(s * 0.55, -s * 0.15), c + Vector2(s * 0.05, -s * 0.15)]), w)
			"regen":
				draw_arc(c, s * 0.8, -PI * 0.15, PI * 1.45, 24, w, 5.0, true)
				var tip := c + Vector2.from_angle(-PI * 0.15) * s * 0.8
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.4, -s * 0.05), tip + Vector2(s * 0.3, -s * 0.05), tip + Vector2(0, s * 0.4)]), w)
			"armor":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, -s * 0.8), c + Vector2(s * 0.8, -s * 0.8), c + Vector2(s * 0.8, s * 0.1),
					c + Vector2(0, s), c + Vector2(-s * 0.8, s * 0.1)]), w)
				draw_line(c + Vector2(0, -s * 0.6), c + Vector2(0, s * 0.7), color.darkened(0.2), 3.0, true)
			"bow":
				draw_arc(c + Vector2(-s * 0.35, 0), s * 0.95, -PI * 0.42, PI * 0.42, 20, w, 5.0, true)
				var a := c + Vector2(-s * 0.35, 0) + Vector2.from_angle(-PI * 0.42) * s * 0.95
				var b := c + Vector2(-s * 0.35, 0) + Vector2.from_angle(PI * 0.42) * s * 0.95
				draw_line(a, b, Color(1, 1, 1, 0.8), 2.0, true)
				draw_line(c + Vector2(-s * 0.2, 0), c + Vector2(s, 0), w, 3.0, true)


## Barra de progresso até o próximo título do arqueiro.
class RankBar:
	extends Control
	var ratio := 0.0
	var shown := 0.0
	var fill := Color(0.45, 0.8, 1.0)

	func _process(delta: float) -> void:
		shown = move_toward(shown, ratio, delta * 1.5)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0, 0, 0, 0.4))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * shown, size.y)), fill)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * shown, size.y * 0.4)), Color(1, 1, 1, 0.25))
		draw_rect(r, Color(1, 1, 1, 0.35), false, 2.0)


## Pedestal brilhante embaixo do arqueiro.
class Pedestal:
	extends Control
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y - 26.0)
		var glow := 0.5 + 0.5 * sin(_t * 2.0)
		draw_circle(c + Vector2(0, -90), 95.0 + glow * 6.0, Color(0.45, 0.75, 1.0, 0.08 + 0.05 * glow))
		draw_set_transform(c, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 92.0, Color(0.3, 0.55, 0.95, 0.35))
		draw_circle(Vector2.ZERO, 70.0, Color(0.55, 0.8, 1.0, 0.35))
		draw_set_transform(Vector2.ZERO)


## Estrelinhas que estouram num ponto (compra feita).
class Sparkles:
	extends Control
	var _p: Array = []
	var _life := 0.9
	var color := Color(1, 0.85, 0.3)

	func burst(at: Vector2, n := 22) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in n:
			var a := randf() * TAU
			_p.append([at, Vector2.from_angle(a) * randf_range(160.0, 520.0), randf_range(3.0, 7.0)])

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		for p in _p:
			p[1] *= 1.0 - minf(delta * 3.0, 1.0)
			p[1].y += 300.0 * delta
			p[0] += p[1] * delta
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_life / 0.9, 0.0, 1.0)
		for p in _p:
			var s: float = p[2] * (0.5 + k)
			var pos: Vector2 = p[0]
			var col := Color(color, k)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -s * 1.6), pos + Vector2(s * 0.45, 0), pos + Vector2(0, s * 1.6), pos + Vector2(-s * 0.45, 0)]), col)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-s * 1.6, 0), pos + Vector2(0, s * 0.45), pos + Vector2(s * 1.6, 0), pos + Vector2(0, -s * 0.45)]), col)


# --- Montagem da tela --------------------------------------------------------------

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := Backdrop.new()
	bg.top = BG_TOP
	bg.bottom = BG_BOTTOM
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	col.add_child(_build_header())
	col.add_child(_build_tabs())
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(pages)
	_pages = [_build_hero_page(), _build_arrows_page()]
	for p in _pages:
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pages.add_child(p)

	_fx_layer = Control.new()
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)
	_toast = UiKit.make_panel(Color(0.06, 0.07, 0.13, 0.95))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label = UiKit.make_label("", 28, Color.WHITE, 6)
	_toast.add_child(_toast_label)
	_toast.modulate.a = 0.0
	_fx_layer.add_child(_toast)

	_shown_coins = GameData.coins
	_detail_id = GameData.selected_arrow
	_switch_tab(start_tab, false)
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _build_header() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var back := UiKit.make_button("VOLTAR", Color(0.3, 0.35, 0.55), 26, Vector2(150, 70))
	back.pressed.connect(_close)
	h.add_child(back)
	var title := UiKit.make_label("ARSENAL", 46, UiKit.GOLD, 10)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title)
	_coin_pill = PanelContainer.new()
	var sb := UiKit.make_style(Color(0.08, 0.09, 0.16, 0.9), 30, 3, Color(1.0, 0.8, 0.3, 0.7))
	sb.content_margin_left = 12
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_coin_pill.add_theme_stylebox_override("panel", sb)
	_coin_pill.custom_minimum_size = Vector2(170, 64)
	var tag := PriceTag.new(30)
	_coin_label = tag.label
	_coin_label.add_theme_color_override("font_color", UiKit.GOLD)
	_coin_pill.add_child(tag)
	h.add_child(_coin_pill)
	return h


func _build_tabs() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	for i in 2:
		var b := UiKit.make_button(["ARQUEIRO", "FLECHAS"][i], GRAY, 32, Vector2(0, 76))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tab: int = i
		b.pressed.connect(func() -> void: _switch_tab(tab, true))
		h.add_child(b)
		_tab_buttons.append(b)
	return h


func _switch_tab(tab: int, animate: bool) -> void:
	_tab = tab
	for i in _pages.size():
		_pages[i].visible = i == tab
		_restyle(_tab_buttons[i], Color(0.95, 0.55, 0.12) if i == tab else GRAY)
	if animate:
		var page := _pages[tab]
		page.modulate.a = 0.0
		page.position.x = 40.0 * (1 if tab == Tab.ARROWS else -1)
		var tw := page.create_tween().set_parallel()
		tw.tween_property(page, "modulate:a", 1.0, 0.2)
		tw.tween_property(page, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# --- Aba ARQUEIRO ---------------------------------------------------------------------

func _build_hero_page() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)

	var hero_card := _card_panel(Color(0.13, 0.17, 0.33), Color(0.45, 0.75, 1.0, 0.5))
	hero_card.custom_minimum_size = Vector2(0, 250)
	v.add_child(hero_card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	hero_card.add_child(h)
	var stage := Pedestal.new()
	stage.custom_minimum_size = Vector2(250, 230)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	_hero = Stickman.new()
	_hero.hit_layer = 0
	_hero.body_color = Color(0.12, 0.35, 0.85)
	_hero.accessory = Stickman.Accessory.BANDANA
	_hero.accessory_color = Color(0.98, 0.78, 0.1)
	_hero.scale = Vector2(1.25, 1.25)
	_hero.position = Vector2(110, 210)
	PlayerArcher.apply_rank_look(_hero)
	stage.add_child(_hero)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 8)
	h.add_child(info)
	info.add_child(UiKit.make_label("SEU ARQUEIRO", 20, Color(0.7, 0.85, 1.0), 5))
	_rank_label = UiKit.make_label("", 40, Color.WHITE, 9)
	info.add_child(_rank_label)
	_rank_bar = RankBar.new()
	_rank_bar.custom_minimum_size = Vector2(0, 24)
	info.add_child(_rank_bar)
	_rank_next = UiKit.make_label("", 18, Color(0.8, 0.88, 1.0), 5)
	info.add_child(_rank_next)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)
	for u in GameData.UPGRADES:
		grid.add_child(_make_upgrade_card(u))

	# Moedas grátis assistindo anúncio (só aparece no celular, com limite por dia).
	_free_btn = UiKit.make_button("", Color(0.55, 0.3, 0.85), 26, Vector2(0, 80))
	var tag := PriceTag.new(26)
	tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_free_btn.add_child(tag)
	_free_btn.set_meta("tag", tag)
	_free_btn.pressed.connect(_on_free_coins)
	_free_btn.visible = Ads.is_available()
	v.add_child(_free_btn)
	return v


func _make_upgrade_card(u: Dictionary) -> Control:
	var id: String = u["id"]
	var color: Color = UPGRADE_LOOK[id]
	var card := _card_panel(CARD, Color(color, 0.7))
	card.custom_minimum_size = Vector2(336, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(StatIcon.new(id, color, 62))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(names)
	var title := UiKit.make_label(u["name"], 28, Color.WHITE, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	names.add_child(title)
	var pips := Pips.new((u["cost"] as Array).size(), color, 15)
	pips.align_left = true
	pips.custom_minimum_size.x = 150
	names.add_child(pips)
	var effect := UiKit.make_label("", 19, Color(color.lightened(0.4)), 4)
	effect.clip_text = true
	effect.custom_minimum_size.x = 10
	v.add_child(effect)
	var buy := UiKit.make_button("", GREEN, 26, Vector2(0, 62))
	var price := PriceTag.new(26)
	price.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buy.add_child(price)
	buy.pressed.connect(func() -> void: _buy_upgrade(id, buy, card))
	v.add_child(buy)
	_upgrade_cards[id] = {"effect": effect, "pips": pips, "buy": buy, "price": price}
	return card


## Texto "agora » depois" de cada melhoria.
func _upgrade_effect_text(id: String, lv: int, maxed: bool) -> String:
	var label: String = {"hp": "Vida", "damage": "Dano", "stamina": "Estamina", "regen": "Recuperação",
		"armor": "Dano sofrido", "bow": "Força"}[id]
	var now := _upgrade_value(id, lv)
	if maxed:
		return "%s: %s" % [label, now]
	return "%s: %s » %s" % [label, now, _upgrade_value(id, lv + 1)]


func _upgrade_value(id: String, lv: int) -> String:
	match id:
		"hp":
			return str(150 + 20 * lv)
		"damage":
			return "+%d%%" % (10 * lv)
		"stamina":
			return str(100 + 15 * lv)
		"regen":
			return "+%d%%" % (20 * lv)
		"armor":
			return "-%d%%" % (7 * lv)
		"bow":
			return "+%d%%" % (6 * lv)
	return ""


func _buy_upgrade(id: String, button: Button, card: Control) -> void:
	var cost := GameData.upgrade_cost(id)
	if cost < 0:
		return
	if not GameData.upgrade_wave_ok(id):
		Sfx.play("hurt", -8.0)
		_shake(button)
		_show_toast("Chegue à onda %d numa partida\npara liberar este nível" % GameData.upgrade_wave_needed(id), Color(0.6, 0.85, 1.0))
		return
	if GameData.coins < cost:
		_not_enough(cost, button)
		return
	var old_rank := GameData.player_rank_name()
	GameData.buy_upgrade(id)
	_celebrate(button, card, "NÍVEL %d!" % GameData.upgrade_level(id), UPGRADE_LOOK[id])
	PlayerArcher.apply_rank_look(_hero)
	_hero.play_shot_recoil()
	if GameData.player_rank_name() != old_rank:
		_show_toast("NOVO TÍTULO: %s!" % GameData.player_rank_name().to_upper(), UiKit.GOLD)
		Sfx.play("record", -4.0)
	_refresh()


# --- Aba FLECHAS ----------------------------------------------------------------------

func _build_arrows_page() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)

	_slot_title = UiKit.make_label("", 22, Color(0.8, 0.9, 1.0), 6)
	v.add_child(_slot_title)
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 10)
	v.add_child(slots)
	for i in GameData.max_slots():
		var b := Button.new()
		b.custom_minimum_size = Vector2(124, 124)
		b.focus_mode = Control.FOCUS_NONE
		var index: int = i
		b.pressed.connect(func() -> void: _on_slot(index))
		slots.add_child(b)
		_slots.append(b)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for def in GameData.ARROWS:
		grid.add_child(_make_arrow_card(def))

	var sheet := _card_panel(Color(0.12, 0.15, 0.28), Color(1.0, 0.8, 0.3, 0.6))
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sheet)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	sheet.add_child(sv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	sv.add_child(top)
	_detail_icon = ArrowIcon.new("normal")
	_detail_icon.custom_minimum_size = Vector2(118, 118)
	top.add_child(_detail_icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	top.add_child(info)
	_detail_name = UiKit.make_label("", 34, Color.WHITE, 8)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_detail_name)
	_detail_pips = Pips.new(GameData.ARROW_MAX_LEVEL, UiKit.GOLD, 18)
	_detail_pips.align_left = true
	info.add_child(_detail_pips)
	_detail_desc = UiKit.make_label("", 19, Color(0.85, 0.9, 1.0), 5)
	_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_detail_desc)
	_detail_xp_label = UiKit.make_label("", 18, Color(0.6, 0.9, 1.0), 5)
	_detail_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_detail_xp_label)
	_detail_xp_bar = RankBar.new()
	_detail_xp_bar.custom_minimum_size = Vector2(0, 14)
	info.add_child(_detail_xp_bar)
	_detail_stats = UiKit.make_label("", 20, Color(0.7, 1.0, 0.7), 5)
	sv.add_child(_detail_stats)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	sv.add_child(buttons)
	_equip_btn = UiKit.make_button("", Color(0.25, 0.5, 0.9), 26, Vector2(0, 76))
	_equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_btn.pressed.connect(_on_equip)
	buttons.add_child(_equip_btn)
	_main_btn = UiKit.make_button("", GREEN, 26, Vector2(0, 76))
	_main_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_price = PriceTag.new(26)
	_main_price.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_btn.add_child(_main_price)
	_main_btn.pressed.connect(_on_main_action)
	buttons.add_child(_main_btn)
	return v


func _make_arrow_card(def: Dictionary) -> Button:
	var id: String = def["id"]
	var b := Button.new()
	b.custom_minimum_size = Vector2(164, 150)
	b.focus_mode = Control.FOCUS_NONE
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 6
	v.offset_bottom = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var icon := ArrowIcon.new(id)
	icon.custom_minimum_size = Vector2(76, 76)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var title := UiKit.make_label(def["name"], 19, Color.WHITE, 5)
	v.add_child(title)
	var pips := Pips.new(GameData.ARROW_MAX_LEVEL, UiKit.GOLD, 11)
	v.add_child(pips)
	# Barrinha de experiência (encher usando a flecha).
	var xp := RankBar.new()
	xp.fill = Color(0.35, 0.85, 1.0)
	xp.custom_minimum_size = Vector2(110, 6)
	xp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(xp)
	# Selo no canto: equipada (vai para a partida).
	var badge := CheckBadge.new()
	badge.position = Vector2(126, 6)
	b.add_child(badge)
	b.pressed.connect(func() -> void:
		_detail_id = id
		Sfx.play("click")
		_pulse(b, 1.06)
		_refresh())
	_arrow_cards[id] = {"button": b, "icon": icon, "title": title, "pips": pips, "badge": badge, "xp": xp}
	return b


func _on_slot(index: int) -> void:
	var loadout := GameData.loadout
	if index < loadout.size():
		_detail_id = loadout[index]
		Sfx.play("click")
		_refresh()
	elif index < GameData.arrow_slots:
		_show_toast("Toque numa flecha e em EQUIPAR", Color(0.8, 0.9, 1.0))
	elif index == GameData.arrow_slots:
		var cost := GameData.next_slot_cost()
		if GameData.coins < cost:
			_not_enough(cost, _slots[index])
			return
		GameData.buy_slot()
		_celebrate(_slots[index], _slots[index], "NOVO ESPAÇO!", Color(0.5, 0.85, 1.0))
		_refresh()
	else:
		_show_toast("Compre os espaços em ordem", Color(0.8, 0.9, 1.0))


func _on_equip() -> void:
	var id := _detail_id
	if not GameData.is_unlocked(id) or id == "normal":
		return
	if GameData.is_equipped(id):
		GameData.unequip(id)
		Sfx.play("click")
		_show_toast("Removida da partida", Color(0.8, 0.9, 1.0))
	elif GameData.equip(id):
		Sfx.play("unlock", -6.0)
		var slot := _slots[GameData.loadout.size() - 1]
		_celebrate(slot, slot, "", Color(0.5, 0.85, 1.0), false)
	else:
		Sfx.play("hurt", -10.0)
		_shake(_equip_btn)
		_show_toast("Espaços cheios! Remova uma flecha\nou compre outro espaço", Color(1, 0.75, 0.5))
	_refresh()


func _on_main_action() -> void:
	var id := _detail_id
	if not GameData.is_unlocked(id):
		var price := GameData.arrow_unlock_cost(id)
		if GameData.coins < price:
			_not_enough(price, _main_btn)
			return
		GameData.buy_arrow(id)
		_celebrate(_main_btn, _arrow_cards[id]["button"], "NOVA FLECHA!", UiKit.GOLD)
	else:
		var cost := GameData.arrow_upgrade_cost(id)
		if cost < 0:
			return
		if not GameData.arrow_xp_ok(id):
			Sfx.play("hurt", -8.0)
			_shake(_main_btn)
			_show_toast("Use a %s nas partidas:\nacertos e abates dão experiência" % GameData.get_arrow(id)["name"], Color(0.6, 0.85, 1.0))
			return
		if GameData.coins < cost:
			_not_enough(cost, _main_btn)
			return
		GameData.buy_arrow_upgrade(id)
		var master := GameData.is_master(id)
		_celebrate(_main_btn, _arrow_cards[id]["button"], "MESTRE!" if master else "NÍVEL %d!" % GameData.arrow_level(id), UiKit.GOLD)
		if master:
			Sfx.play("record", -4.0)
			_show_toast("%s virou MESTRE!\n+10%% de dano e brilho dourado" % GameData.get_arrow(id)["name"], UiKit.GOLD)
	_refresh()


# --- Atualização da tela --------------------------------------------------------------

func _refresh() -> void:
	_refresh_hero()
	_refresh_arrows()


func _refresh_hero() -> void:
	var total := GameData.total_upgrade_levels()
	var current := 0
	for i in RANKS.size():
		if total >= int(RANKS[i][0]):
			current = i
	_rank_label.text = GameData.player_rank_name()
	if current + 1 < RANKS.size():
		var lo: int = RANKS[current][0]
		var hi: int = RANKS[current + 1][0]
		_rank_bar.ratio = float(total - lo) / float(hi - lo)
		_rank_next.text = "Mais %d melhoria%s para virar\n%s" % [hi - total, "s" if hi - total > 1 else "", RANKS[current + 1][1]]
	else:
		_rank_bar.ratio = 1.0
		_rank_next.text = "Título máximo!"
	for u in GameData.UPGRADES:
		var id: String = u["id"]
		var c: Dictionary = _upgrade_cards[id]
		var lv := GameData.upgrade_level(id)
		var cost := GameData.upgrade_cost(id)
		(c["pips"] as Pips).set_value(lv, (u["cost"] as Array).size())
		(c["effect"] as Label).text = _upgrade_effect_text(id, lv, cost < 0)
		var buy: Button = c["buy"]
		var price: PriceTag = c["price"]
		if cost < 0:
			price.show_text("MÁXIMO", false)
			_restyle(buy, Color(0.75, 0.55, 0.15))
		else:
			if not GameData.upgrade_wave_ok(id):
				price.show_text("Chegue à onda %d" % GameData.upgrade_wave_needed(id), false)
				_restyle(buy, Color(0.2, 0.3, 0.5))
			else:
				price.show_text(str(cost), true)
				_restyle(buy, GREEN if GameData.coins >= cost else GRAY)
	_refresh_free_button()


func _refresh_free_button() -> void:
	if not _free_btn.visible:
		return
	var tag: PriceTag = _free_btn.get_meta("tag")
	var left := GameData.free_coin_ads_left()
	if left <= 0:
		tag.show_text("Volte amanhã: mais moedas grátis", false)
		_restyle(_free_btn, GRAY)
	elif not Ads.is_rewarded_ready():
		tag.show_text("Carregando anúncio...", false)
		_restyle(_free_btn, GRAY)
	else:
		tag.show_text("VER ANÚNCIO: +%d   (%d hoje)" % [GameData.FREE_COIN_REWARD, left], true)
		_restyle(_free_btn, Color(0.55, 0.3, 0.85))


func _on_free_coins() -> void:
	if GameData.free_coin_ads_left() <= 0 or not Ads.is_rewarded_ready():
		Sfx.play("hurt", -10.0)
		_shake(_free_btn)
		return
	Ads.show_rewarded(func() -> void:
		GameData.claim_free_coins()
		_celebrate(_free_btn, _coin_pill, "+%d MOEDAS!" % GameData.FREE_COIN_REWARD, UiKit.GOLD)
		_refresh())


func _refresh_arrows() -> void:
	var loadout := GameData.loadout
	_slot_title.text = "NA PARTIDA: %d de %d espaços" % [loadout.size(), GameData.arrow_slots]
	for i in _slots.size():
		_fill_slot(_slots[i], i, loadout)

	for def in GameData.ARROWS:
		var id: String = def["id"]
		var c: Dictionary = _arrow_cards[id]
		var unlocked := GameData.is_unlocked(id)
		var equipped := GameData.is_equipped(id)
		var lv := GameData.arrow_level(id)
		(c["icon"] as ArrowIcon).locked = not unlocked
		(c["icon"] as ArrowIcon).selected = equipped
		(c["title"] as Label).add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.55, 0.57, 0.65))
		(c["pips"] as Pips).set_value(lv, GameData.ARROW_MAX_LEVEL)
		(c["pips"] as Pips).visible = unlocked
		(c["badge"] as Control).visible = equipped
		var xp_bar: RankBar = c["xp"]
		var need := GameData.arrow_xp_needed(id)
		xp_bar.visible = unlocked and need > 0
		if need > 0:
			xp_bar.ratio = float(GameData.get_arrow_xp(id)) / need
			xp_bar.fill = Color(0.4, 1.0, 0.5) if GameData.arrow_xp_ok(id) else Color(0.35, 0.85, 1.0)
		var border := UiKit.GOLD if id == _detail_id else (Color(0.4, 0.9, 0.5, 0.8) if equipped else Color(1, 1, 1, 0.15))
		var bg := Color(0.2, 0.24, 0.4) if id == _detail_id else CARD
		_style_card_button(c["button"], bg, border, 4 if id == _detail_id else 2)

	_refresh_detail()


func _fill_slot(b: Button, i: int, loadout: Array) -> void:
	for child in b.get_children():
		child.queue_free()
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	if i < loadout.size():
		var icon := ArrowIcon.new(loadout[i])
		icon.custom_minimum_size = Vector2(78, 78)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.selected = loadout[i] == _detail_id
		v.add_child(icon)
		v.add_child(UiKit.make_label(GameData.get_arrow(loadout[i])["name"], 16, Color.WHITE, 4))
		_style_card_button(b, Color(0.16, 0.3, 0.22), Color(0.45, 0.95, 0.55), 3)
	elif i < GameData.arrow_slots:
		v.add_child(UiKit.make_label("+", 54, Color(1, 1, 1, 0.45), 4))
		v.add_child(UiKit.make_label("vazio", 16, Color(1, 1, 1, 0.5), 4))
		_style_card_button(b, Color(0.1, 0.12, 0.2), Color(1, 1, 1, 0.3), 2)
	else:
		var lock := ArrowIcon.new("normal")
		lock.locked = true
		lock.custom_minimum_size = Vector2(52, 52)
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(lock)
		if i == GameData.arrow_slots:
			var tag := PriceTag.new(19)
			tag.show_text(str(GameData.next_slot_cost()), true)
			v.add_child(tag)
			v.add_child(UiKit.make_label("novo espaço", 13, Color(0.8, 0.9, 1.0), 4))
			_style_card_button(b, Color(0.22, 0.17, 0.08), UiKit.GOLD, 3)
		else:
			v.add_child(UiKit.make_label("bloqueado", 14, Color(1, 1, 1, 0.4), 4))
			_style_card_button(b, Color(0.08, 0.09, 0.14), Color(1, 1, 1, 0.12), 2)


func _refresh_detail() -> void:
	var id := _detail_id
	var def := GameData.get_arrow(id)
	var unlocked := GameData.is_unlocked(id)
	var lv := GameData.arrow_level(id)
	_detail_icon.arrow_id = id
	_detail_icon.locked = not unlocked
	var master := GameData.is_master(id)
	_detail_name.text = def["name"] + ("  MESTRE" if master else ("" if lv == 0 else "  +%d" % lv))
	_detail_name.add_theme_color_override("font_color", UiKit.GOLD if master else Color.WHITE)
	var need := GameData.arrow_xp_needed(id)
	var xp := GameData.get_arrow_xp(id)
	_detail_xp_bar.visible = unlocked and need > 0
	_detail_xp_label.visible = unlocked
	if master:
		_detail_xp_label.text = "Experiência completa!"
	elif need > 0:
		_detail_xp_bar.ratio = float(xp) / need
		var ready := xp >= need
		_detail_xp_bar.fill = Color(0.4, 1.0, 0.5) if ready else Color(0.35, 0.85, 1.0)
		_detail_xp_label.text = "Experiência %d/%d%s" % [xp, need, "  PRONTA!" if ready else " (use nas partidas)"]
		_detail_xp_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6) if ready else Color(0.6, 0.9, 1.0))
	_detail_pips.set_value(lv, GameData.ARROW_MAX_LEVEL)
	_detail_pips.visible = unlocked
	_detail_desc.text = String(def["desc"]).replace("\n", " ")

	var dmg := GameData.arrow_damage(def)
	var st := GameData.arrow_stamina(def)
	if not unlocked:
		_detail_stats.text = "Dano %d   •   Estamina %d\nou libere com %d abates seguidos" % [int(dmg), int(round(st)), def["unlock"]]
		_detail_stats.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	elif lv >= GameData.ARROW_MAX_LEVEL:
		_detail_stats.text = "Dano %d   •   Estamina %d\nMESTRE: +10%% de dano extra e brilho dourado!" % [int(dmg), int(round(st))]
		_detail_stats.add_theme_color_override("font_color", UiKit.GOLD)
	else:
		var next_master := GameData.MASTER_BONUS if lv + 1 >= GameData.ARROW_MAX_LEVEL else 0.0
		var next_dmg := float(def["damage"]) * (1.0 + 0.12 * (lv + 1) + next_master)
		var next_st := float(def["stamina"]) * (1.0 - 0.06 * (lv + 1))
		_detail_stats.text = "Dano %d » %d   •   Estamina %d » %d\nEfeito especial +15%% mais forte" % [int(dmg), int(next_dmg), int(round(st)), int(round(next_st))]
		_detail_stats.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))

	# Botão da esquerda: equipar / remover.
	if not unlocked:
		_equip_btn.text = "BLOQUEADA"
		_restyle(_equip_btn, Color(0.25, 0.27, 0.35))
	elif id == "normal":
		_equip_btn.text = "SEMPRE LEVA"
		_restyle(_equip_btn, Color(0.25, 0.27, 0.35))
	elif GameData.is_equipped(id):
		_equip_btn.text = "REMOVER"
		_restyle(_equip_btn, Color(0.75, 0.3, 0.3))
	else:
		_equip_btn.text = "EQUIPAR"
		_restyle(_equip_btn, Color(0.25, 0.5, 0.9))

	# Botão da direita: comprar / melhorar.
	if not unlocked:
		var price := GameData.arrow_unlock_cost(id)
		_main_price.show_text("COMPRAR  %d" % price, true)
		_restyle(_main_btn, GREEN if GameData.coins >= price else GRAY)
	else:
		var cost := GameData.arrow_upgrade_cost(id)
		if cost < 0:
			_main_price.show_text("MÁXIMO", false)
			_restyle(_main_btn, Color(0.75, 0.55, 0.15))
		elif not GameData.arrow_xp_ok(id):
			_main_price.show_text("USE MAIS  (%d XP)" % (need - xp), false)
			_restyle(_main_btn, Color(0.2, 0.3, 0.5))
		else:
			_main_price.show_text("MELHORAR  %d" % cost, true)
			_restyle(_main_btn, GREEN if GameData.coins >= cost else GRAY)


# --- Efeitos ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_ad_check -= delta
	if _ad_check <= 0.0 and _free_btn:
		_ad_check = 1.0
		_refresh_free_button()
	_shown_coins = move_toward(_shown_coins, GameData.coins, maxf(delta * 60.0, absf(GameData.coins - _shown_coins) * delta * 6.0))
	if _coin_label:
		_coin_label.text = str(int(round(_shown_coins)))
	if is_instance_valid(_hero):
		# O arqueiro de exemplo puxa o arco e solta, sem parar.
		_hero_time += delta
		var cycle := fmod(_hero_time, 2.4)
		_hero.is_aiming = cycle < 1.6
		_hero.aim_angle = -0.25 + sin(_hero_time * 0.7) * 0.15
		_hero.draw_power = clampf(cycle / 1.2, 0.0, 1.0) if cycle < 1.6 else 0.0
		if cycle >= 1.6 and cycle - delta < 1.6:
			_hero.play_shot_recoil()


func _celebrate(button: Control, target: Control, text: String, color: Color, sound := true) -> void:
	if sound:
		Sfx.play("unlock", -4.0)
	var sp := Sparkles.new()
	sp.color = color.lightened(0.3)
	_fx_layer.add_child(sp)
	sp.burst(button.get_global_rect().get_center() - _fx_layer.get_global_rect().position)
	_pulse(target, 1.08)
	_pulse(_coin_pill, 1.1)
	if text != "":
		var label := UiKit.make_label(text, 34, color.lightened(0.4), 8)
		_fx_layer.add_child(label)
		label.reset_size()
		label.position = target.get_global_rect().get_center() - _fx_layer.get_global_rect().position - label.size / 2.0
		var tw := label.create_tween().set_parallel()
		tw.tween_property(label, "position:y", label.position.y - 90.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.35)
		tw.chain().tween_callback(label.queue_free)


func _not_enough(cost: int, button: Control) -> void:
	Sfx.play("hurt", -8.0)
	_shake(button)
	_shake(_coin_pill)
	var pill_tw := _coin_pill.create_tween()
	_coin_pill.modulate = Color(1, 0.45, 0.45)
	pill_tw.tween_property(_coin_pill, "modulate", Color.WHITE, 0.5)
	_show_toast("Faltam %d moedas!" % (cost - GameData.coins), Color(1, 0.6, 0.5))


func _show_toast(text: String, color: Color) -> void:
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	_toast.reset_size()
	_toast.position = Vector2((_fx_layer.size.x - _toast.size.x) / 2.0, _fx_layer.size.y * 0.42)
	_toast.pivot_offset = _toast.size / 2.0
	_toast.scale = Vector2(0.6, 0.6)
	_toast.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	var tw := _toast.create_tween()
	_toast_tween = tw
	tw.tween_property(_toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _pulse(c: Control, amount: float) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(amount, amount), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake(c: Control) -> void:
	var x := c.position.x
	var tw := c.create_tween()
	for d in [12.0, -10.0, 7.0, -4.0, 0.0]:
		tw.tween_property(c, "position:x", x + d, 0.04)


# --- Estilos -------------------------------------------------------------------------------

func _card_panel(bg: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiKit.make_style(bg, 22, 3, border)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	return p


## Troca a cor de um botão criado pelo UiKit.
func _restyle(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", UiKit.make_style(color, 26, 4, color.lightened(0.35)))
	b.add_theme_stylebox_override("hover", UiKit.make_style(color.lightened(0.08), 26, 4, color.lightened(0.45)))
	b.add_theme_stylebox_override("pressed", UiKit.make_style(color.darkened(0.15), 26, 4, color.lightened(0.2)))


func _style_card_button(b: Button, bg: Color, border: Color, width: int) -> void:
	for state in ["normal", "hover", "pressed"]:
		var c := bg.lightened(0.06) if state == "hover" else (bg.darkened(0.1) if state == "pressed" else bg)
		var sb := UiKit.make_style(c, 18, width, border)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _close() -> void:
	closed.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
