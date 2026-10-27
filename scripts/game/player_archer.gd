class_name PlayerArcher
extends Stickman
## Jogador: mira tocando e arrastando o dedo PARA TRÁS (como um estilingue)
## e dispara ao soltar. Atirar e segurar o arco tenso gasta estamina: quanto
## mais forte o tiro, mais estamina ele gasta.

signal shoot_requested(spawn_position: Vector2, velocity: Vector2, def: Dictionary)

const STAMINA_REGEN := 14.0
const HOLD_DRAIN := 3.0
## Fração do custo da flecha gasta num tiro com o arco quase solto.
const MIN_COST_RATIO := 0.4

var min_speed := 450.0
var max_speed := 1300.0
var max_drag := 250.0
var dead_zone := 25.0
var cooldown := 0.28
var min_angle := -1.8
var max_angle := 1.5

var max_stamina := 100.0
var stamina := 100.0
var regen_mult := 1.0
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
	head_multiplier = 2.0
	belly_multiplier = 1.5
	apply_rank_look(self)
	max_hp = GameData.player_max_hp()
	max_stamina = GameData.player_max_stamina()
	stamina = max_stamina
	regen_mult = GameData.stamina_regen_mult()
	damage_taken_mult = GameData.damage_taken_mult()
	max_speed *= GameData.bow_mult()
	body_color = Color(0.12, 0.35, 0.85)
	accessory = Accessory.BANDANA
	accessory_color = Color(0.98, 0.78, 0.1)


## O visual do arqueiro evolui com as melhorias compradas.
static func apply_rank_look(s: Stickman) -> void:
	match GameData.player_rank_name():
		"Caçador":
			s.accessory = Accessory.HOOD
			s.accessory_color = Color(0.1, 0.45, 0.25)
		"Cavaleiro":
			s.accessory = Accessory.HELMET
			s.accessory_color = Color(0.8, 0.82, 0.9)
			s.bow_color = Color(0.55, 0.15, 0.1)
		"Rei Arqueiro":
			s.accessory = Accessory.CROWN
			s.accessory_color = Color(1.0, 0.82, 0.2)
			s.bow_color = Color(0.95, 0.75, 0.2)


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
			stamina = minf(stamina + STAMINA_REGEN * regen_mult * delta, max_stamina)
	tired = clampf(1.0 - stamina / 35.0, 0.0, 1.0)


func cancel_aim() -> void:
	_touch_index = -1
	is_aiming = false
	draw_power = 0.0
	if aim_guide:
		aim_guide.hide_aim()


## Começo da mira: só fora dos botões (_unhandled_input não recebe toques em botões).
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


## Arrastar e soltar: em _input, para a mira continuar mesmo quando o dedo passa
## por cima da barra de flechas ou de outro botão (que "engoliriam" o toque).
func _input(event: InputEvent) -> void:
	if _touch_index == -1 or not alive or not input_enabled:
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_finger = drag.position
			_update_aim(drag.position)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed and touch.index == _touch_index:
			_release(touch.position)
			get_viewport().set_input_as_handled()


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
	var cost := shot_cost(def, draw_power_from(pull))
	if stamina < cost:
		# Cansado: o tiro sai fraco.
		velocity *= 0.55 + 0.45 * (stamina / cost)
		stamina = 0.0
		if _tired_msg_cooldown <= 0.0:
			_tired_msg_cooldown = 2.0
			Fx.text(to_global(Vector2(0, -210)), tr("CANSADO!"), Color(1, 0.85, 0.3), 30, 1.0)
	else:
		stamina -= cost
	_cooldown_left = cooldown
	_regen_delay = 0.6
	play_shot_recoil()
	Sfx.play("shoot")
	shoot_requested.emit(get_arrow_spawn_global(), velocity, def)


## Estamina gasta por um tiro: depende da flecha e da força (0..1) do tiro.
static func shot_cost(def: Dictionary, power: float) -> float:
	return GameData.arrow_stamina(def) * lerpf(MIN_COST_RATIO, 1.0, power)


func draw_power_from(pull: Vector2) -> float:
	return clampf(pull.length() / max_drag, 0.0, 1.0)


func _launch_velocity() -> Vector2:
	return Vector2.from_angle(aim_angle) * lerpf(min_speed, max_speed, draw_power)
