class_name ArrowIcon
extends Control
## Desenha o ícone de um tipo de flecha (usado no menu e na barra do jogo).

var arrow_id := "normal"
var locked := false
var selected := false
var _time := 0.0


func _init(id := "normal") -> void:
	arrow_id = id
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(90, 90)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var def: Dictionary = GameData.get_arrow(arrow_id)
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	var bg := Color(0.14, 0.17, 0.27) if not selected else Color(0.32, 0.24, 0.08)
	draw_circle(c, r, bg)
	var trail: Color = def["trail"]
	if trail.a > 0.0 and not locked:
		draw_circle(c, r * (0.82 + 0.05 * sin(_time * 4.0)), Color(trail.r, trail.g, trail.b, 0.22))
	draw_arc(c, r, 0, TAU, 40, UiKit.GOLD if selected else Color(1, 1, 1, 0.35), 4.0 if selected else 2.0, true)

	var alen := r * 1.5
	var angle := -PI / 4.0
	draw_set_transform(c + Vector2.from_angle(angle) * alen / 2.0, angle, Vector2.ONE * (alen / 54.0))
	var mod := Color(0.35, 0.35, 0.4) if locked else Color.WHITE
	ArrowDraw.draw_arrow(self, def, mod)
	draw_set_transform(Vector2.ZERO)

	if locked:
		_draw_lock(c + Vector2(r * 0.42, r * 0.42), r * 0.42)


func _draw_lock(p: Vector2, s: float) -> void:
	draw_arc(p + Vector2(0, -s * 0.35), s * 0.42, PI, TAU, 16, Color(0.9, 0.9, 0.95), s * 0.18, true)
	draw_rect(Rect2(p + Vector2(-s * 0.6, -s * 0.35), Vector2(s * 1.2, s * 0.95)), UiKit.GOLD)
	draw_circle(p + Vector2(0, s * 0.1), s * 0.14, UiKit.DARK)
