class_name Ragdoll
extends Node2D
## Corpo "mole" do stickman morto, simulado com física de Verlet (pontos + bastões).
## É leve para o celular e permite separar cabeça e membros (desmembramento).

const GRAVITY := 1500.0
const ITERATIONS := 4
const MAX_AGE := 6.0
const BLEED_TIME := 1.4

# Índices dos pontos.
const P_HEAD := 0
const P_NECK := 1
const P_HIP := 2
const P_ELBOW_F := 3
const P_HAND_F := 4
const P_ELBOW_B := 5
const P_HAND_B := 6
const P_KNEE_L := 7
const P_FOOT_L := 8
const P_KNEE_R := 9
const P_FOOT_R := 10
const P_BOW_A := 11
const P_BOW_B := 12
const P_WAIST := 13

## Junta que se rompe em cada desmembramento: [ponto do corpo, ponto da parte].
const SEVER_JOINTS := {
	"head": [P_NECK, P_HEAD],
	"waist": [P_WAIST, P_HIP],
	"armF": [P_NECK, P_ELBOW_F],
	"armB": [P_NECK, P_ELBOW_B],
	"legL": [P_HIP, P_KNEE_L],
	"legR": [P_HIP, P_KNEE_R],
}

var _pos: PackedVector2Array = PackedVector2Array()
var _prev: PackedVector2Array = PackedVector2Array()
## Bastões: [a, b, comprimento, desenhar?]
var _sticks: Array = []
var _bleeding: Array = []
var _arrows: Array = []
var _color := Color.BLACK
var _bow_color := Color.BROWN
var _accessory := Stickman.Accessory.NONE
var _accessory_color := Color.WHITE
var _facing := 1.0
var _platform: Node2D = null
var _age := 0.0
var _bleed_timer := 0.0
var _head_angle := 0.0
var _head_spin := 0.0
var _head_attached := true
## Tamanho do personagem (chefes são maiores).
var _size := 1.0
var _draw_bow := true


## "missing" são partes já arrancadas em vida: não aparecem no corpo caindo.
func setup_from(s: Stickman, zone: String, impulse: Vector2, severed: Array, missing: Array = []) -> void:
	_color = s.current_color().darkened(0.1)
	_bow_color = s.bow_color
	_accessory = s.accessory
	_accessory_color = s.accessory_color
	_facing = s.get_facing()
	_platform = s.platform
	_size = s.global_transform.get_scale().x
	z_index = 2

	var pose := s.get_pose()
	var local_points := [
		pose["head"], pose["neck"], pose["hip"], pose["elbow_front"], pose["hand_front"],
		pose["elbow_back"], pose["hand_back"], pose["knee_l"], pose["foot_l"], pose["knee_r"], pose["foot_r"],
	]
	var bow_center: Vector2 = pose["bow_center"]
	local_points.append(bow_center + Vector2.from_angle(s.aim_angle - Stickman.BOW_HALF_ANGLE) * Stickman.BOW_RADIUS)
	local_points.append(bow_center + Vector2.from_angle(s.aim_angle + Stickman.BOW_HALF_ANGLE) * Stickman.BOW_RADIUS)
	local_points.append((pose["neck"] as Vector2).lerp(pose["hip"], 0.55))

	var dt := 1.0 / 60.0
	var base_v := impulse * 0.22 + Vector2(0, -120)
	for lp in local_points:
		var gp := s.to_global(lp)
		_pos.append(gp)
		var v := base_v + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		_prev.append(gp - v * dt)

	# Empurrão extra na parte atingida.
	var hit_points := {
		"head": [P_HEAD],
		"torso": [P_NECK, P_WAIST],
		"belly": [P_WAIST, P_HIP],
		"arm": [P_ELBOW_F, P_HAND_F],
		"leg": [P_KNEE_L, P_KNEE_R, P_FOOT_L, P_FOOT_R],
	}
	for i in hit_points.get(zone, [P_NECK]):
		_prev[i] -= impulse * 0.35 * dt

	_add_stick(P_HEAD, P_NECK, false)
	_add_stick(P_NECK, P_WAIST, true)
	_add_stick(P_WAIST, P_HIP, true)
	_add_stick(P_NECK, P_ELBOW_F, true)
	_add_stick(P_ELBOW_F, P_HAND_F, true)
	_add_stick(P_NECK, P_ELBOW_B, true)
	_add_stick(P_ELBOW_B, P_HAND_B, true)
	_add_stick(P_HIP, P_KNEE_L, true)
	_add_stick(P_KNEE_L, P_FOOT_L, true)
	_add_stick(P_HIP, P_KNEE_R, true)
	_add_stick(P_KNEE_R, P_FOOT_R, true)
	_add_stick(P_BOW_A, P_BOW_B, false)
	# Bastões invisíveis que mantêm a cabeça "em pé" e o tronco reto.
	_add_stick(P_HEAD, P_WAIST, false)
	_add_stick(P_NECK, P_HIP, false)

	_head_angle = (_pos[P_HEAD] - _pos[P_NECK]).angle()
	for part in missing:
		_remove_part(part)
	for part in severed:
		_sever(part, impulse)


