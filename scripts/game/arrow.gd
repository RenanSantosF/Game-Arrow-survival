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
## Velocidade de curva da flecha teleguiada (radianos por segundo).
const HOMING_TURN := 2.8
const HOMING_RANGE := 520.0

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
## Quantos inimigos a flecha perfurante ainda pode atravessar.
var _pierce_left := 0
var _master := false


func launch(start: Vector2, initial_velocity: Vector2, arrow_def: Dictionary, arrow_damage: float, is_player: bool) -> void:
	def = arrow_def
	damage = arrow_damage
	from_player = is_player
	collision_mask = PLAYER_MASK if is_player else ENEMY_MASK
	_master = is_player and GameData.is_master(def["id"])
	_pierce_left = 0
	if def["id"] == "pierce":
		_pierce_left = 3 if GameData.arrow_level("pierce") >= 3 else 2
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
	if def["id"] == "homing" and from_player and _timer > 0.12:
		_steer(delta)
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
				if _pierce_left <= 0:
					_stick(result)
					return
				# Perfurante: atravessa o escudo sem parar e fere o corpo sem ficar presa.
				var zone: String = collider.get_meta("zone")
				if zone == "shield":
					Sfx.play("shield", -6.0)
					Fx.sparks(result["position"], -velocity.normalized(), 6)
					_exclude.append((collider as Area2D).get_rid())
				else:
					var rids := stickman.get_hit_rids()
					stickman.receive_arrow(self, zone, result["position"], velocity)
					_pierce_left -= 1
					velocity *= 0.85
					_exclude.append_array(rids)
			elif is_instance_valid(stickman):
				# Alvo invulnerável (piscando): a flecha passa direto.
				_exclude.append_array(stickman.get_hit_rids())
			else:
				_exclude.append((collider as Area2D).get_rid())
		else:
			_stick(result)
			return

	global_position = to
	global_rotation = velocity.angle()
	_emit_trail(delta)


## Teleguiada: vira devagar na direção do inimigo vivo mais próximo à frente.
func _steer(delta: float) -> void:
	if Game.instance == null:
		return
	var best: Stickman = null
	var best_d := HOMING_RANGE
	var dir := velocity.normalized()
	for e in Game.instance.enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		var to_e: Vector2 = e.get_chest_global() - global_position
		var d := to_e.length()
		if d < best_d and dir.dot(to_e / maxf(d, 0.001)) > 0.2:
			best_d = d
			best = e
	if best == null:
		return
	var desired := (best.get_chest_global() - global_position).angle()
	var current := velocity.angle()
	var diff := wrapf(desired - current, -PI, PI)
	var max_turn := HOMING_TURN * GameData.arrow_effect("homing") * delta
	var turn := clampf(diff, -max_turn, max_turn)
	# Compensa a gravidade para a curva não "despencar".
	velocity = velocity.rotated(turn) - Vector2(0, GRAVITY * delta * 0.7)


func _emit_trail(delta: float) -> void:
	var trail: Color = def["trail"]
	if trail.a <= 0.0 and not _master:
		return
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = 0.03
	var back := global_position - velocity.normalized() * 30.0
	if _master:
		Fx.burst(back, -velocity, 1, Color(1, 0.85, 0.3, 0.9), 60.0, 0.6, 2.5, 0.0, 0.3, Fx.Kind.SPARK)
		if trail.a <= 0.0:
			return
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
	if from_player and _master:
		# Flecha MESTRE (nível máximo): brilho dourado.
		draw_circle(Vector2(-4, 0), 11.0, Color(1, 0.85, 0.3, 0.35))
		draw_line(Vector2(-ArrowDraw.LENGTH, 0), Vector2(0, 0), Color(1, 0.85, 0.3, 0.5), 7.0, true)
	ArrowDraw.draw_arrow(self, def)
