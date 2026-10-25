class_name Game
extends Node2D
## Partida de sobrevivência infinita.
##
## - O jogador fica numa plataforma flutuante à esquerda.
## - Inimigos surgem em plataformas dentro de uma ÁREA LIMITE à direita,
##   sempre afastados entre si. Mais inimigos aparecem conforme a dificuldade.
## - Frutas sobem do fundo: acerte-as para recuperar vida ou estamina.
## - A dificuldade cresce com os abates e com o tempo, sem fases.

const PLAYER_SPOT := Vector2(118, 840)
## Área onde os inimigos podem surgir (posição dos pés).
const ENEMY_AREA := Rect2(455, 430, 185, 560)
const MIN_ENEMY_DISTANCE := 165.0
const MAX_ARROWS := 45
const EXPLOSION_RADIUS := 125.0
const HEAL_AMOUNT := 40.0
const STAMINA_AMOUNT := 60.0
const COMBO_WINDOW := 2.5

const ENEMY_STYLES := [
	{"body": Color(0.82, 0.12, 0.12), "bow": Color(0.28, 0.16, 0.08), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.2, 0.2, 0.22)},
	{"body": Color(0.85, 0.42, 0.08), "bow": Color(0.35, 0.2, 0.1), "acc": Stickman.Accessory.BANDANA, "acc_color": Color(0.15, 0.15, 0.15)},
	{"body": Color(0.6, 0.1, 0.35), "bow": Color(0.3, 0.12, 0.2), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.95, 0.85, 0.3)},
]
const HUNTER_STYLES := [
	{"body": Color(0.45, 0.2, 0.7), "bow": Color(0.2, 0.1, 0.3), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.25, 0.1, 0.4)},
	{"body": Color(0.1, 0.5, 0.3), "bow": Color(0.15, 0.25, 0.1), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.05, 0.3, 0.15)},
]
const ELITE_STYLE := {"body": Color(0.18, 0.18, 0.22), "bow": Color(0.6, 0.1, 0.1), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.62, 0.65, 0.7)}

enum State { PLAYING, DYING, OVER }

static var instance: Game = null

var state := State.PLAYING
var score := 0
var kills := 0
var headshots := 0
var elapsed := 0.0
var revived := false

var player: PlayerArcher = null
var player_platform: FloatingPlatform = null
var enemies: Array[EnemyArcher] = []

var _world: Node2D
var _platforms: Node2D
var _bodies: Node2D
var _fruits: Node2D
var _arrows_root: Node2D
var _aim_guide: Node2D
var _hud: GameHud
var _overlay: CanvasLayer
var _arrows: Array = []
var _spawn_timer := 1.0
var _fruit_timer := 6.0
var _combo := 0
var _combo_timer := 0.0
var _shake := 0.0
var _game_end_registered := false
var _new_arrows: Array = []


func _ready() -> void:
	instance = self
	randomize()
	GameData.start_game()

	add_child(SkyBackground.new())
	_world = Node2D.new()
	add_child(_world)
	_platforms = _add_layer("Platforms")
	_bodies = _add_layer("Bodies")
	_fruits = _add_layer("Fruits")
	_arrows_root = _add_layer("Arrows")
	_world.add_child(Fx.new())
	_aim_guide = preload("res://scripts/game/aim_guide.gd").new()
	_world.add_child(_aim_guide)

	_hud = GameHud.new()
	add_child(_hud)
	_hud.pause_pressed.connect(_pause)
	_overlay = CanvasLayer.new()
	_overlay.layer = 20
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	_spawn_player(false)
	_hud.set_score(0, 0)
	Ads.rewarded_earned.connect(_on_rewarded_earned)


func _exit_tree() -> void:
	if instance == self:
		instance = null
	Engine.time_scale = 1.0


