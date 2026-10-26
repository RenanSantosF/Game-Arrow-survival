class_name Stickman
extends Node2D
## Personagem stickman com arco, desenhado só com linhas e círculos.
##
## - A origem (0, 0) fica nos PÉS (em cima da plataforma).
## - Cabeça, tronco, braço e pernas têm áreas de colisão separadas (hit zones).
## - Ao morrer, vira um "ragdoll" que cai da plataforma e pode perder partes
##   ou até ser partido ao meio.
## - Pode carregar um ESCUDO na frente do corpo, que bloqueia flechas até quebrar.

signal died(stickman: Stickman, zone: String)
signal damaged(stickman: Stickman, amount: float, zone: String)

enum Accessory { NONE, BANDANA, HAT, HOOD, HELMET, CROWN }

const HEAD := Vector2(0, -152)
const HEAD_RADIUS := 16.0
const NECK := Vector2(0, -133)
const SHOULDER := Vector2(0, -122)
const HIP := Vector2(0, -70)
const LINE_WIDTH := 6.0
const ARM_LENGTH := 38.0
const BOW_RADIUS := 34.0
const BOW_HALF_ANGLE := 0.95
const STRING_COLOR := Color(0.95, 0.95, 0.95)

## Chance de desmembramento ao morrer, por região atingida.
const DECAPITATION_CHANCE := 0.6
const LIMB_CHANCE := 0.5
const TORSO_LIMB_CHANCE := 0.15
## Chance base de partir o corpo ao meio com um tiro no tronco (aumenta com a força).
const WAIST_CHANCE := 0.18
const SHIELD_OFFSET := Vector2(24, -80)
const SHIELD_SIZE := Vector2(22, 104)

var body_color := Color(0.1, 0.1, 0.1)
var bow_color := Color(0.45, 0.27, 0.1)
var accessory_color := Color(0.9, 0.2, 0.2)
var accessory: Accessory = Accessory.NONE
var facing_left := false
var hit_layer := Arrow.LAYER_ENEMY
var head_multiplier := 3.0
var eye_color := Color.WHITE
## Multiplica todo dano recebido (armadura do jogador).
var damage_taken_mult := 1.0
## Mostra uma barrinha de vida acima da cabeça quando ferido.
var show_hp_bar := false

var shield_hp := 0.0
var shield_max := 0.0
var shield_color := Color(0.55, 0.35, 0.18)

var max_hp := 100.0
var hp := 100.0
var alive := true
var invulnerable_time := 0.0
## 0..1: deixa a respiração ofegante (jogador cansado).
var tired := 0.0

var aim_angle := 0.0
var draw_power := 0.0
var is_aiming := false
var nocked_def: Dictionary = GameData.ARROWS[0]

var poison_time := 0.0
var burn_time := 0.0
var freeze_time := 0.0

## Onde criar o ragdoll e os efeitos ao morrer (definido pelo jogo).
var effects_parent: Node = null
## Plataforma onde o personagem está (o ragdoll colide com ela).
var platform: Node2D = null

var _time := 0.0
var _flash := 0.0
var _lean := 0.0
var _lean_velocity := 0.0
var _recoil := 0.0
var _dot_timer := 0.0
var _status_fx_timer := 0.0
var _areas := {}
var _shield_area: Area2D = null
var _shield_hit := 0.0
## Força do último impacto (0 = fraco, >1 = muito forte); define a chance de partir o corpo.
var _last_hit_power := 0.0


func _ready() -> void:
	aim_angle = get_idle_angle()
	hp = max_hp
	_build_hit_zones()


func get_facing() -> float:
	return -1.0 if facing_left else 1.0


func get_idle_angle() -> float:
	return PI + 0.2 if facing_left else -0.2


func can_be_hit() -> bool:
	return alive and invulnerable_time <= 0.0


func get_hit_rids() -> Array[RID]:
	var rids: Array[RID] = []
	for area in _areas.values():
		rids.append((area as Area2D).get_rid())
	if is_instance_valid(_shield_area):
		rids.append(_shield_area.get_rid())
	return rids


func has_shield() -> bool:
	return shield_hp > 0.0 and is_instance_valid(_shield_area)


func get_chest_global() -> Vector2:
	return to_global(Vector2(0, -105))


func get_head_global() -> Vector2:
	return to_global(HEAD)


func get_arrow_spawn_global() -> Vector2:
	return to_global(_shoulder() + Vector2.from_angle(aim_angle) * (ARM_LENGTH + 14.0))


# --- Zonas de acerto -------------------------------------------------------

