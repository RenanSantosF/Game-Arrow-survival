class_name Stickman
extends Node2D
## Personagem stickman com arco, desenhado só com linhas e círculos (sem imagens).
##
## A origem (0, 0) fica nos PÉS do personagem. Isso facilita posicioná-lo no
## chão e faz o balanço ao ser atingido girar em torno dos pés.

## Emitido quando uma flecha atinge este personagem.
signal hit_taken(arrow: Node2D, hit_position: Vector2)

enum Accessory { NONE, BANDANA, HAT }

const SHOULDER := Vector2(0, -122)
const NECK := Vector2(0, -132)
const HIP := Vector2(0, -70)
const HEAD := Vector2(0, -152)
const HEAD_RADIUS := 16.0
const LINE_WIDTH := 6.0
const ARM_LENGTH := 38.0
const BOW_RADIUS := 34.0
const BOW_HALF_ANGLE := 0.95
const STRING_COLOR := Color(0.95, 0.95, 0.95)

@export var body_color := Color(0.1, 0.1, 0.1)
@export var bow_color := Color(0.45, 0.27, 0.1)
@export var accessory_color := Color(0.9, 0.2, 0.2)
@export var accessory: Accessory = Accessory.NONE
## Marque para o personagem olhar para a esquerda (inimigos).
@export var facing_left := false

## Ângulo (em radianos) para onde o arco aponta.
var aim_angle := 0.0
## Força de tensão da corda, de 0.0 (solta) a 1.0 (máxima).
var draw_power := 0.0
## Enquanto verdadeiro, mostra a flecha encaixada no arco.
var is_aiming := false

var _time := 0.0
var _flash := 0.0
var _lean := 0.0
var _lean_velocity := 0.0


func _ready() -> void:
	aim_angle = get_idle_angle()


func get_facing() -> float:
	return -1.0 if facing_left else 1.0


func get_idle_angle() -> float:
	return PI + 0.15 if facing_left else -0.15


## Posição global de onde a flecha deve sair.
func get_arrow_spawn_global() -> Vector2:
	return to_global(_shoulder() + Vector2.from_angle(aim_angle) * (ARM_LENGTH + 10.0))


## Chamado pela flecha quando ela acerta este personagem.
func take_hit(arrow: Node2D, hit_position: Vector2, arrow_velocity: Vector2) -> void:
	_flash = 1.0
	_lean_velocity += clampf(arrow_velocity.x * 0.0025, -3.0, 3.0)
	hit_taken.emit(arrow, hit_position)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 5.0, 0.0)
	# Mola amortecida: o corpo balança com o impacto e volta ao lugar.
	_lean_velocity += (-_lean * 120.0 - _lean_velocity * 10.0) * delta
	_lean += _lean_velocity * delta
	rotation = _lean
	queue_redraw()


func _shoulder() -> Vector2:
	return SHOULDER + Vector2(0, _breath())


func _breath() -> float:
	return sin(_time * 2.2) * 1.5


func _draw() -> void:
	var f := get_facing()
	var col := body_color.lerp(Color.WHITE, _flash)
	var breath := _breath()
	var shoulder := _shoulder()
	var neck := NECK + Vector2(0, breath)
	var head := HEAD + Vector2(0, breath)

	# Pernas (perna de trás e perna da frente, com joelho levemente dobrado).
	draw_polyline(PackedVector2Array([HIP, Vector2(-8 * f, -36), Vector2(-22 * f, 0)]), col, LINE_WIDTH, true)
	draw_polyline(PackedVector2Array([HIP, Vector2(14 * f, -36), Vector2(20 * f, 0)]), col, LINE_WIDTH, true)
	# Tronco e cabeça.
	draw_line(HIP, neck, col, LINE_WIDTH, true)
	draw_circle(head, HEAD_RADIUS, col)
	draw_circle(head + Vector2(7 * f, -3), 3.0, Color.WHITE)
	_draw_accessory(head, f)

	# Arco: a mão da frente segura o arco; a de trás puxa a corda.
	var dir := Vector2.from_angle(aim_angle)
	var hand := shoulder + dir * ARM_LENGTH
	var center := hand - dir * (BOW_RADIUS - 6.0)
	var tip_a := center + Vector2.from_angle(aim_angle - BOW_HALF_ANGLE) * BOW_RADIUS
	var tip_b := center + Vector2.from_angle(aim_angle + BOW_HALF_ANGLE) * BOW_RADIUS
	var pull := hand - dir * (8.0 + 30.0 * draw_power)

	draw_polyline(PackedVector2Array([tip_a, pull, tip_b]), STRING_COLOR, 1.5, true)
	draw_arc(center, BOW_RADIUS, aim_angle - BOW_HALF_ANGLE, aim_angle + BOW_HALF_ANGLE, 16, bow_color, 4.0, true)

	if is_aiming:
		draw_set_transform(pull + dir * Arrow.LENGTH, aim_angle)
		Arrow.draw_shape(self)
		draw_set_transform(Vector2.ZERO)

	# Braços.
	draw_line(shoulder, hand, col, LINE_WIDTH - 1.0, true)
	var elbow := shoulder.lerp(pull, 0.5) + Vector2(0, 10)
	draw_polyline(PackedVector2Array([shoulder, elbow, pull]), col, LINE_WIDTH - 1.0, true)


func _draw_accessory(head: Vector2, f: float) -> void:
	match accessory:
		Accessory.BANDANA:
			draw_line(head + Vector2(-HEAD_RADIUS, -5), head + Vector2(HEAD_RADIUS, -5), accessory_color, 5.0, true)
			var knot := head + Vector2(-HEAD_RADIUS * f, -5)
			var wave := sin(_time * 6.0) * 3.0
			draw_line(knot, knot + Vector2(-14 * f, 4 + wave), accessory_color, 3.0, true)
			draw_line(knot, knot + Vector2(-11 * f, 10 + wave), accessory_color, 3.0, true)
		Accessory.HAT:
			draw_colored_polygon(PackedVector2Array([
				head + Vector2(-HEAD_RADIUS - 6, -8),
				head + Vector2(HEAD_RADIUS + 6, -8),
				head + Vector2(-4 * f, -HEAD_RADIUS - 18),
			]), accessory_color)