func _add_stick(a: int, b: int, visible_line: bool) -> void:
	_sticks.append([a, b, _pos[a].distance_to(_pos[b]), visible_line])


## Tira do corpo uma parte que já tinha sido arrancada (sem desenhar nem sangrar de novo).
func _remove_part(part: String) -> void:
	var points: Array = []
	match part:
		"armF":
			points = [P_ELBOW_F, P_HAND_F]
			_draw_bow = false
		"legL":
			points = [P_KNEE_L, P_FOOT_L]
		"legR":
			points = [P_KNEE_R, P_FOOT_R]
	var i := _sticks.size() - 1
	while i >= 0:
		var st: Array = _sticks[i]
		if points.has(st[0]) or points.has(st[1]):
			_sticks.remove_at(i)
		i -= 1


func _sever(part: String, impulse: Vector2) -> void:
	var joint: Array = SEVER_JOINTS[part]
	var a: int = joint[0]
	var b: int = joint[1]
	var i := _sticks.size() - 1
	while i >= 0:
		var st: Array = _sticks[i]
		var connects: bool = (st[0] == a and st[1] == b) or (st[0] == b and st[1] == a)
		if part == "head" and (st[0] == P_HEAD or st[1] == P_HEAD):
			connects = true
		if part == "waist" and ((st[0] == P_NECK and st[1] == P_HIP) or (st[0] == P_HIP and st[1] == P_NECK)):
			connects = true
		if connects:
			_sticks.remove_at(i)
		i -= 1
	var dt := 1.0 / 60.0
	var fling := impulse.normalized() * 260.0 + Vector2(randf_range(-120, 120), -380)
	_prev[b] -= fling * dt
	if part == "head":
		_head_attached = false
		_head_spin = randf_range(-14, 14)
	if part == "waist":
		# As pernas caem, a parte de cima é lançada para trás.
		_prev[P_NECK] -= impulse.normalized() * 200.0 * dt + Vector2(0, -260) * dt
		Fx.text(_pos[a] + Vector2(0, -40), "PARTIDO!", Color(1, 0.55, 0.4), 34, 0.9)
	_bleeding.append([a, b])
	Fx.blood(_pos[a], Vector2.UP, 2.2)
	Sfx.play("headshot", -2.0, 0.2)


## Prende uma flecha (que estava no corpo vivo) neste ragdoll.
func attach_arrow(arrow: Arrow) -> void:
	var gp := arrow.global_position
	var best := -1
	var best_d := INF
	var best_t := 0.0
	for idx in _sticks.size():
		var st: Array = _sticks[idx]
		if not st[3]:
			continue
		var a: Vector2 = _pos[st[0]]
		var b: Vector2 = _pos[st[1]]
		var t := clampf((gp - a).dot(b - a) / maxf((b - a).length_squared(), 0.001), 0.0, 1.0)
		var d := gp.distance_to(a.lerp(b, t))
		if d < best_d:
			best_d = d
			best = idx
			best_t = t
	var head_d := gp.distance_to(_pos[P_HEAD])
	arrow.reparent(self, true)
	arrow.held_by_ragdoll = true
	if head_d < (Stickman.HEAD_RADIUS + 14.0) * _size or best == -1:
		var rel := (gp - _pos[P_HEAD]).rotated(-_head_angle)
		_arrows.append([arrow, -1, 0.0, rel, arrow.global_rotation - _head_angle])
	else:
		var st: Array = _sticks[best]
		var a: Vector2 = _pos[st[0]]
		var b: Vector2 = _pos[st[1]]
		var ang := (b - a).angle()
		var rel := (gp - a.lerp(b, best_t)).rotated(-ang)
		_arrows.append([arrow, best, best_t, rel, arrow.global_rotation - ang])