func _build_hit_zones() -> void:
	var head := CircleShape2D.new()
	head.radius = HEAD_RADIUS + 3.0
	_make_zone("head", head, HEAD, 0.0)

	var torso := CapsuleShape2D.new()
	torso.radius = 12.0
	torso.height = absf(HIP.y - NECK.y) + 24.0
	_make_zone("torso", torso, (NECK + HIP) / 2.0, 0.0)

	var legs := RectangleShape2D.new()
	legs.size = Vector2(48, 70)
	_make_zone("leg", legs, Vector2(0, -36), 0.0)

	var arm := CapsuleShape2D.new()
	arm.radius = 8.0
	arm.height = ARM_LENGTH + 16.0
	_make_zone("arm", arm, Vector2(ARM_LENGTH / 2.0, 0), PI / 2.0)

	if shield_hp > 0.0:
		shield_max = maxf(shield_max, shield_hp)
		var rect := RectangleShape2D.new()
		rect.size = SHIELD_SIZE
		_make_zone("shield", rect, Vector2(SHIELD_OFFSET.x * get_facing(), SHIELD_OFFSET.y), 0.0)
		_shield_area = _areas["shield"]
		_areas.erase("shield")


func _make_zone(zone: String, shape: Shape2D, pos: Vector2, shape_rotation: float) -> void:
	var area := Area2D.new()
	area.name = "Zone_" + zone
	area.collision_layer = hit_layer
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("stickman", self)
	area.set_meta("zone", zone)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	if zone == "arm":
		area.position = SHOULDER
		cs.position = pos
	else:
		cs.position = pos
	cs.rotation = shape_rotation
	area.add_child(cs)
	add_child(area)
	_areas[zone] = area


# --- Dano --------------------------------------------------------------------

## Chamado pela flecha quando ela acerta uma das zonas deste personagem.
func receive_arrow(arrow: Arrow, zone: String, point: Vector2, arrow_velocity: Vector2) -> void:
	if not alive:
		return
	var dir := arrow_velocity.normalized()
	if zone == "shield":
		var shield_dmg := arrow.damage * (3.0 if arrow.def["id"] == "heavy" else 1.0)
		damage_shield(shield_dmg, point, dir)
		_lean_velocity += clampf(arrow_velocity.x * 0.0015, -2.0, 2.0)
		return
	var mult: float = head_multiplier if zone == "head" else GameData.ZONE_MULTIPLIER[zone]
	var dmg := arrow.damage * mult
	_last_hit_power = clampf(arrow_velocity.length() / 1300.0, 0.0, 1.2)
	if arrow.def["id"] == "heavy":
		_last_hit_power += 0.8

	Fx.blood(point, dir, 1.6 if zone == "head" else 1.0)
	Sfx.play("headshot" if zone == "head" else "hit")
	_flash = 1.0
	_lean_velocity += clampf(arrow_velocity.x * 0.0035 * (2.0 if arrow.def["id"] == "heavy" else 1.0), -6.0, 6.0) / scale.x

	match arrow.def["id"]:
		"poison":
			poison_time = 4.0
			Fx.burst(point, Vector2.UP, 10, Color(0.45, 1, 0.3), 160.0, 1.2, 4.0, 200.0, 0.7)
		"fire":
			burn_time = 3.0
			Sfx.play("fire")
			Fx.burst(point, Vector2.UP, 10, Color(1, 0.6, 0.1), 140.0, 1.0, 8.0, -150.0, 0.5, Fx.Kind.SMOKE)
		"ice":
			if hit_layer == Arrow.LAYER_ENEMY:
				freeze_time = 3.0
			Sfx.play("freeze")
			Fx.burst(point, Vector2.UP, 12, Color(0.75, 0.97, 1), 220.0, PI, 5.0, 300.0, 0.7, Fx.Kind.FLAKE)

	var hp_before := hp
	take_damage(dmg, zone, arrow_velocity, point)
	if arrow.from_player and Game.instance:
		Game.instance.on_player_arrow_hit(self, arrow, zone, minf(dmg, hp_before), point)


## Dano no escudo. Quando a resistência acaba, o escudo se quebra.
func damage_shield(amount: float, point: Vector2, dir: Vector2) -> void:
	if not has_shield():
		return
	shield_hp -= amount
	_shield_hit = 1.0
	Sfx.play("shield", -3.0)
	Fx.sparks(point, -dir, 8, shield_color.lightened(0.5))
	if shield_hp <= 0.0:
		break_shield()


