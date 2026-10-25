extends Node2D
## Cenário desenhado por código: céu em degradê, sol, morros e chão.
## Nada de imagens externas, para manter o jogo leve.

const GROUND_Y := 1000.0
const LEFT := -1000.0
const RIGHT := 2000.0
const TOP := -1000.0
const BOTTOM := 3000.0

const SKY_TOP := Color(0.33, 0.62, 0.92)
const SKY_BOTTOM := Color(0.93, 0.85, 0.70)
const SUN := Color(1.0, 0.93, 0.6)
const HILLS_FAR := Color(0.55, 0.68, 0.62)
const HILLS_NEAR := Color(0.38, 0.55, 0.40)
const GRASS := Color(0.30, 0.62, 0.25)
const DIRT := Color(0.42, 0.30, 0.20)
const DIRT_DARK := Color(0.33, 0.23, 0.15)


func _draw() -> void:
	# Céu (degradê: uma cor por vértice).
	draw_polygon(
		PackedVector2Array([Vector2(LEFT, TOP), Vector2(RIGHT, TOP), Vector2(RIGHT, GROUND_Y), Vector2(LEFT, GROUND_Y)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM])
	)
	draw_circle(Vector2(540, 330), 70.0, SUN)

	_draw_hills(GROUND_Y - 160.0, 90.0, 0.006, 1.3, HILLS_FAR)
	_draw_hills(GROUND_Y - 70.0, 60.0, 0.011, 0.2, HILLS_NEAR)

	# Chão: terra e uma faixa de grama.
	draw_rect(Rect2(LEFT, GROUND_Y, RIGHT - LEFT, BOTTOM - GROUND_Y), DIRT)
	draw_rect(Rect2(LEFT, GROUND_Y + 60.0, RIGHT - LEFT, BOTTOM - GROUND_Y), DIRT_DARK)
	draw_rect(Rect2(LEFT, GROUND_Y, RIGHT - LEFT, 14.0), GRASS)


func _draw_hills(base_y: float, amplitude: float, frequency: float, phase: float, color: Color) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(LEFT, GROUND_Y))
	var x := LEFT
	while x <= RIGHT:
		var y := base_y - amplitude * (0.5 + 0.5 * sin(x * frequency + phase))
		points.append(Vector2(x, y))
		x += 40.0
	points.append(Vector2(RIGHT, GROUND_Y))
	draw_colored_polygon(points, color)