func _add_layer(layer_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = layer_name
	_world.add_child(n)
	return n


# --- Jogador -------------------------------------------------------------------

func _spawn_player(is_revive: bool) -> void:
	player_platform = FloatingPlatform.new()
	player_platform.grass_color = Color(0.3, 0.7, 0.35)
	_platforms.add_child(player_platform)
	player_platform.enter(PLAYER_SPOT, Vector2(-380, 0))

	player = PlayerArcher.new()
	player.effects_parent = _bodies
	player.platform = player_platform
	player.aim_guide = _aim_guide
	player.ui_blocker = _hud.blocks_point
	player_platform.add_child(player)
	player.shoot_requested.connect(_on_player_shoot)
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	if is_revive:
		player.hp = player.max_hp * 0.6
		player.invulnerable_time = 2.5
	_hud.hp_bar.set_value(player.hp, player.max_hp)
	_hud.stamina_bar.set_value(player.stamina, PlayerArcher.MAX_STAMINA)
	_hud.hp_bar.snap()
	_hud.stamina_bar.snap()


func _on_player_shoot(spawn: Vector2, velocity: Vector2, def: Dictionary) -> void:
	if def["id"] == "triple":
		for a in [-0.09, 0.0, 0.09]:
			spawn_arrow(spawn, velocity.rotated(a), def, def["damage"], true)
	else:
		spawn_arrow(spawn, velocity, def, def["damage"], true)


func _on_player_damaged(_p: Stickman, amount: float, zone: String) -> void:
	_hud.flash_damage()
	add_shake(9.0 if zone == "head" else 5.0)
	Sfx.play("hurt", -2.0)
	Fx.text(player.to_global(Vector2(0, -200)), "-%d" % int(amount), Color(1, 0.4, 0.35), 32, 0.8)
	Input.vibrate_handheld(60)


func _on_player_died(_p: Stickman, _zone: String) -> void:
	state = State.DYING
	_aim_guide.hide_aim()
	_hud.set_controls_visible(false)
	if is_instance_valid(player_platform):
		player_platform.crumble(0.3)
	add_shake(14.0)
	Engine.time_scale = 0.4
	var t := get_tree().create_timer(1.3, true, false, true)
	t.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
		_show_game_over())


# --- Flechas e explosões --------------------------------------------------------

func spawn_arrow(start: Vector2, velocity: Vector2, def: Dictionary, damage: float, is_player: bool) -> Arrow:
	var arrow := Arrow.new()
	_arrows_root.add_child(arrow)
	arrow.launch(start, velocity, def, damage, is_player)
	_arrows = _arrows.filter(func(a): return is_instance_valid(a))
	_arrows.append(arrow)
	while _arrows.size() > MAX_ARROWS:
		var oldest = _arrows.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	return arrow


func explode(point: Vector2, arrow: Arrow, collider: Object) -> void:
	Fx.explosion(point, EXPLOSION_RADIUS)
	Sfx.play("explosion")
	add_shake(14.0)
	var direct: Stickman = null
	var direct_zone := "torso"
	if collider is Area2D and collider.has_meta("stickman"):
		direct = collider.get_meta("stickman")
		direct_zone = collider.get_meta("zone")
	for e: EnemyArcher in enemies.duplicate():
		if not is_instance_valid(e) or not e.alive:
			continue
		var d := e.get_chest_global().distance_to(point)
		var dmg := 0.0
		if e == direct:
			var mult: float = e.head_multiplier if direct_zone == "head" else GameData.ZONE_MULTIPLIER[direct_zone]
			dmg += arrow.damage * mult
		if d < EXPLOSION_RADIUS + 40.0:
			dmg += 45.0 * (1.0 - d / (EXPLOSION_RADIUS + 40.0) * 0.6)
		if dmg <= 0.0:
			continue
		var impulse := (e.get_chest_global() - point).normalized() * 1100.0 + Vector2(0, -300)
		Fx.blood(e.get_chest_global(), impulse.normalized(), 1.2)
		if e.hp - dmg <= 0.0:
			e.hp = 0.0
			e.die(direct_zone if e == direct else "torso", impulse, point, true)
		else:
			e.take_damage(dmg, "torso", impulse, point)
	for f in _fruits.get_children():
		if f is Fruit and f.global_position.distance_to(point) < EXPLOSION_RADIUS:
			f.hit_by_arrow(arrow)


# --- Inimigos ------------------------------------------------------------------

func difficulty_level() -> float:
	return kills + elapsed / 18.0


func _max_enemies() -> int:
	var lv := difficulty_level()
	if lv < 4.0:
		return 1
	if lv < 12.0:
		return 2
	if lv < 26.0:
		return 3
	return 4


