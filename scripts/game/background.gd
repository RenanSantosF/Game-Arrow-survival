class_name SkyBackground
extends Node2D
## Céu animado: degradê, sol pulsando, montanhas ao longe, névoa do abismo
## e nuvens que passam devagar. Tudo desenhado por código.

const LEFT := -400.0
const RIGHT := 1200.0
const TOP := -400.0
const BOTTOM := 2600.0

const SKY_TOP := Color(0.23, 0.45, 0.85)
const SKY_MID := Color(0.55, 0.75, 0.95)
const SKY_LOW := Color(0.98, 0.83, 0.62)
const MOUNTAIN_FAR := Color(0.62, 0.66, 0.82)
const MOUNTAIN_NEAR := Color(0.45, 0.5, 0.7)
const MIST := Color(0.95, 0.93, 0.98)

var _time := 0.0
var _sun := Vector2(170, 380)
var _far: PackedVector2Array
var _near: PackedVector2Array


class Cloud:
	extends Node2D
	var speed := 20.0
	var puffs: Array = []
	var tint := Color.WHITE

	func _init(p_speed: float, p_scale: float, alpha: float) -> void:
		speed = p_speed
		scale = Vector2(p_scale, p_scale)
		tint = Color(1, 1, 1, alpha)
		for i in randi_range(4, 6):
			puffs.append([Vector2(i * 34 - 80 + randf_range(-6, 6), randf_range(-14, 8)), randf_range(26, 40)])

	func _process(delta: float) -> void:
		position.x += speed * delta
		if position.x > 900:
			position.x = -260
			position.y = randf_range(120, 1100)

	func _draw() -> void:
		for p in puffs:
			draw_circle(p[0] + Vector2(0, 6), p[1], Color(0.75, 0.8, 0.95, tint.a * 0.6))
		for p in puffs:
			draw_circle(p[0], p[1], tint)


func _ready() -> void:
	z_index = -50
	_far = _ridge(1240.0, 170.0, 0.011, 0.0)
	_near = _ridge(1360.0, 140.0, 0.017, 2.0)
	for i in 7:
		var far := i < 4
		var c := Cloud.new(randf_range(8, 14) if far else randf_range(18, 30), randf_range(0.6, 0.9) if far else randf_range(1.0, 1.4), 0.55 if far else 0.85)
		c.position = Vector2(randf_range(-200, 800), randf_range(120, 1150))
		c.z_index = 1 if far else 2
		add_child(c)


func _ridge(base_y: float, amp: float, freq: float, phase: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(LEFT, BOTTOM))
	var x := LEFT
	while x <= RIGHT:
		var y := base_y - amp * (0.5 + 0.5 * sin(x * freq + phase)) - 40.0 * sin(x * freq * 2.7 + phase)
		pts.append(Vector2(x, y))
		x += 30.0
	pts.append(Vector2(RIGHT, BOTTOM))
	return pts


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, TOP), Vector2(RIGHT, TOP), Vector2(RIGHT, 700), Vector2(LEFT, 700)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_MID, SKY_MID]))
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, 700), Vector2(RIGHT, 700), Vector2(RIGHT, BOTTOM), Vector2(LEFT, BOTTOM)]),
		PackedColorArray([SKY_MID, SKY_MID, SKY_LOW, SKY_LOW]))
	var pulse := 0.5 + 0.5 * sin(_time * 1.5)
	draw_circle(_sun, 120.0 + pulse * 8.0, Color(1, 0.95, 0.7, 0.18))
	draw_circle(_sun, 88.0, Color(1, 0.93, 0.6, 0.35))
	draw_circle(_sun, 64.0, Color(1, 0.94, 0.62))
	for i in 12:
		var a := _time * 0.15 + i * TAU / 12.0
		draw_line(_sun + Vector2.from_angle(a) * 82.0, _sun + Vector2.from_angle(a) * (110.0 + pulse * 12.0), Color(1, 0.95, 0.7, 0.35), 4.0)
	draw_colored_polygon(_far, MOUNTAIN_FAR)
	draw_colored_polygon(_near, MOUNTAIN_NEAR)
	# Névoa do abismo.
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, 1060), Vector2(RIGHT, 1060), Vector2(RIGHT, BOTTOM), Vector2(LEFT, BOTTOM)]),
		PackedColorArray([Color(MIST, 0.0), Color(MIST, 0.0), Color(MIST, 0.85), Color(MIST, 0.85)]))
