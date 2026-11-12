class_name SkyBackground
extends Node2D
## Céu animado: degradê, sol pulsando, montanhas ao longe, névoa do abismo
## e nuvens que passam devagar. Tudo desenhado por código.
## O céu muda de cor a cada nova era de inimigos (manhã → noite), com transição suave.

const LEFT := -400.0
const RIGHT := 1200.0
const TOP := -400.0
const BOTTOM := 2600.0

## Paletas: [céu alto, céu meio, céu baixo, montanha longe, montanha perto, névoa, sol, estrelas]
const THEMES := [
	[Color(0.23, 0.45, 0.85), Color(0.55, 0.75, 0.95), Color(0.98, 0.83, 0.62), Color(0.62, 0.66, 0.82), Color(0.45, 0.5, 0.7), Color(0.95, 0.93, 0.98), Color(1, 0.94, 0.62), Color(1, 1, 1, 0)],
	[Color(0.3, 0.5, 0.88), Color(0.72, 0.8, 0.92), Color(1.0, 0.72, 0.45), Color(0.72, 0.6, 0.7), Color(0.55, 0.42, 0.55), Color(1.0, 0.92, 0.85), Color(1, 0.85, 0.45), Color(1, 1, 1, 0)],
	[Color(0.18, 0.42, 0.52), Color(0.52, 0.78, 0.72), Color(0.86, 0.92, 0.62), Color(0.42, 0.6, 0.55), Color(0.25, 0.45, 0.38), Color(0.88, 0.97, 0.9), Color(1, 0.97, 0.7), Color(1, 1, 1, 0)],
	[Color(0.33, 0.24, 0.58), Color(0.95, 0.52, 0.45), Color(1.0, 0.74, 0.35), Color(0.6, 0.4, 0.55), Color(0.4, 0.25, 0.42), Color(1.0, 0.85, 0.78), Color(1, 0.6, 0.3), Color(1, 1, 1, 0.15)],
	[Color(0.12, 0.13, 0.38), Color(0.45, 0.32, 0.6), Color(0.92, 0.55, 0.5), Color(0.35, 0.3, 0.5), Color(0.22, 0.18, 0.35), Color(0.8, 0.7, 0.85), Color(0.95, 0.75, 0.75), Color(1, 1, 1, 0.5)],
	[Color(0.04, 0.03, 0.12), Color(0.18, 0.1, 0.3), Color(0.5, 0.18, 0.32), Color(0.2, 0.12, 0.28), Color(0.1, 0.06, 0.16), Color(0.55, 0.4, 0.6), Color(0.9, 0.9, 1.0), Color(1, 1, 1, 1)],
]

var _time := 0.0
var _sun := Vector2(170, 380)
var _far: PackedVector2Array
var _near: PackedVector2Array
var _from: Array = THEMES[0]
var _to: Array = THEMES[0]
var _blend := 1.0
var _stars: PackedVector2Array


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
	for i in 60:
		_stars.append(Vector2(randf_range(0, 720), randf_range(0, 900)))
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


## Troca suavemente para a paleta de uma era (o índice dá a volta na lista).
func set_theme(index: int) -> void:
	_from = _current()
	_to = THEMES[index % THEMES.size()]
	_blend = 0.0


func _current() -> Array:
	var out: Array = []
	for i in _to.size():
		out.append((_from[i] as Color).lerp(_to[i], _blend))
	return out


func _process(delta: float) -> void:
	_time += delta
	if _blend < 1.0:
		_blend = minf(_blend + delta / 2.5, 1.0)
		# Nuvens escurecem à noite.
		var night: float = _current()[7].a
		for c in get_children():
			(c as CanvasItem).modulate = Color.WHITE.lerp(Color(0.45, 0.4, 0.6), night * 0.8)
	queue_redraw()


func _draw() -> void:
	var pal := _current()
	var sky_top: Color = pal[0]
	var sky_mid: Color = pal[1]
	var sky_low: Color = pal[2]
	var mountain_far: Color = pal[3]
	var mountain_near: Color = pal[4]
	var mist: Color = pal[5]
	var sun: Color = pal[6]
	var stars: Color = pal[7]
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, TOP), Vector2(RIGHT, TOP), Vector2(RIGHT, 700), Vector2(LEFT, 700)]),
		PackedColorArray([sky_top, sky_top, sky_mid, sky_mid]))
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, 700), Vector2(RIGHT, 700), Vector2(RIGHT, BOTTOM), Vector2(LEFT, BOTTOM)]),
		PackedColorArray([sky_mid, sky_mid, sky_low, sky_low]))
	if stars.a > 0.0:
		for i in _stars.size():
			var tw := 0.5 + 0.5 * sin(_time * 2.0 + i * 1.7)
			draw_circle(_stars[i], 1.5 + (i % 3) * 0.6, Color(stars, stars.a * (0.4 + 0.6 * tw)))
	var pulse := 0.5 + 0.5 * sin(_time * 1.5)
	draw_circle(_sun, 120.0 + pulse * 8.0, Color(sun.lightened(0.2), 0.18))
	draw_circle(_sun, 88.0, Color(sun, 0.35))
	draw_circle(_sun, 64.0, sun)
	for i in 12:
		var a := _time * 0.15 + i * TAU / 12.0
		draw_line(_sun + Vector2.from_angle(a) * 82.0, _sun + Vector2.from_angle(a) * (110.0 + pulse * 12.0), Color(sun.lightened(0.2), 0.35 * (1.0 - stars.a)), 4.0)
	draw_colored_polygon(_far, mountain_far)
	draw_colored_polygon(_near, mountain_near)
	# Névoa do abismo.
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, 1060), Vector2(RIGHT, 1060), Vector2(RIGHT, BOTTOM), Vector2(LEFT, BOTTOM)]),
		PackedColorArray([Color(mist, 0.0), Color(mist, 0.0), Color(mist, 0.85), Color(mist, 0.85)]))
