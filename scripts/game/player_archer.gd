class_name PlayerArcher
extends Stickman
## Jogador: mira tocando e arrastando o dedo PARA TRÁS (como um estilingue)
## e dispara ao soltar. Atirar e segurar o arco tenso gasta estamina.

signal shoot_requested(spawn_position: Vector2, velocity: Vector2, def: Dictionary)

const MAX_STAMINA := 100.0
const STAMINA_REGEN := 15.0
const HOLD_DRAIN := 4.0

var min_speed := 450.0
var max_speed := 1300.0
var max_drag := 250.0
var dead_zone := 25.0
var cooldown := 0.28
var min_angle := -1.45
var max_angle := 1.15

var stamina := MAX_STAMINA
var input_enabled := true
var aim_guide: Node = null
## Função que diz se um ponto da tela está sobre um botão (para não mirar ali).
var ui_blocker: Callable = func(_p: Vector2) -> bool: return false

var _touch_index := -1
var _touch_start := Vector2.ZERO
var _finger := Vector2.ZERO
var _cooldown_left := 0.0
var _regen_delay := 0.0
var _tired_msg_cooldown := 0.0


func _init() -> void:
	hit_layer = Arrow.LAYER_PLAYER
	max_hp = 150.0
	head_multiplier = 2.5
	body_color = Color(0.12, 0.35, 0.85)
	accessory = Accessory.BANDANA
	accessory_color = Color(0.98, 0.78, 0.1)


func _process(delta: float) -> void:
	super(delta)
	if not alive:
		return
	nocked_def = GameData.get_arrow(GameData.selected_arrow)
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_regen_delay = maxf(_regen_delay - delta, 0.0)
	_tired_msg_cooldown = maxf(_tired_msg_cooldown - delta, 0.0)

	if is_aiming:
		if draw_power > 0.4:
			stamina = maxf(stamina - HOLD_DRAIN * draw_power * delta, 0.0)
		_update_aim(_finger)
	else:
		draw_power = move_toward(draw_power, 0.0, delta * 8.0)
		aim_angle = lerp_angle(aim_angle, get_idle_angle(), delta * 1.5)
		if _regen_delay <= 0.0:
			stamina = minf(stamina + STAMINA_REGEN * delta, MAX_STAMINA)
	tired = clampf(1.0 - stamina / 35.0, 0.0, 1.0)


func cancel_aim() -> void:
	_touch_index = -1
	is_aiming = false
	draw_power = 0.0
	if aim_guide:
		aim_guide.hide_aim()


func _unhandled_input(event: InputEvent) -> void:
	if not alive or not input_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			if ui_blocker.call(touch.position):
				return
			_touch_index = touch.index
			_touch_start = touch.position
			_finger = touch.position
			is_aiming = true
			Sfx.play("draw", -8.0)
			_update_aim(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			_release(touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_finger = drag.position
			_update_aim(drag.position)


func _update_aim(finger: Vector2) -> void:
	var pull := _touch_start - finger
	var valid := pull.length() >= dead_zone
	if valid:
		var wobble := sin(_time * 9.0) * 0.05 * tired
		aim_angle = clampf(pull.angle(), min_angle, max_angle) + wobble
		draw_power = clampf(pull.length() / max_drag, 0.0, 1.0)
	else:
		draw_power = 0.0
	if aim_guide:
		aim_guide.update_aim(_touch_start, finger, valid, get_arrow_spawn_global(), _launch_velocity())


func _release(finger: Vector2) -> void:
	var pull := _touch_start - finger
	var velocity := _launch_velocity()
	cancel_aim()
	if pull.length() < dead_zone or _cooldown_left > 0.0:
		return
	var def := GameData.get_arrow(GameData.selected_arrow)
	var cost: float = def["stamina"]
	if stamina < cost:
		# Cansado: o tiro sai fraco.
		velocity *= 0.55 + 0.45 * (stamina / cost)
		stamina = 0.0
		if _tired_msg_cooldown <= 0.0:
			_tired_msg_cooldown = 2.0
			Fx.text(to_global(Vector2(0, -210)), "CANSADO!", Color(1, 0.85, 0.3), 30, 1.0)
	else:
		stamina -= cost
	_cooldown_left = cooldown
	_regen_delay = 0.6
	play_shot_recoil()
	Sfx.play("shoot")
	shoot_requested.emit(get_arrow_spawn_global(), velocity, def)


func _launch_velocity() -> Vector2:
	return Vector2.from_angle(aim_angle) * lerpf(min_speed, max_speed, draw_power)