func break_shield() -> void:
	shield_hp = 0.0
	if not is_instance_valid(_shield_area):
		return
	var center := _shield_area.to_global(Vector2(SHIELD_OFFSET.x * get_facing(), SHIELD_OFFSET.y))
	Fx.burst(center, Vector2.UP, 18, shield_color, 340.0, PI, 7.0, 1100.0, 0.9)
	Fx.burst(center, Vector2.UP, 8, shield_color.lightened(0.4), 420.0, PI, 3.0, 900.0, 0.5, Fx.Kind.SPARK)
	Fx.text(center + Vector2(0, -60), "ESCUDO QUEBRADO!", Color(0.85, 0.95, 1.0), 30, 1.0)
	Sfx.play("shield_break")
	_shield_area.queue_free()
	_shield_area = null


func take_damage(amount: float, zone: String, impulse: Vector2, point: Vector2) -> void:
	if not alive:
		return
	amount *= damage_taken_mult
	hp -= amount
	damaged.emit(self, amount, zone)
	if hp <= 0.0:
		hp = 0.0
		die(zone, impulse, point)


func die(zone: String, impulse: Vector2, point: Vector2, explosion := false) -> void:
	if not alive:
		return
	alive = false
	var severed: Array[String] = []
	if explosion:
		for part in ["head", "armF", "armB", "legL", "legR"]:
			if randf() < 0.45:
				severed.append(part)
		if randf() < 0.3:
			severed.append("waist")
	else:
		match zone:
			"head":
				if randf() < DECAPITATION_CHANCE:
					severed.append("head")
			"arm":
				if randf() < LIMB_CHANCE + 0.3 * _last_hit_power:
					severed.append("armF")
			"leg":
				if randf() < LIMB_CHANCE + 0.3 * _last_hit_power:
					severed.append("legL" if point.x < global_position.x else "legR")
			_:
				if randf() < WAIST_CHANCE + 0.3 * _last_hit_power:
					severed.append("waist")
				elif randf() < TORSO_LIMB_CHANCE:
					severed.append(["armB", "legL", "legR"].pick_random())

	if has_shield():
		# O escudo cai junto e se despedaça.
		break_shield()
	var parent := effects_parent if effects_parent else get_parent()
	var rag := Ragdoll.new()
	parent.add_child(rag)
	rag.setup_from(self, zone, impulse, severed)
	for area in _areas.values():
		for child in (area as Node).get_children():
			if child is Arrow:
				rag.attach_arrow(child)
	Sfx.play("death", -6.0)
	died.emit(self, zone)
	queue_free()


func _process_status(delta: float) -> void:
	poison_time = maxf(poison_time - delta, 0.0)
	burn_time = maxf(burn_time - delta, 0.0)
	freeze_time = maxf(freeze_time - delta, 0.0)
	if poison_time > 0.0 or burn_time > 0.0:
		_dot_timer -= delta
		if _dot_timer <= 0.0:
			_dot_timer = 0.5
			var dmg := 0.0
			if poison_time > 0.0:
				dmg += 3.5
			if burn_time > 0.0:
				dmg += 5.0
			_last_hit_power = 0.0
			Fx.text(to_global(Vector2(0, -190)), "-%d" % int(dmg), Color(0.6, 1, 0.4) if poison_time > 0.0 else Color(1, 0.7, 0.3), 26, 0.6)
			take_damage(dmg, "torso", Vector2(-get_facing() * 150.0, -100.0), get_chest_global())
	_status_fx_timer -= delta
	if _status_fx_timer <= 0.0:
		_status_fx_timer = 0.12
		if poison_time > 0.0:
			Fx.burst(to_global(Vector2(randf_range(-14, 14), randf_range(-150, -60))), Vector2.UP, 1, Color(0.45, 1, 0.3, 0.8), 60.0, 0.4, 4.0, -120.0, 0.6)
		if burn_time > 0.0:
			Fx.burst(to_global(Vector2(randf_range(-14, 14), randf_range(-150, -40))), Vector2.UP, 1, Color(1, 0.55, 0.1, 0.9), 70.0, 0.4, 9.0, -200.0, 0.45, Fx.Kind.SMOKE)


# --- Animação ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not alive:
		return
	_process_status(delta)
	if not alive:
		return
	var frozen := freeze_time > 0.0
	if not frozen:
		_time += delta * (1.0 + tired * 1.5)
	invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	modulate.a = 0.35 if invulnerable_time > 0.0 and fmod(invulnerable_time, 0.2) < 0.1 else 1.0
	_flash = maxf(_flash - delta * 5.0, 0.0)
	_recoil = maxf(_recoil - delta * 6.0, 0.0)
	_shield_hit = maxf(_shield_hit - delta * 6.0, 0.0)
	# Mola amortecida: o corpo balança com o impacto e volta ao lugar.
	_lean_velocity += (-_lean * 120.0 - _lean_velocity * 9.0) * delta
	_lean += _lean_velocity * delta
	rotation = _lean
	var arm_area: Area2D = _areas.get("arm")
	if arm_area:
		arm_area.position = _shoulder()
		arm_area.rotation = aim_angle
	queue_redraw()


