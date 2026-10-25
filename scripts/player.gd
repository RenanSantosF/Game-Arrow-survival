extends Stickman
## Jogador: mira tocando e arrastando o dedo; dispara ao soltar.
##
## Funciona como um estilingue: arraste o dedo PARA TRÁS (para longe do alvo).
## A flecha sai na direção oposta ao arraste, e a distância arrastada define a força.

## Pedido de disparo. A cena principal cria a flecha (ver main.gd).
signal shot_fired(spawn_position: Vector2, velocity: Vector2, mask: int, shooter: Node2D)

@export var min_speed := 450.0       ## Velocidade com o mínimo de força.
@export var max_speed := 1250.0      ## Velocidade com força máxima.
@export var max_drag := 260.0        ## Arraste (em pixels) para atingir força máxima.
@export var dead_zone := 25.0        ## Arrastes menores que isso cancelam o tiro.
@export var cooldown := 0.35         ## Tempo mínimo entre disparos (segundos).
@export_flags_2d_physics var arrow_mask: int = 5  ## O que as flechas do jogador acertam (mundo + inimigo).
@export var min_angle := -1.45       ## Limite da mira para cima (radianos).
@export var max_angle := 1.2         ## Limite da mira para baixo (radianos).

var can_shoot := true

var _touch_index := -1
var _touch_start := Vector2.ZERO
var _cooldown_left := 0.0

@onready var _aim_guide := $AimGuide


func _process(delta: float) -> void:
	super(delta)
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not is_aiming:
		draw_power = move_toward(draw_power, 0.0, delta * 8.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 and can_shoot:
			_touch_index = touch.index
			_touch_start = touch.position
			is_aiming = true
			_update_aim(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			_release(touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_aim(drag.position)


func _update_aim(finger_position: Vector2) -> void:
	var pull := _touch_start - finger_position
	var valid := pull.length() >= dead_zone
	if valid:
		aim_angle = clampf(pull.angle(), min_angle, max_angle)
		draw_power = clampf(pull.length() / max_drag, 0.0, 1.0)
	else:
		draw_power = 0.0
	_aim_guide.update_aim(_touch_start, finger_position, valid, get_arrow_spawn_global(), _launch_velocity())


func _release(finger_position: Vector2) -> void:
	var pull := _touch_start - finger_position
	_touch_index = -1
	is_aiming = false
	_aim_guide.hide_aim()
	if pull.length() >= dead_zone and _cooldown_left <= 0.0:
		_cooldown_left = cooldown
		shot_fired.emit(get_arrow_spawn_global(), _launch_velocity(), arrow_mask, self)
	draw_power = 0.0


func _launch_velocity() -> Vector2:
	return Vector2.from_angle(aim_angle) * lerpf(min_speed, max_speed, draw_power)
