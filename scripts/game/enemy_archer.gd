class_name EnemyArcher
extends Stickman
## Arqueiro inimigo: espera, puxa o arco mirando no jogador e dispara.
## A precisão, a velocidade e a vida dependem da dificuldade atual.

enum State { WAIT, AIM }

var target: Stickman = null
var active := false
var aim_time := 2.0
var shot_cooldown := 2.2
var aim_error := 90.0
var arrow_damage := 16.0
var score_value := 10

var _state := State.WAIT
var _timer := 1.5
var _target_angle := 0.0
var _shot_velocity := Vector2.ZERO


func _init() -> void:
	hit_layer = Arrow.LAYER_ENEMY
	facing_left = true


func _process(delta: float) -> void:
	super(delta)
	if not alive or not active or freeze_time > 0.0:
		return
	match _state:
		State.WAIT:
			aim_angle = lerp_angle(aim_angle, get_idle_angle(), delta * 3.0)
			draw_power = move_toward(draw_power, 0.0, delta * 6.0)
			_timer -= delta
			if _timer <= 0.0 and is_instance_valid(target) and target.alive:
				_begin_aim()
		State.AIM:
			_timer -= delta
			var progress := clampf(1.0 - _timer / aim_time, 0.0, 1.0)
			draw_power = ease(progress, 0.6)
			aim_angle = lerp_angle(aim_angle, _target_angle, minf(delta * 7.0, 1.0))
			if _timer <= 0.0:
				_shoot()


func _begin_aim() -> void:
	_state = State.AIM
	_timer = aim_time
	is_aiming = true
	var aim_point := target.get_chest_global()
	if randf() < 0.2:
		aim_point = target.get_head_global()
	aim_point += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * aim_error
	var start := to_global(SHOULDER) + (aim_point - to_global(SHOULDER)).normalized() * (ARM_LENGTH + 14.0)
	var dist := start.distance_to(aim_point)
	var t := clampf(dist / 850.0, 0.5, 1.0) * randf_range(0.9, 1.12)
	_shot_velocity = (aim_point - start) / t - Vector2(0, 0.5 * Arrow.GRAVITY * t)
	_target_angle = _shot_velocity.angle()


func _shoot() -> void:
	_state = State.WAIT
	_timer = shot_cooldown * randf_range(0.8, 1.25)
	is_aiming = false
	draw_power = 0.0
	play_shot_recoil()
	if not is_instance_valid(target) or not target.alive or Game.instance == null:
		return
	Sfx.play("shoot", -5.0)
	Game.instance.spawn_arrow(get_arrow_spawn_global(), _shot_velocity, GameData.ARROWS[0], arrow_damage, false)
