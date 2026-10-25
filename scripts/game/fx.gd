class_name Fx
extends Node2D
## Partículas 2D leves desenhadas por código (sangue, sucos, faíscas, fumaça)
## e textos flutuantes. Há um limite de partículas para preservar o desempenho.
##
## Uso em qualquer script: Fx.burst(posição, direção, quantidade, cor)

const MAX_PARTICLES := 420
const MAX_TEXTS := 12

enum Kind { DROP, SPARK, SMOKE, RING, FLAKE }

static var instance: Fx = null

var _p: Array[Particle] = []
var _texts: Array[FloatText] = []
var _font: Font


class Particle:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var size: float
	var color: Color
	var gravity: float
	var kind: int
	var drag: float


class FloatText:
	var pos: Vector2
	var text: String
	var color: Color
	var size: int
	var life: float
	var max_life: float


func _ready() -> void:
	instance = self
	_font = ThemeDB.fallback_font
	z_index = 20


func _exit_tree() -> void:
	if instance == self:
		instance = null


## Espalha gotas/partículas a partir de um ponto.
static func burst(pos: Vector2, dir: Vector2, count: int, color: Color, speed := 380.0,
		spread := 1.1, size := 4.0, gravity := 1300.0, life := 0.9, kind := Kind.DROP) -> void:
	if instance == null:
		return
	var base := dir.angle() if dir != Vector2.ZERO else -PI / 2.0
	for i in count:
		var a := base + randf_range(-spread, spread)
		var v := Vector2.from_angle(a) * speed * randf_range(0.35, 1.15)
		instance._add(pos, v, life * randf_range(0.6, 1.2), size * randf_range(0.6, 1.4), color, gravity, kind, 0.0)


static func blood(pos: Vector2, dir: Vector2, amount := 1.0) -> void:
	var c := Color(0.75, 0.04, 0.06)
	burst(pos, dir, int(14 * amount), c, 360.0, 0.75, 4.5)
	burst(pos, -dir, int(5 * amount), c.darkened(0.2), 160.0, 1.4, 3.0)


static func smoke(pos: Vector2, count: int, color := Color(0.9, 0.9, 0.9, 0.6), size := 14.0) -> void:
	burst(pos, Vector2.UP, count, color, 90.0, PI, size, -60.0, 0.9, Kind.SMOKE)


static func sparks(pos: Vector2, dir: Vector2, count: int, color := Color(1, 0.9, 0.5)) -> void:
	burst(pos, dir, count, color, 520.0, 0.9, 2.5, 900.0, 0.35, Kind.SPARK)


static func ring(pos: Vector2, color: Color, size := 60.0, life := 0.4) -> void:
	if instance:
		instance._add(pos, Vector2.ZERO, life, size, color, 0.0, Kind.RING, 0.0)


static func explosion(pos: Vector2, radius: float) -> void:
	ring(pos, Color(1, 0.85, 0.4, 0.9), radius, 0.35)
	burst(pos, Vector2.UP, 26, Color(1, 0.6, 0.1), 520.0, PI, 6.0, 300.0, 0.55, Kind.SPARK)
	burst(pos, Vector2.UP, 16, Color(1, 0.85, 0.3), 260.0, PI, 22.0, -80.0, 0.5, Kind.SMOKE)
	smoke(pos, 12, Color(0.35, 0.33, 0.32, 0.7), 26.0)


static func text(pos: Vector2, msg: String, color := Color.WHITE, size := 34, life := 1.0) -> void:
	if instance == null:
		return
	if instance._texts.size() >= MAX_TEXTS:
		instance._texts.pop_front()
	var t := FloatText.new()
	t.pos = pos
	t.text = msg
	t.color = color
	t.size = size
	t.life = life
	t.max_life = life
	instance._texts.append(t)


func _add(pos: Vector2, vel: Vector2, life: float, size: float, color: Color, gravity: float, kind: int, drag: float) -> void:
	if _p.size() >= MAX_PARTICLES:
		_p.pop_front()
	var p := Particle.new()
	p.pos = pos
	p.vel = vel
	p.life = life
	p.max_life = life
	p.size = size
	p.color = color
	p.gravity = gravity
	p.kind = kind
	p.drag = drag
	_p.append(p)


func _process(delta: float) -> void:
	var i := 0
	while i < _p.size():
		var p := _p[i]
		p.life -= delta
		if p.life <= 0.0:
			_p.remove_at(i)
			continue
		p.vel.y += p.gravity * delta
		if p.kind == Kind.SMOKE:
			p.vel *= 1.0 - minf(delta * 2.5, 1.0)
		p.pos += p.vel * delta
		i += 1
	var j := 0
	while j < _texts.size():
		var t := _texts[j]
		t.life -= delta
		if t.life <= 0.0:
			_texts.remove_at(j)
			continue
		t.pos.y -= 70.0 * delta
		j += 1
	queue_redraw()


func _draw() -> void:
	for p in _p:
		var k := p.life / p.max_life
		var c := p.color
		match p.kind:
			Kind.DROP:
				c.a *= minf(k * 2.0, 1.0)
				draw_circle(p.pos, p.size * (0.5 + 0.5 * k), c)
			Kind.SPARK:
				c.a *= k
				draw_line(p.pos, p.pos - p.vel * 0.03, c, p.size, true)
			Kind.SMOKE:
				c.a *= k
				draw_circle(p.pos, p.size * (1.6 - k * 0.6), c)
			Kind.RING:
				c.a *= k
				draw_arc(p.pos, p.size * (1.0 - k * 0.7), 0, TAU, 36, c, 6.0 * k + 1.0, true)
			Kind.FLAKE:
				c.a *= k
				var s := p.size
				draw_line(p.pos - Vector2(s, 0), p.pos + Vector2(s, 0), c, 2.0)
				draw_line(p.pos - Vector2(0, s), p.pos + Vector2(0, s), c, 2.0)
	for t in _texts:
		var k := t.life / t.max_life
		var scale_in := minf((1.0 - k) * 8.0, 1.0)
		var fs := int(t.size * (0.6 + 0.4 * scale_in))
		var c := t.color
		c.a = minf(k * 3.0, 1.0)
		var w := 600.0
		var pos := t.pos - Vector2(w / 2.0, 0)
		draw_string_outline(_font, pos, t.text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 8, Color(0.05, 0.05, 0.1, c.a))
		draw_string(_font, pos, t.text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, c)