func _physics_process(delta: float) -> void:
	_age += delta
	var dt2 := delta * delta
	for i in _pos.size():
		var p := _pos[i]
		var v := (p - _prev[i]) * 0.995
		_prev[i] = p
		_pos[i] = p + v + Vector2(0, GRAVITY) * dt2

	for _k in ITERATIONS:
		for st in _sticks:
			var a: int = st[0]
			var b: int = st[1]
			var delta_v := _pos[b] - _pos[a]
			var d := delta_v.length()
			if d < 0.0001:
				continue
			var diff: float = (d - st[2]) / d * 0.5
			var offset := delta_v * diff
			_pos[a] += offset
			_pos[b] -= offset
		_collide_platform()

	if _head_attached:
		_head_angle = (_pos[P_HEAD] - _pos[P_NECK]).angle()
	else:
		_head_angle += _head_spin * delta

	_update_arrows()
	_update_bleeding(delta)

	var all_gone := true
	for p in _pos:
		if p.y < 2300.0:
			all_gone = false
			break
	if all_gone or _age > MAX_AGE:
		queue_free()
	elif _age > MAX_AGE - 0.6:
		modulate.a = (MAX_AGE - _age) / 0.6
	queue_redraw()


func _collide_platform() -> void:
	if not is_instance_valid(_platform) or not _platform.has_method("get_top_rect"):
		return
	var r: Rect2 = _platform.get_top_rect()
	for i in _pos.size():
		var p := _pos[i]
		if r.has_point(p):
			var prev := _prev[i]
			if prev.y <= r.position.y + 4.0:
				p.y = r.position.y
				# Atrito ao bater no chão da plataforma.
				_prev[i].x = lerpf(prev.x, p.x, 0.4)
			elif p.x < r.get_center().x:
				p.x = r.position.x
			else:
				p.x = r.end.x
			_pos[i] = p


func _update_arrows() -> void:
	var i := _arrows.size() - 1
	while i >= 0:
		var entry: Array = _arrows[i]
		var arrow = entry[0]
		if not is_instance_valid(arrow):
			_arrows.remove_at(i)
			i -= 1
			continue
		var stick_idx: int = entry[1]
		if stick_idx == -1 or stick_idx >= _sticks.size():
			arrow.global_position = _pos[P_HEAD] + (entry[3] as Vector2).rotated(_head_angle)
			arrow.global_rotation = _head_angle + entry[4]
		else:
			var st: Array = _sticks[stick_idx]
			var a: Vector2 = _pos[st[0]]
			var b: Vector2 = _pos[st[1]]
			var ang := (b - a).angle()
			arrow.global_position = a.lerp(b, entry[2]) + (entry[3] as Vector2).rotated(ang)
			arrow.global_rotation = ang + entry[4]
		i -= 1


func _update_bleeding(delta: float) -> void:
	if _bleeding.is_empty() or _age > BLEED_TIME:
		return
	_bleed_timer -= delta
	if _bleed_timer > 0.0:
		return
	_bleed_timer = 0.05
	for pair in _bleeding:
		var a: int = pair[0]
		var b: int = pair[1]
		var dir := (_pos[a] - _pos[b]).normalized()
		Fx.burst(_pos[a], dir if dir != Vector2.ZERO else Vector2.UP, 2, Color(0.75, 0.04, 0.06), 220.0, 0.35, 3.5)
		Fx.burst(_pos[b], -dir, 1, Color(0.7, 0.03, 0.05), 120.0, 0.5, 3.0)


func _draw() -> void:
	draw_set_transform(-global_position)
	for st in _sticks:
		if st[3]:
			draw_line(_pos[st[0]], _pos[st[1]], _color, Stickman.LINE_WIDTH * _size, true)
	# Arco caindo (curvado entre as duas pontas).
	if _draw_bow:
		var a := _pos[P_BOW_A]
		var b := _pos[P_BOW_B]
		var mid := a.lerp(b, 0.5) + (b - a).orthogonal().normalized() * -10.0 * _facing
		draw_polyline(PackedVector2Array([a, mid, b]), _bow_color, 4.5 * _size, true)
	# Cabeça.
	var head := _pos[P_HEAD]
	draw_circle(head, Stickman.HEAD_RADIUS * _size, _color)
	var eye := head + Vector2(7 * _facing, -3).rotated(_head_angle + PI / 2.0) * _size
	var e := 3.0 * _size
	draw_line(eye + Vector2(-e, -e), eye + Vector2(e, e), Color.WHITE, 2.0 * _size)
	draw_line(eye + Vector2(e, -e), eye + Vector2(-e, e), Color.WHITE, 2.0 * _size)
	draw_set_transform(Vector2.ZERO)
	Stickman.draw_accessory(self, head - global_position, _facing, _accessory, _accessory_color, _age, _head_angle + PI / 2.0, _size)