func _spawn_enemy() -> void:
	var spot := _find_enemy_spot()
	var lv := difficulty_level()
	var k := clampf(lv / 45.0, 0.0, 1.0)

	var platform := FloatingPlatform.new()
	platform.grass_color = Color(0.4, 0.62, 0.25).lerp(Color(0.55, 0.5, 0.3), randf())
	_platforms.add_child(platform)
	platform.enter(spot, Vector2(420, randf_range(-220, 220)))

	var e := EnemyArcher.new()
	var style: Dictionary = ENEMY_STYLES.pick_random()
	e.max_hp = 40.0 + minf(lv * 0.9, 45.0)
	e.aim_time = lerpf(2.3, 0.95, k) * randf_range(0.9, 1.1)
	e.shot_cooldown = lerpf(2.6, 1.1, k)
	e.aim_error = lerpf(110.0, 22.0, k)
	e.arrow_damage = 15.0 + minf(lv * 0.25, 11.0)
	e.score_value = 10
	if lv > 18.0 and randf() < 0.25:
		style = ELITE_STYLE
		e.max_hp *= 1.45
		e.head_multiplier = 2.0
		e.score_value = 25
	elif lv > 8.0 and randf() < 0.35:
		style = HUNTER_STYLES.pick_random()
		e.aim_time *= 0.85
		e.aim_error *= 0.8
		e.score_value = 15
	e.body_color = style["body"]
	e.bow_color = style["bow"]
	e.accessory = style["acc"]
	e.accessory_color = style["acc_color"]
	e.target = player
	e.platform = platform
	e.effects_parent = _bodies
	platform.add_child(e)
	e.died.connect(_on_enemy_died)
	enemies.append(e)
	Sfx.play("spawn", -6.0)
	var enemy_id := e.get_instance_id()
	get_tree().create_timer(0.9).timeout.connect(func() -> void:
		var obj := instance_from_id(enemy_id)
		if obj is EnemyArcher:
			obj.active = true)


## Escolhe um ponto dentro da área limite, longe dos outros inimigos.
func _find_enemy_spot() -> Vector2:
	var best := ENEMY_AREA.get_center()
	var best_dist := -1.0
	for i in 40:
		var p := Vector2(
			randf_range(ENEMY_AREA.position.x, ENEMY_AREA.end.x),
			randf_range(ENEMY_AREA.position.y, ENEMY_AREA.end.y))
		var nearest := INF
		for e in enemies:
			if is_instance_valid(e) and is_instance_valid(e.platform):
				nearest = minf(nearest, p.distance_to((e.platform as FloatingPlatform).base_position))
		if nearest >= MIN_ENEMY_DISTANCE:
			return p
		if nearest > best_dist:
			best_dist = nearest
			best = p
	return best


func _on_enemy_died(s: Stickman, zone: String) -> void:
	var e := s as EnemyArcher
	enemies.erase(e)
	kills += 1
	GameData.add_kill()
	var pos := e.to_global(Vector2(0, -170))
	var pts := e.score_value
	if zone == "head":
		headshots += 1
		pts += 15
		Fx.text(pos + Vector2(0, -50), "NA CABEÇA!", UiKit.GOLD, 44, 1.2)
		_slow_motion(0.3, 0.35)
	_combo = _combo + 1 if _combo_timer > 0.0 else 1
	_combo_timer = COMBO_WINDOW
	if _combo >= 2:
		pts += 10 * (_combo - 1)
		_hud.show_banner("COMBO x%d!" % _combo, Color(1, 0.6, 0.2), 1.0)
	score += pts
	Fx.text(pos, "+%d" % pts, Color.WHITE, 38, 1.0)
	add_shake(6.0)
	if is_instance_valid(e.platform):
		(e.platform as FloatingPlatform).crumble(0.6)
	_spawn_timer = maxf(_spawn_timer, 1.2)

	for def in GameData.check_unlocks(kills):
		_new_arrows.append(def)
		_hud.show_banner("NOVA FLECHA: %s!" % def["name"], Color(0.6, 1, 0.5), 2.5)
		_hud.rebuild_arrow_bar()
		Sfx.play("unlock")
	_hud.set_score(score, kills)


func _slow_motion(time_scale_value: float, seconds: float) -> void:
	if state != State.PLAYING:
		return
	Engine.time_scale = time_scale_value
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		if state == State.PLAYING:
			Engine.time_scale = 1.0)


# --- Frutas --------------------------------------------------------------------