func play_shot_recoil() -> void:
	_recoil = 1.0


func _breath() -> float:
	return sin(_time * 2.2) * (1.5 + tired * 2.5)


func _shoulder() -> Vector2:
	var dir := Vector2.from_angle(aim_angle)
	return SHOULDER + Vector2(0, _breath()) - dir * 4.0 * _recoil


## Posições (locais) das juntas, usadas para desenhar e para criar o ragdoll.
func get_pose() -> Dictionary:
	var f := get_facing()
	var breath := _breath()
	var shoulder := _shoulder()
	var dir := Vector2.from_angle(aim_angle)
	var hand := shoulder + dir * ARM_LENGTH
	var pull := hand - dir * (8.0 + 30.0 * draw_power)
	var knee_bend := 1.0 + breath * 0.3
	return {
		"head": HEAD + Vector2(-dir.x * 2.0 * _recoil, breath),
		"neck": NECK + Vector2(0, breath),
		"shoulder": shoulder,
		"hip": HIP,
		"hand_front": hand,
		"elbow_front": shoulder.lerp(hand, 0.5) + Vector2(0, 2),
		"hand_back": pull,
		"elbow_back": shoulder.lerp(pull, 0.5) + Vector2(0, 10),
		"knee_l": Vector2(-8 * f - knee_bend, -36),
		"foot_l": Vector2(-22 * f, 0),
		"knee_r": Vector2(14 * f + knee_bend, -36),
		"foot_r": Vector2(20 * f, 0),
		"bow_center": hand - dir * (BOW_RADIUS - 6.0),
	}


func current_color() -> Color:
	var col := body_color
	var pulse := 0.5 + 0.5 * sin(_time * 8.0)
	if poison_time > 0.0:
		col = col.lerp(Color(0.35, 0.9, 0.2), 0.35 + 0.2 * pulse)
	if burn_time > 0.0:
		col = col.lerp(Color(1.0, 0.45, 0.05), 0.35 + 0.25 * pulse)
	if freeze_time > 0.0:
		col = col.lerp(Color(0.6, 0.9, 1.0), 0.6)
	return col.lerp(Color.WHITE, _flash)


func _draw() -> void:
	var p := get_pose()
	var col := current_color()
	var f := get_facing()

	draw_polyline(PackedVector2Array([p["hip"], p["knee_l"], p["foot_l"]]), col, LINE_WIDTH, true)
	draw_polyline(PackedVector2Array([p["hip"], p["knee_r"], p["foot_r"]]), col, LINE_WIDTH, true)
	draw_line(p["hip"], p["neck"], col, LINE_WIDTH, true)
	draw_circle(p["head"], HEAD_RADIUS, col)
	if eye_color != Color.WHITE:
		# Olho brilhante (inimigos mais avançados).
		draw_circle(p["head"] + Vector2(7 * f, -3), 6.0, Color(eye_color, 0.3))
		draw_circle(p["head"] + Vector2(7 * f, -3), 3.4, eye_color)
	else:
		draw_circle(p["head"] + Vector2(7 * f, -3), 3.2, Color.WHITE)
		draw_circle(p["head"] + Vector2(8 * f, -3), 1.5, Color(0.05, 0.05, 0.1))
	draw_accessory(self, p["head"], f, accessory, accessory_color, _time)

	var dir := Vector2.from_angle(aim_angle)
	var center: Vector2 = p["bow_center"]
	var tip_a := center + Vector2.from_angle(aim_angle - BOW_HALF_ANGLE) * BOW_RADIUS
	var tip_b := center + Vector2.from_angle(aim_angle + BOW_HALF_ANGLE) * BOW_RADIUS
	draw_polyline(PackedVector2Array([tip_a, p["hand_back"], tip_b]), STRING_COLOR, 1.5, true)
	draw_arc(center, BOW_RADIUS, aim_angle - BOW_HALF_ANGLE, aim_angle + BOW_HALF_ANGLE, 16, bow_color, 4.5, true)

	if is_aiming:
		draw_set_transform(p["hand_back"] + dir * ArrowDraw.LENGTH, aim_angle)
		ArrowDraw.draw_arrow(self, nocked_def)
		draw_set_transform(Vector2.ZERO)

	draw_line(p["shoulder"], p["hand_front"], col, LINE_WIDTH - 1.0, true)
	draw_polyline(PackedVector2Array([p["shoulder"], p["elbow_back"], p["hand_back"]]), col, LINE_WIDTH - 1.0, true)

	if has_shield():
		_draw_shield(f)

	if show_hp_bar and hp < max_hp:
		var w := 60.0
		var bar := Rect2(-w / 2.0, -205, w, 8)
		draw_rect(bar.grow(2.0), Color(0.05, 0.05, 0.1, 0.8))
		draw_rect(Rect2(bar.position, Vector2(w * hp / max_hp, bar.size.y)), Color(0.95, 0.25, 0.25))

	if freeze_time > 0.0:
		var a := 0.35 + 0.1 * sin(Time.get_ticks_msec() * 0.01)
		draw_rect(Rect2(-34, -182, 68, 186), Color(0.7, 0.95, 1.0, a))
		draw_rect(Rect2(-34, -182, 68, 186), Color(1, 1, 1, 0.8), false, 2.0)
		draw_line(Vector2(-26, -170), Vector2(-10, -140), Color(1, 1, 1, 0.7), 2.0)


