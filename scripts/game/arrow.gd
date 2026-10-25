class_name Arrow
extends Node2D
## Flecha com trajetória física (velocidade + gravidade).
##
## A cada quadro de física a flecha lança um raio entre a posição anterior e a
## nova, então nunca atravessa um alvo, mesmo em alta velocidade.
## A origem é a PONTA da flecha.

const GRAVITY := 980.0
const PENETRATION := 14.0
const STUCK_LIFETIME := 4.0
const FADE_TIME := 0.5
const MAX_FLIGHT_TIME := 5.0

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_FRUIT := 32
const PLAYER_MASK := LAYER_WORLD | LAYER_ENEMY | LAYER_FRUIT
const ENEMY_MASK := LAYER_WORLD | LAYER_PLAYER

var def: Dictionary = GameData.ARROWS[0]
var velocity := Vector2.ZERO
var damage := 20.0
var from_player := false
var collision_mask := LAYER_WORLD
## Quando a flecha está presa num corpo caindo (ragdoll), ele controla a posição.
var held_by_ragdoll := false

var _exclude: Array[RID] = []
var _stuck := false
var _timer := 0.0
var _trail_timer := 0.0
var _burn_left := 0.0


func launch(start: Vector2, initial_velocity: Vector2, arrow_def: Dictionary, arrow_damage: float, is_player: bool) -> void:
	def = arrow_def
	damage = arrow_damage
	from_player = is_player
	collision_mask = PLAYER_MASK if is_player else ENEMY_MASK
	global_position = start
	velocity = initial_velocity
	global_rotation = velocity.angle()
	queue_redraw()


func is_stuck() -> bool:
	return _stuck


func _physics_process(delta: float) -> void:
	_timer += delta
	if _stuck:
		_process_stuck(delta)
		return
	if _timer > MAX_FLIGHT_TIME or global_position.y > 2600.0:
		queue_free()
		return

	var from := global_position
	velocity.y += GRAVITY * delta
	var to := from + velocity * delta

	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask, _exclude)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := get_world_2d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		var collider: Object = result["collider"]
		if collider is Area2D and collider.has_meta("fruit"):
			var fruit: Node = collider.get_meta("fruit")
			if is_instance_valid(fruit):
				fruit.hit_by_arrow(self)
			_exclude.append((collider as Area2D).get_rid())
		elif collider is Area2D and collider.has_meta("stickman"):
			var stickman: Stickman = collider.get_meta("stickman")
			if is_instance_valid(stickman) and stickman.can_be_hit():
				_stick(result)
				return
			# Alvo invulnerável (piscando): a flecha passa direto.
			for rid in stickman.get_hit_rids():
				_exclude.append(rid)
		else:
			_stick(result)
			return

	global_position = to
	global_rotation = velocity.angle()
	_emit_trail(delta)


func _emit_trail(delta: float) -> void:
	var trail: Color = def["trail"]
	if trail.a <= 0.0:
		return
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = 0.03
	var back := global_position - velocity.normalized() * 30.0
	match def["id"]:
		"fire":
			Fx.burst(back, Vector2.UP, 1, trail, 40.0, 0.6, 7.0, -120.0, 0.35, Fx.Kind.SMOKE)
		"ice":
			Fx.burst(back, Vector2.DOWN, 1, trail, 30.0, 1.0, 4.0, 100.0, 0.5, Fx.Kind.FLAKE)
		"explosive":
			Fx.burst(back, -velocity, 1, trail, 80.0, 0.5, 2.0, 0.0, 0.25, Fx.Kind.SPARK)
		_:
			Fx.burst(back, Vector2.DOWN, 1, trail, 30.0, 0.8, 3.0, 400.0, 0.5)


func _stick(result: Dictionary) -> void:
	var collider: Object = result["collider"]
	var point: Vector2 = result["position"]
	var direction := velocity.normalized()
	var impact_velocity := velocity

	if def["id"] == "explosive":
		if Game.instance:
			Game.instance.explode(point, self, collider)
		queue_free()
		return

	_stuck = true
	_timer = 0.0
	velocity = Vector2.ZERO
	global_position = point + direction * PENETRATION
	global_rotation = direction.angle()

	if collider is Node:
		reparent(collider as Node, true)

	if collider is Area2D and collider.has_meta("stickman"):
		var stickman: Stickman = collider.get_meta("stickman")
		stickman.receive_arrow(self, collider.get_meta("zone"), point, impact_velocity)
	else:
		Sfx.play("wood", -4.0)
		Fx.sparks(point, -direction, 5, Color(0.85, 0.7, 0.45))
		if def["id"] == "fire":
			_burn_left = 1.5


func _process_stuck(delta: float) -> void:
	if _burn_left > 0.0:
		_burn_left -= delta
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = 0.06
			Fx.burst(global_position, Vector2.UP, 1, Color(1, 0.55, 0.1, 0.9), 50.0, 0.5, 7.0, -150.0, 0.4, Fx.Kind.SMOKE)
	if _timer > STUCK_LIFETIME:
		modulate.a = 1.0 - (_timer - STUCK_LIFETIME) / FADE_TIME
		if modulate.a <= 0.0:
			queue_free()


func _draw() -> void:
	ArrowDraw.draw_arrow(self, def)
