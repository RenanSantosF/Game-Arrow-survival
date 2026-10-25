extends Node2D
## Desenha a mira: onde o dedo tocou, quanto foi puxado e a trajetória prevista.
##
## O nó usa top_level = true, então desenha em coordenadas globais, sem ser
## afetado pelo balanço do personagem.

const DOTS := 14
const TIME_STEP := 0.05

var _active := false
var _touch_start := Vector2.ZERO
var _touch_current := Vector2.ZERO
var _show_trajectory := false
var _launch_position := Vector2.ZERO
var _launch_velocity := Vector2.ZERO


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 10


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


func _draw() -> void:
	if not _active:
		return

	# Indicador do dedo: círculo no ponto inicial e linha até o dedo.
	draw_arc(_touch_start, 28.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 3.0, true)
	draw_line(_touch_start, _touch_current, Color(1, 1, 1, 0.35), 4.0, true)
	draw_circle(_touch_current, 10.0, Color(1, 1, 1, 0.6))

	if not _show_trajectory:
		return

	# Trajetória aproximada (somente o começo, para manter o desafio).
	for i in DOTS:
		var t := (i + 1) * TIME_STEP
		var point := _launch_position + _launch_velocity * t + Vector2(0, 0.5 * Arrow.GRAVITY * t * t)
		var alpha := 1.0 - float(i) / DOTS
		draw_circle(point, 5.0 - i * 0.2, Color(1, 1, 1, 0.9 * alpha))