func _draw_shield(f: float) -> void:
	var c := Vector2(SHIELD_OFFSET.x * f, SHIELD_OFFSET.y)
	var hw := SHIELD_SIZE.x / 2.0 + 4.0
	var hh := SHIELD_SIZE.y / 2.0
	var shape := PackedVector2Array([
		c + Vector2(-hw, -hh), c + Vector2(hw, -hh), c + Vector2(hw, hh * 0.55),
		c + Vector2(0, hh + 10), c + Vector2(-hw, hh * 0.55), c + Vector2(-hw, -hh),
	])
	var col := shield_color.lerp(Color.WHITE, _shield_hit * 0.6)
	draw_colored_polygon(shape, col)
	draw_polyline(shape, col.lightened(0.35), 3.0, true)
	draw_line(c + Vector2(0, -hh + 8), c + Vector2(0, hh), col.darkened(0.3), 3.0, true)
	draw_circle(c + Vector2(0, -8), 5.0, col.lightened(0.5))
	var ratio := shield_hp / maxf(shield_max, 1.0)
	if ratio < 0.66:
		draw_line(c + Vector2(-hw + 3, -20), c + Vector2(-2, 0), Color(0, 0, 0, 0.6), 2.0)
	if ratio < 0.33:
		draw_line(c + Vector2(hw - 3, 18), c + Vector2(2, -6), Color(0, 0, 0, 0.6), 2.0)
		draw_line(c + Vector2(-3, 30), c + Vector2(4, 48), Color(0, 0, 0, 0.6), 2.0)


static func draw_accessory(canvas: CanvasItem, head: Vector2, f: float, kind: Accessory, color: Color, time: float, angle := 0.0, size := 1.0) -> void:
	canvas.draw_set_transform(head, angle, Vector2(size, size))
	var r := HEAD_RADIUS
	match kind:
		Accessory.BANDANA:
			canvas.draw_line(Vector2(-r, -5), Vector2(r, -5), color, 5.0, true)
			var knot := Vector2(-r * f, -5)
			var wave := sin(time * 6.0) * 3.0
			canvas.draw_line(knot, knot + Vector2(-15 * f, 4 + wave), color, 3.5, true)
			canvas.draw_line(knot, knot + Vector2(-12 * f, 11 + wave), color, 3.5, true)
		Accessory.HAT:
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-r - 7, -7), Vector2(r + 7, -7), Vector2(-4 * f, -r - 20),
			]), color)
		Accessory.HOOD:
			canvas.draw_arc(Vector2.ZERO, r + 3, PI * 0.9, PI * 2.1, 20, color, 6.0, true)
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-r * f, -6), Vector2(-(r + 14) * f, 10), Vector2(-(r - 2) * f, 12),
			]), color)
		Accessory.HELMET:
			canvas.draw_arc(Vector2(0, -2), r + 2, PI, TAU, 20, color, 9.0, true)
			canvas.draw_line(Vector2(6 * f, -6), Vector2(6 * f, 8), color, 3.0, true)
			canvas.draw_circle(Vector2(0, -r - 6), 3.5, color.lightened(0.3))
		Accessory.CROWN:
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-r + 2, -r + 4), Vector2(-r + 2, -r - 10), Vector2(-r * 0.4, -r - 2),
				Vector2(0, -r - 14), Vector2(r * 0.4, -r - 2), Vector2(r - 2, -r - 10), Vector2(r - 2, -r + 4),
			]), color)
	canvas.draw_set_transform(Vector2.ZERO)
