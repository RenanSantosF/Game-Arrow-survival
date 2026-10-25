class_name Fruit
extends Node2D
## Fruta que sobe do fundo da tela e cai de novo. Acerte com uma flecha para pegar:
## - Maçã vermelha: recupera VIDA.
## - Fruta-estrela amarela: recupera ESTAMINA.

const GRAVITY := 520.0
const RADIUS := 26.0

enum Kind { HEALTH, STAMINA }

var kind: Kind = Kind.HEALTH
var velocity := Vector2.ZERO

var _spin := 0.0
var _time := 0.0
var _collected := false


func _ready() -> void:
	_spin = randf_range(-2.5, 2.5)
	var area := Area2D.new()
	area.collision_layer = Arrow.LAYER_FRUIT
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("fruit", self)
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS + 8.0
	cs.shape = circle
	area.add_child(cs)
	add_child(area)


func get_color() -> Color:
	return Color(0.92, 0.12, 0.15) if kind == Kind.HEALTH else Color(1.0, 0.82, 0.1)


func hit_by_arrow(arrow: Arrow) -> void:
	if _collected or not arrow.from_player:
		return
	_collected = true
	Fx.burst(global_position, arrow.velocity, 22, get_color(), 300.0, PI, 5.0, 700.0, 0.8)
	Fx.burst(global_position, Vector2.UP, 8, Color(1, 1, 1, 0.9), 200.0, PI, 3.0, 300.0, 0.5, Fx.Kind.SPARK)
	Fx.ring(global_position, get_color().lightened(0.3), 70.0, 0.45)
	Sfx.play("fruit")
	if Game.instance:
		Game.instance.collect_fruit(self)
	queue_free()


func _process(delta: float) -> void:
	_time += delta
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += _spin * delta
	if velocity.y > 0.0 and global_position.y > 2400.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var glow := 0.25 + 0.15 * sin(_time * 6.0)
	var c := get_color()
	draw_circle(Vector2.ZERO, RADIUS + 12.0, Color(c.r, c.g, c.b, glow * 0.5))
	if kind == Kind.HEALTH:
		draw_circle(Vector2(-7, 2), RADIUS * 0.82, c)
		draw_circle(Vector2(7, 2), RADIUS * 0.82, c)
		draw_circle(Vector2(0, 5), RADIUS * 0.8, c)
		draw_circle(Vector2(-9, -6), 6.0, Color(1, 1, 1, 0.45))
		draw_line(Vector2(0, -16), Vector2(3, -28), Color(0.4, 0.25, 0.1), 4.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(3, -24), Vector2(18, -32), Vector2(12, -20)]), Color(0.3, 0.75, 0.25))
		_draw_heart(Vector2(0, 6), 8.0, Color(1, 1, 1, 0.9))
	else:
		var pts := PackedVector2Array()
		for i in 10:
			var r := RADIUS * (1.05 if i % 2 == 0 else 0.6)
			pts.append(Vector2.from_angle(i * TAU / 10.0 - PI / 2.0) * r)
		draw_colored_polygon(pts, c)
		draw_polyline(pts + PackedVector2Array([pts[0]]), c.darkened(0.25), 2.5, true)
		draw_circle(Vector2(-6, -7), 5.0, Color(1, 1, 1, 0.5))
		var s := 10.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.25 * s, -s), Vector2(-0.55 * s, 0.15 * s), Vector2(-0.05 * s, 0.15 * s),
			Vector2(-0.25 * s, s), Vector2(0.55 * s, -0.15 * s), Vector2(0.05 * s, -0.15 * s),
		]), Color(1, 1, 1, 0.95))


func _draw_heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, 0), c + Vector2(r * 1.02, 0), c + Vector2(0, r * 1.05)]), col)
