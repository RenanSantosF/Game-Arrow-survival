extends Node2D
## Desenha a mira: onde o dedo tocou, quanto foi puxado e o começo da trajetória.

const DOTS := 13
const TIME_STEP := 0.05

var _active := false
var _touch_start := Vector2.ZERO
var _touch_current := Vector2.ZERO
var _show_trajectory := false
var _launch_position := Vector2.ZERO
var _launch_velocity := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 30


func update_aim(touch_start: Vector2, touch_current: Vector2, show_trajectory: bool,
		launch_position: Vector2, launch_velocity: Vector2) -> void:
	_active = true
	_touch_start = touch_start
	_touch_current = touch_current
	_show_trajectory = show_trajectory
	_launch_position = launch_position
	_launch_velocity = launch_velocity
	queue_redraw()


func hide_aim() -> void:
	_active = false
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _active:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 10.0)
	draw_arc(_touch_start, 30.0 + pulse * 4.0, 0.0, TAU, 32, Color(1, 1, 1, 0.55), 3.0, true)
	draw_line(_touch_start, _touch_current, Color(1, 1, 1, 0.3), 5.0, true)
	draw_circle(_touch_current, 12.0, Color(1, 1, 1, 0.65))

	if not _show_trajectory:
		return
	for i in DOTS:
		var t := (i + 1) * TIME_STEP
		var point := _launch_position + _launch_velocity * t + Vector2(0, 0.5 * Arrow.GRAVITY * t * t)
		var alpha := 1.0 - float(i) / DOTS
		draw_circle(point, 6.0 - i * 0.3, Color(0.05, 0.05, 0.1, 0.35 * alpha))
		draw_circle(point, 4.5 - i * 0.25, Color(1, 1, 1, 0.95 * alpha))