func _spawn_fruit() -> void:
	var f := Fruit.new()
	var hp_ratio := player.hp / player.max_hp
	var st_ratio := player.stamina / PlayerArcher.MAX_STAMINA
	var p_health := clampf(0.5 + (st_ratio - hp_ratio) * 0.8, 0.2, 0.8)
	f.kind = Fruit.Kind.HEALTH if randf() < p_health else Fruit.Kind.STAMINA
	var bottom := get_viewport_rect().size.y + 50.0
	var apex := randf_range(330.0, 640.0)
	f.position = Vector2(randf_range(230.0, 520.0), bottom)
	f.velocity = Vector2(randf_range(-50.0, 50.0), -sqrt(2.0 * Fruit.GRAVITY * (bottom - apex)))
	_fruits.add_child(f)


func collect_fruit(f: Fruit) -> void:
	if not is_instance_valid(player) or not player.alive:
		return
	if f.kind == Fruit.Kind.HEALTH:
		player.hp = minf(player.hp + HEAL_AMOUNT, player.max_hp)
		Fx.text(f.global_position, "+%d VIDA" % int(HEAL_AMOUNT), Color(1, 0.45, 0.45), 36, 1.2)
	else:
		player.stamina = minf(player.stamina + STAMINA_AMOUNT, PlayerArcher.MAX_STAMINA)
		Fx.text(f.global_position, "+%d ESTAMINA" % int(STAMINA_AMOUNT), Color(1, 0.88, 0.3), 36, 1.2)
	score += 5
	_hud.set_score(score, kills)


# --- Laço principal ---------------------------------------------------------------

func _process(delta: float) -> void:
	_update_shake(delta)
	if state != State.PLAYING:
		return
	elapsed += delta
	_combo_timer = maxf(_combo_timer - delta, 0.0)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and enemies.size() < _max_enemies():
		_spawn_enemy()
		_spawn_timer = 1.4

	_fruit_timer -= delta
	if _fruit_timer <= 0.0:
		_spawn_fruit()
		_fruit_timer = randf_range(7.0, 12.0)

	if is_instance_valid(player):
		_hud.hp_bar.set_value(player.hp, player.max_hp)
		_hud.stamina_bar.set_value(player.stamina, PlayerArcher.MAX_STAMINA)


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _update_shake(delta: float) -> void:
	_shake = maxf(_shake - delta * 40.0, 0.0)
	_world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake if _shake > 0.0 else Vector2.ZERO


# --- Pausa, derrota e continuar ----------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING and not get_tree().paused:
		_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == State.PLAYING and not get_tree().paused:
			_pause()


func _pause() -> void:
	if get_tree().paused or state != State.PLAYING:
		return
	if is_instance_valid(player):
		player.cancel_aim()
	get_tree().paused = true
	var panel := PausePanel.new()
	_overlay.add_child(panel)
	panel.resume_pressed.connect(func() -> void:
		panel.queue_free()
		get_tree().paused = false)
	panel.menu_pressed.connect(func() -> void:
		_finish_run()
		UiKit.fade_to_scene(self, "res://scenes/menu.tscn"))


func _finish_run() -> bool:
	if not _game_end_registered:
		_game_end_registered = true
		Ads.register_game_end(elapsed)
	return GameData.submit_result(score, kills)


func _show_game_over() -> void:
	state = State.OVER
	var is_record := _finish_run() and score > 0
	var panel := GameOverPanel.new()
	panel.score = score
	panel.kills = kills
	panel.headshots = headshots
	panel.seconds = elapsed
	panel.is_record = is_record
	panel.can_revive = not revived and Ads.is_rewarded_ready()
	panel.new_arrows = _new_arrows
	_overlay.add_child(panel)
	Sfx.play("gameover")
	panel.revive_pressed.connect(func() -> void: Ads.show_rewarded())
	panel.retry_pressed.connect(func() -> void:
		Ads.maybe_show_interstitial(func() -> void: UiKit.fade_to_scene(self, "res://scenes/game.tscn")))
	panel.menu_pressed.connect(func() -> void:
		Ads.maybe_show_interstitial(func() -> void: UiKit.fade_to_scene(self, "res://scenes/menu.tscn")))


func _on_rewarded_earned() -> void:
	if state != State.OVER or revived:
		return
	revived = true
	for child in _overlay.get_children():
		child.queue_free()
	# Remove as flechas inimigas que ainda estão voando.
	for a in _arrows_root.get_children():
		if a is Arrow and not a.from_player and not a.is_stuck():
			a.queue_free()
	state = State.PLAYING
	_spawn_player(true)
	_hud.set_controls_visible(true)
	_hud.show_banner("DE VOLTA À LUTA!", Color(0.6, 1, 0.5), 1.5)
	for e in enemies:
		if is_instance_valid(e):
			e.target = player
