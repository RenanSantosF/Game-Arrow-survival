class_name StatBar
extends Control
## Barra de vida/estamina animada: a parte perdida "escorre" devagar e a barra
## pisca quando está baixa.

enum Icon { HEART, BOLT }

var max_value := 100.0
var value := 100.0
var color := Color(0.9, 0.2, 0.25)
var icon: Icon = Icon.HEART

var _shown := 100.0
var _ghost := 100.0
var _time := 0.0
var _flash := 0.0


func _init(p_color := Color.RED, p_icon := Icon.HEART) -> void:
	color = p_color
	icon = p_icon
	custom_minimum_size = Vector2(300, 38)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_value(v: float, max_v: float) -> void:
	if v > value + 0.5:
		_flash = 1.0
	value = v
	max_value = max_v


func snap() -> void:
	_shown = value
	_ghost = value


func _process(delta: float) -> void:
	_time += delta
	_shown = lerpf(_shown, value, minf(delta * 14.0, 1.0))
	if _ghost > _shown:
		_ghost = move_toward(_ghost, _shown, delta * max_value * 0.6)
	else:
		_ghost = _shown
	_flash = maxf(_flash - delta * 3.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var icon_w := h + 8.0
	var bar := Rect2(icon_w, h * 0.18, size.x - icon_w, h * 0.64)
	var ratio := clampf(_shown / max_value, 0.0, 1.0)
	var ghost_ratio := clampf(_ghost / max_value, 0.0, 1.0)

	draw_rect(bar.grow(4), Color(0.05, 0.06, 0.1, 0.85))
	draw_rect(bar, Color(0.18, 0.2, 0.26))
	if ghost_ratio > ratio:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ghost_ratio, bar.size.y)), Color(1, 0.95, 0.8, 0.8))
	var c := color
	if ratio < 0.25:
		c = c.lerp(Color.WHITE, 0.35 * (0.5 + 0.5 * sin(_time * 12.0)))
	c = c.lerp(Color.WHITE, _flash * 0.6)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), c)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y * 0.35)), Color(1, 1, 1, 0.25))

	var center := Vector2(h / 2.0, h / 2.0)
	draw_circle(center, h / 2.0, Color(0.05, 0.06, 0.1, 0.85))
	match icon:
		Icon.HEART:
			_draw_heart(center, h * 0.32, color.lightened(0.15))
		Icon.BOLT:
			_draw_bolt(center, h * 0.36, color.lightened(0.15))


func _draw_heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 1.02, 0), c + Vector2(r * 1.02, 0), c + Vector2(0, r * 1.05)
	]), col)


func _draw_bolt(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0.25 * r, -r), c + Vector2(-0.55 * r, 0.15 * r), c + Vector2(-0.05 * r, 0.15 * r),
		c + Vector2(-0.25 * r, r), c + Vector2(0.55 * r, -0.15 * r), c + Vector2(0.05 * r, -0.15 * r),
	]), col)
