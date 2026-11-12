class_name LimbPiece
extends Node2D
## Membro arrancado (braço com o arco, ou perna) que sai voando, girando e
## sangrando, e cai no abismo.

const GRAVITY := 1500.0
const LIFETIME := 3.0

## Partes desenhadas: [pontos locais, cor, espessura]
var _parts: Array = []
var _velocity := Vector2.ZERO
var _spin := 0.0
var _age := 0.0
var _size := 1.0
var _bleed_timer := 0.0


## "parts" recebe pontos em coordenadas globais: [pontos, cor, espessura].
func setup(parts: Array, velocity: Vector2, size := 1.0) -> void:
	var center := Vector2.ZERO
	var count := 0
	for part in parts:
		for p in part[0]:
			center += p
			count += 1
	center /= maxf(count, 1)
	global_position = center
	for part in parts:
		var local := PackedVector2Array()
		for p in part[0]:
			local.append(p - center)
		_parts.append([local, part[1], part[2]])
	_velocity = velocity
	_spin = randf_range(-9.0, 9.0)
	_size = size
	z_index = 2


func _process(delta: float) -> void:
	_age += delta
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	rotation += _spin * delta
	if _age < 1.0:
		_bleed_timer -= delta
		if _bleed_timer <= 0.0:
			_bleed_timer = 0.06
			Fx.burst(global_position, -_velocity, 1, Color(0.75, 0.04, 0.06), 80.0, 0.6, 3.0, 900.0, 0.5)
	if _age > LIFETIME or global_position.y > 2400.0:
		queue_free()
	elif _age > LIFETIME - 0.5:
		modulate.a = (LIFETIME - _age) / 0.5
	queue_redraw()


func _draw() -> void:
	for part in _parts:
		draw_polyline(part[0], part[1], part[2] * _size, true)
