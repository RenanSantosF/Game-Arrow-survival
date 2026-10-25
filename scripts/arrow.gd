class_name Arrow
extends Node2D
## Flecha com trajetória física simples (velocidade + gravidade).
##
## A cada quadro de física, a flecha lança um raio da posição anterior até a
## nova posição. Assim ela nunca "atravessa" um alvo, mesmo em alta velocidade.
## A origem (0, 0) da flecha é a PONTA; o corpo fica para trás, no eixo -X.

## Emitido quando a flecha acerta algo (chão ou personagem).
signal hit(collider: Object, hit_position: Vector2)

const GRAVITY := 980.0          ## Gravidade aplicada à flecha (pixels/s²).
const LENGTH := 50.0            ## Comprimento visual da flecha.
const PENETRATION := 14.0       ## Quanto a ponta entra no alvo ao acertar.
const STUCK_LIFETIME := 5.0     ## Tempo que a flecha fica presa antes de sumir.
const FADE_TIME := 0.6          ## Duração do desaparecimento gradual.
const MAX_FLIGHT_TIME := 6.0    ## Flechas perdidas são removidas após esse tempo.

const SHAFT_COLOR := Color(0.45, 0.28, 0.12)
const HEAD_COLOR := Color(0.75, 0.78, 0.82)
const FEATHER_COLOR := Color(0.96, 0.96, 0.96)

var velocity := Vector2.ZERO
var collision_mask: int = 1
var shooter: Node = null

var _stuck := false
var _timer := 0.0


## Deve ser chamado logo depois de a flecha ser adicionada à cena.
func launch(start_position: Vector2, initial_velocity: Vector2, mask: int, shooter_node: Node = null) -> void:
	global_position = start_position
	velocity = initial_velocity
	collision_mask = mask
	shooter = shooter_node
	global_rotation = velocity.angle()


func is_stuck() -> bool:
	return _stuck


func _physics_process(delta: float) -> void:
	_timer += delta

	if _stuck:
		if _timer > STUCK_LIFETIME:
			modulate.a = 1.0 - (_timer - STUCK_LIFETIME) / FADE_TIME
			if modulate.a <= 0.0:
				queue_free()
		return

	if _timer > MAX_FLIGHT_TIME:
		queue_free()
		return

	var from := global_position
	velocity.y += GRAVITY * delta
	var to := from + velocity * delta

	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := get_world_2d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		global_position = to
		global_rotation = velocity.angle()
	else:
		_stick(result)


func _stick(result: Dictionary) -> void:
	var collider: Object = result["collider"]
	var point: Vector2 = result["position"]
	var direction := velocity.normalized()
	var impact_velocity := velocity

	_stuck = true
	_timer = 0.0
	velocity = Vector2.ZERO
	global_position = point + direction * PENETRATION
	global_rotation = direction.angle()

	# Se acertou um personagem, a flecha vira "filha" da área atingida,
	# acompanhando o corpo quando ele se mexe.
	if collider is Area2D:
		reparent(collider as Node, true)

	var stickman := _find_stickman(collider)
	if stickman != null:
		stickman.take_hit(self, point, impact_velocity)

	hit.emit(collider, point)


func _find_stickman(collider: Object) -> Stickman:
	var node := collider as Node
	while node != null:
		if node is Stickman:
			return node as Stickman
		node = node.get_parent()
	return null


func _draw() -> void:
	draw_shape(self)


## Desenha a flecha em qualquer CanvasItem (também usada pelo arco do stickman).
static func draw_shape(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(-LENGTH, 0), Vector2(-6, 0), SHAFT_COLOR, 3.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(4, 0), Vector2(-9, -5), Vector2(-9, 5)
	]), HEAD_COLOR)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-LENGTH + 12, 0), Vector2(-LENGTH - 2, -7),
		Vector2(-LENGTH + 2, 0), Vector2(-LENGTH - 2, 7)
	]), FEATHER_COLOR)
