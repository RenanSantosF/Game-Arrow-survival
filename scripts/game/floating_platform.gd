class_name FloatingPlatform
extends Node2D
## Ilhota flutuante onde um arqueiro fica em pé. Ela balança suavemente,
## entra na tela com animação e desmorona/cai quando o arqueiro morre.
## O personagem é filho da plataforma, com os pés em (0, 0).

const WIDTH := 116.0
const THICKNESS := 24.0

var base_position := Vector2.ZERO
var grass_color := Color(0.33, 0.68, 0.27)
var rock_color := Color(0.42, 0.33, 0.27)

var _time := 0.0
var _phase := 0.0
var _falling := false
var _fall_velocity := Vector2.ZERO
var _spin := 0.0
var _bob_amount := 6.0
var _offset := Vector2.ZERO
var _rocks: PackedVector2Array


func _ready() -> void:
	_phase = randf() * TAU
	var body := StaticBody2D.new()
	body.collision_layer = Arrow.LAYER_WORLD
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, THICKNESS)
	cs.shape = rect
	cs.position = Vector2(0, THICKNESS / 2.0)
	body.add_child(cs)
	add_child(body)
	# Formato irregular da parte de baixo (rochas).
	_rocks = PackedVector2Array([
		Vector2(-WIDTH / 2.0, THICKNESS * 0.6), Vector2(-WIDTH * 0.32, THICKNESS + 14 + randf() * 8),
		Vector2(-WIDTH * 0.12, THICKNESS + 30 + randf() * 14), Vector2(WIDTH * 0.05, THICKNESS + 44 + randf() * 12),
		Vector2(WIDTH * 0.2, THICKNESS + 26 + randf() * 10), Vector2(WIDTH * 0.38, THICKNESS + 12 + randf() * 6),
		Vector2(WIDTH / 2.0, THICKNESS * 0.6),
	])


## Posiciona a plataforma e faz a animação de entrada.
func enter(target: Vector2, from_offset := Vector2(500, 0), delay := 0.0) -> void:
	base_position = target
	_offset = from_offset
	position = target + from_offset
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "_offset", Vector2.ZERO, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Fx.burst(global_position + Vector2(0, THICKNESS), Vector2.DOWN, 10, Color(1, 1, 1, 0.6), 120.0, 1.2, 10.0, -40.0, 0.6, Fx.Kind.SMOKE))


func place(target: Vector2) -> void:
	base_position = target
	position = target


func crumble(delay := 0.4) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		_falling = true
		_fall_velocity = Vector2(randf_range(-30, 30), -60)
		_spin = randf_range(-1.2, 1.2)
		Fx.burst(global_position + Vector2(0, THICKNESS), Vector2.DOWN, 14, rock_color, 160.0, 1.0, 5.0, 900.0, 1.0)
		Sfx.play("wood", -2.0, 0.3))


func is_falling() -> bool:
	return _falling


## Retângulo do topo (em coordenadas globais), usado pelo ragdoll.
func get_top_rect() -> Rect2:
	return Rect2(global_position + Vector2(-WIDTH / 2.0, 0), Vector2(WIDTH, THICKNESS))


func _process(delta: float) -> void:
	_time += delta
	if _falling:
		_fall_velocity.y += 1100.0 * delta
		position += _fall_velocity * delta
		rotation += _spin * delta
		if global_position.y > 2600.0:
			queue_free()
	else:
		position = base_position + _offset + Vector2(0, sin(_time * 1.3 + _phase) * _bob_amount)
	queue_redraw()


func _draw() -> void:
	# Sombra de "vento" embaixo para dar sensação de flutuar.
	var glow := 0.12 + 0.05 * sin(_time * 2.0 + _phase)
	draw_circle(Vector2(0, THICKNESS + 40), 34, Color(1, 1, 1, glow * 0.5))
	draw_colored_polygon(_rocks, rock_color)
	draw_colored_polygon(PackedVector2Array([
		_rocks[1], _rocks[2], _rocks[3], Vector2(0, THICKNESS + 8),
	]), rock_color.darkened(0.25))
	var top := Rect2(-WIDTH / 2.0, 0, WIDTH, THICKNESS * 0.75)
	draw_rect(top, rock_color.lightened(0.1))
	draw_rect(Rect2(-WIDTH / 2.0 - 3, -3, WIDTH + 6, 11), grass_color)
	for i in 6:
		var x := -WIDTH / 2.0 + 8 + i * (WIDTH - 16) / 5.0
		draw_line(Vector2(x, 6), Vector2(x - 3, 15 + (i % 2) * 6), grass_color.darkened(0.15), 3.0)
