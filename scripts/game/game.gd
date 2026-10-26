class_name Game
extends Node2D
## Partida de sobrevivência infinita, organizada em ONDAS e ERAS.
##
## - O jogador fica numa plataforma flutuante à esquerda.
## - Cada onda tem alguns inimigos; ao limpar a onda, o jogador recupera um pouco
##   de vida e ganha moedas. A cada 5 ondas começa uma nova ERA: inimigos com novas
##   cores, acessórios e proteções (escudos, elmos) e o céu muda de cor.
## - Onda 3 de cada era termina com um MINI-CHEFE (capitão); a onda 5 é um CHEFE:
##   muito maior, mais forte, às vezes com escudo e disparando rajadas.
## - Depois da última era, as eras voltam com inimigos cada vez mais fortes.
## - Frutas sobem do fundo: acerte-as para recuperar vida ou estamina.

const PLAYER_SPOT := Vector2(118, 840)
## Área onde os inimigos podem surgir (posição dos pés).
const ENEMY_AREA := Rect2(455, 430, 185, 560)
const BOSS_SPOT := Vector2(610, 960)
## Espaço ocupado por um inimigo em tamanho normal, relativo aos pés: do arco
## (à esquerda) até a borda da ilhota, do topo do chapéu até as rochas embaixo.
const ENEMY_BOX := Rect2(-64, -194, 124, 276)
## Folga entre dois inimigos (inclui o balanço das ilhotas).
const BOX_MARGIN := 22.0
## Por quanto tempo o lugar de um inimigo morto fica reservado (corpo e ilhota caindo).
const DEAD_SPOT_TIME := 1.6
const MAX_ARROWS := 45
const EXPLOSION_RADIUS := 125.0
const HEAL_AMOUNT := 40.0
const STAMINA_AMOUNT := 60.0
const COMBO_WINDOW := 2.5
const WAVES_PER_ERA := 5
## Estamina recuperada ao acertar um inimigo, por região.
const HIT_STAMINA := {"head": 18.0, "belly": 10.0, "torso": 4.0, "arm": 2.0, "leg": 2.0}
const VAMPIRE_RATIO := 0.35
const LIGHTNING_RANGE := 380.0


## Eras de inimigos. Cada uma tem estilos comuns, chance de escudo, um capitão
## (mini-chefe) e um chefe. "size" do chefe é o tamanho total em relação ao normal.
const ERAS := [
	{
		"name": "Recrutas", "grass": Color(0.4, 0.62, 0.25),
		"styles": [
			{"body": Color(0.55, 0.55, 0.6), "bow": Color(0.4, 0.3, 0.2), "acc": Stickman.Accessory.NONE, "acc_color": Color.WHITE},
			{"body": Color(0.72, 0.58, 0.42), "bow": Color(0.35, 0.22, 0.1), "acc": Stickman.Accessory.NONE, "acc_color": Color.WHITE},
			{"body": Color(0.45, 0.55, 0.4), "bow": Color(0.3, 0.2, 0.1), "acc": Stickman.Accessory.NONE, "acc_color": Color.WHITE},
		],
		"shield_chance": 0.0, "shield_hp": 0.0, "shield_color": Color(0.55, 0.35, 0.18),
		"captain": {"name": "Sargento", "body": Color(0.38, 0.38, 0.46), "bow": Color(0.3, 0.2, 0.1), "acc": Stickman.Accessory.BANDANA, "acc_color": Color(0.85, 0.15, 0.15), "shield": 0.0},
		"boss": {"name": "GRANDALHÃO", "body": Color(0.5, 0.33, 0.22), "bow": Color(0.3, 0.18, 0.08), "acc": Stickman.Accessory.BANDANA, "acc_color": Color(0.95, 0.9, 0.8), "size": 1.7, "volley": 1, "shield": 0.0},
	},
	{
		"name": "Bandidos", "grass": Color(0.5, 0.6, 0.25),
		"styles": [
			{"body": Color(0.82, 0.12, 0.12), "bow": Color(0.28, 0.16, 0.08), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.2, 0.2, 0.22)},
			{"body": Color(0.85, 0.42, 0.08), "bow": Color(0.35, 0.2, 0.1), "acc": Stickman.Accessory.BANDANA, "acc_color": Color(0.15, 0.15, 0.15)},
			{"body": Color(0.6, 0.1, 0.35), "bow": Color(0.3, 0.12, 0.2), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.95, 0.85, 0.3)},
		],
		"shield_chance": 0.0, "shield_hp": 0.0, "shield_color": Color(0.55, 0.35, 0.18),
		"captain": {"name": "Capitão Bandido", "body": Color(0.55, 0.05, 0.05), "bow": Color(0.2, 0.1, 0.05), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.95, 0.75, 0.2), "shield": 0.0},
		"boss": {"name": "BARÃO BANDIDO", "body": Color(0.65, 0.04, 0.1), "bow": Color(0.95, 0.75, 0.2), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.1, 0.1, 0.12), "size": 1.75, "volley": 2, "shield": 0.0},
	},
	{
		"name": "Caçadores da Floresta", "grass": Color(0.25, 0.6, 0.3),
		"styles": [
			{"body": Color(0.45, 0.2, 0.7), "bow": Color(0.2, 0.1, 0.3), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.25, 0.1, 0.4)},
			{"body": Color(0.1, 0.5, 0.3), "bow": Color(0.15, 0.25, 0.1), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.05, 0.3, 0.15)},
			{"body": Color(0.05, 0.5, 0.55), "bow": Color(0.1, 0.25, 0.25), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.6, 0.4, 0.15)},
		],
		"shield_chance": 0.2, "shield_hp": 40.0, "shield_color": Color(0.55, 0.35, 0.18),
		"captain": {"name": "Mestre Caçador", "body": Color(0.08, 0.35, 0.18), "bow": Color(0.4, 0.25, 0.1), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.85, 0.7, 0.2), "shield": 60.0},
		"boss": {"name": "RAINHA DA FLORESTA", "body": Color(0.1, 0.45, 0.25), "bow": Color(0.95, 0.8, 0.3), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.9, 0.75, 0.2), "size": 1.8, "volley": 3, "shield": 0.0},
	},
	{
		"name": "Cavaleiros de Ferro", "grass": Color(0.45, 0.5, 0.35),
		"styles": [
			{"body": Color(0.4, 0.45, 0.55), "bow": Color(0.25, 0.2, 0.15), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.7, 0.72, 0.78)},
			{"body": Color(0.28, 0.33, 0.5), "bow": Color(0.25, 0.2, 0.15), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.6, 0.62, 0.7)},
			{"body": Color(0.5, 0.42, 0.35), "bow": Color(0.3, 0.2, 0.12), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.75, 0.6, 0.35)},
		],
		"shield_chance": 0.4, "shield_hp": 60.0, "shield_color": Color(0.55, 0.6, 0.68),
		"captain": {"name": "Comandante de Ferro", "body": Color(0.2, 0.24, 0.35), "bow": Color(0.6, 0.1, 0.1), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.8, 0.82, 0.88), "shield": 100.0},
		"boss": {"name": "COLOSSO DE FERRO", "body": Color(0.25, 0.28, 0.36), "bow": Color(0.6, 0.1, 0.1), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.78, 0.8, 0.88), "size": 1.95, "volley": 2, "shield": 160.0},
	},
	{
		"name": "Guarda Real", "grass": Color(0.35, 0.55, 0.45),
		"styles": [
			{"body": Color(0.15, 0.25, 0.75), "bow": Color(0.95, 0.75, 0.2), "acc": Stickman.Accessory.HAT, "acc_color": Color(0.95, 0.78, 0.2)},
			{"body": Color(0.85, 0.8, 0.65), "bow": Color(0.3, 0.2, 0.12), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.95, 0.75, 0.25)},
			{"body": Color(0.75, 0.15, 0.3), "bow": Color(0.95, 0.75, 0.2), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.9, 0.9, 0.95)},
		],
		"shield_chance": 0.45, "shield_hp": 70.0, "shield_color": Color(0.2, 0.3, 0.8),
		"captain": {"name": "Cavaleiro Dourado", "body": Color(0.8, 0.6, 0.15), "bow": Color(0.3, 0.15, 0.4), "acc": Stickman.Accessory.HELMET, "acc_color": Color(1.0, 0.85, 0.3), "shield": 110.0},
		"boss": {"name": "REI ARQUEIRO", "body": Color(0.45, 0.1, 0.55), "bow": Color(1.0, 0.8, 0.25), "acc": Stickman.Accessory.CROWN, "acc_color": Color(1.0, 0.82, 0.2), "size": 1.85, "volley": 3, "shield": 120.0},
	},
	{
		"name": "Sombras", "grass": Color(0.3, 0.3, 0.45),
		"styles": [
			{"body": Color(0.45, 0.2, 0.6), "bow": Color(0.1, 0.05, 0.15), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.12, 0.05, 0.18), "eye": Color(1.0, 0.2, 0.2)},
			{"body": Color(0.2, 0.45, 0.5), "bow": Color(0.05, 0.1, 0.12), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.05, 0.12, 0.15), "eye": Color(0.3, 1.0, 1.0)},
			{"body": Color(0.6, 0.6, 0.7), "bow": Color(0.1, 0.1, 0.12), "acc": Stickman.Accessory.HELMET, "acc_color": Color(0.15, 0.12, 0.2), "eye": Color(1.0, 0.85, 0.2)},
		],
		"shield_chance": 0.35, "shield_hp": 80.0, "shield_color": Color(0.3, 0.12, 0.38),
		"captain": {"name": "Assassino Sombrio", "body": Color(0.3, 0.1, 0.4), "bow": Color(0.8, 0.1, 0.5), "acc": Stickman.Accessory.HOOD, "acc_color": Color(0.08, 0.02, 0.12), "eye": Color(1.0, 0.2, 0.8), "shield": 90.0},
		"boss": {"name": "SENHOR DAS SOMBRAS", "body": Color(0.22, 0.08, 0.3), "bow": Color(0.7, 0.1, 0.9), "acc": Stickman.Accessory.CROWN, "acc_color": Color(0.7, 0.2, 0.95), "eye": Color(1.0, 0.15, 0.15), "size": 2.0, "volley": 4, "shield": 150.0},
	},
]

enum State { PLAYING, DYING, OVER }

static var instance: Game = null

var state := State.PLAYING
var score := 0
var kills := 0
var headshots := 0
var elapsed := 0.0
var revived := false
var wave := 0
var run_coins := 0

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
var _coins_banked := 0
var _new_arrows: Array = []
var _sky: SkyBackground
## Inimigos que ainda vão surgir nesta onda: "normal", "captain" ou "boss".
var _wave_queue: Array[String] = []
var _wave_active := false
var _wave_size := 0
var _wave_break := 1.2
var _boss: EnemyArcher = null
## Lugares de inimigos que acabaram de morrer: [caixa, tempo restante].
var _dead_spots: Array = []


func _ready() -> void:
	instance = self
	randomize()
	GameData.start_game()

	_sky = SkyBackground.new()
	add_child(_sky)
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
	_hud.set_coins(0)
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
	_hud.stamina_bar.set_value(player.stamina, player.max_stamina)
	_hud.hp_bar.snap()
	_hud.stamina_bar.snap()


func _on_player_shoot(spawn: Vector2, velocity: Vector2, def: Dictionary) -> void:
	var dmg: float = GameData.arrow_damage(def) * GameData.damage_mult()
	if def["id"] == "triple":
		for a in [-0.09, 0.0, 0.09]:
			spawn_arrow(spawn, velocity.rotated(a), def, dmg, true)
	else:
		spawn_arrow(spawn, velocity, def, dmg, true)


## Chamado quando uma flecha do jogador fere um inimigo (não conta escudo).
func on_player_arrow_hit(target: Stickman, arrow: Arrow, zone: String, dmg: float, point: Vector2) -> void:
	if not is_instance_valid(player) or not player.alive:
		return
	# Acertar recupera estamina; na cabeça recupera bem mais.
	var gain: float = HIT_STAMINA.get(zone, 0.0)
	if gain > 0.0:
		player.stamina = minf(player.stamina + gain, player.max_stamina)
		if zone == "head" or zone == "belly":
			Fx.text(player.to_global(Vector2(0, -230)), "+%d ESTAMINA" % int(gain), Color(1, 0.88, 0.3), 26, 0.9)
	if zone == "belly" and target.alive:
		Fx.text(point + Vector2(0, -30), "NA BARRIGA!", Color(1, 0.6, 0.3), 28, 0.8)
	var effect := GameData.arrow_effect(arrow.def["id"])
	match arrow.def["id"]:
		"vampire":
			var heal := dmg * VAMPIRE_RATIO * effect
			if heal >= 1.0:
				player.hp = minf(player.hp + heal, player.max_hp)
				Fx.text(player.to_global(Vector2(0, -260)), "+%d" % int(heal), Color(1, 0.35, 0.45), 28, 0.8)
				Fx.burst(point, (player.get_chest_global() - point).normalized(), 8, Color(0.9, 0.1, 0.25), 420.0, 0.3, 4.0, 0.0, 0.6)
		"lightning":
			_chain_lightning(target, point, arrow.damage * 0.6 * effect, 3 if GameData.arrow_level("lightning") >= 3 else 2)


## O raio salta do alvo para inimigos próximos (2, ou 3 com a flecha melhorada).
func _chain_lightning(source: Stickman, point: Vector2, dmg: float, jumps: int) -> void:
	Sfx.play("zap")
	var from := point
	var hit := [source]
	for i in jumps:
		var best: EnemyArcher = null
		var best_d := LIGHTNING_RANGE
		for e in enemies:
			if is_instance_valid(e) and e.alive and not hit.has(e):
				var d := from.distance_to(e.get_chest_global())
				if d < best_d:
					best_d = d
					best = e
		if best == null:
			return
		var to := best.get_chest_global()
		Fx.bolt(from, to)
		hit.append(best)
		best.take_damage(dmg, "torso", (to - from).normalized() * 500.0, to)
		from = to


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
	# A explosão cresce com o nível da flecha.
	var radius := EXPLOSION_RADIUS * (0.5 + 0.5 * GameData.arrow_effect("explosive"))
	Fx.explosion(point, radius)
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
		# A explosão destrói escudos com facilidade.
		if e.has_shield() and d < radius + 60.0:
			e.damage_shield(arrow.damage * (3.0 if e == direct and direct_zone == "shield" else 2.0), point, (e.get_chest_global() - point).normalized())
		if e == direct and direct_zone != "shield":
			dmg += arrow.damage * e.zone_multiplier(direct_zone)
		if d < radius + 40.0:
			dmg += 45.0 * (1.0 - d / (radius + 40.0) * 0.6)
		if dmg <= 0.0:
			continue
		var impulse := (e.get_chest_global() - point).normalized() * 1100.0 + Vector2(0, -300)
		Fx.blood(e.get_chest_global(), impulse.normalized(), 1.2)
		if e.hp - dmg <= 0.0:
			e.hp = 0.0
			e.die(direct_zone if e == direct and direct_zone != "shield" else "torso", impulse, point, true)
		else:
			e.take_damage(dmg, "torso", impulse, point)
	for f in _fruits.get_children():
		if f is Fruit and f.global_position.distance_to(point) < radius:
			f.hit_by_arrow(arrow)


# --- Ondas -------------------------------------------------------------------------

func era_index() -> int:
	return maxi(wave - 1, 0) / WAVES_PER_ERA


## Definição da era atual. Depois da última, as eras voltam (sem a dos recrutas).
func era_def() -> Dictionary:
	return ERAS[_era_def_index()]


func _era_def_index() -> int:
	var i := era_index()
	if i < ERAS.size():
		return i
	return 1 + (i - 1) % (ERAS.size() - 1)


func era_title() -> String:
	var title: String = era_def()["name"]
	var lap := era_index() / ERAS.size()
	if era_index() >= ERAS.size():
		lap = (era_index() - 1) / (ERAS.size() - 1)
	return title + (" +%d" % lap if lap > 0 else "")


func _wave_in_era() -> int:
	return (wave - 1) % WAVES_PER_ERA + 1


func is_boss_wave() -> bool:
	return _wave_in_era() == WAVES_PER_ERA


## 0..1: quão difícil está (precisão, velocidade). Chega ao máximo na onda 29.
func _skill() -> float:
	return clampf((wave - 1) / 28.0, 0.0, 1.0)


## Depois do máximo, a vida e o dano continuam subindo devagar (infinito).
func _overflow() -> float:
	return 1.0 + maxf(wave - 29, 0) * 0.03


func _max_enemies() -> int:
	if is_boss_wave():
		return 2
	if wave <= 2:
		return 1
	if wave <= 6:
		return 2
	if wave <= 14:
		return 3
	return 4


func _start_wave(n: int) -> void:
	var new_era := wave == 0 or (n - 1) / WAVES_PER_ERA != era_index()
	wave = n
	_wave_queue.clear()
	if is_boss_wave():
		_wave_queue.append("boss")
		for i in mini(1 + era_index(), 3):
			_wave_queue.append("normal")
	else:
		for i in mini(3 + int(n * 0.6), 12):
			_wave_queue.append("normal")
		if _wave_in_era() == 3:
			_wave_queue.append("captain")
	_wave_size = _wave_queue.size()
	_wave_active = true
	_spawn_timer = 0.6
	if new_era:
		_sky.set_theme(_era_def_index())
		_hud.show_banner("ERA %d: %s" % [era_index() + 1, era_title().to_upper()], Color(0.7, 0.9, 1.0), 2.0)
		Sfx.play("unlock", -4.0)
	elif is_boss_wave():
		_hud.show_banner("CHEFE: %s!" % era_def()["boss"]["name"], Color(1, 0.35, 0.3), 2.0)
		Sfx.play("boss")
		add_shake(10.0)
	else:
		_hud.show_banner("ONDA %d" % n, UiKit.GOLD, 1.2)
		Sfx.play("wave", -4.0)
	_update_wave_label()


func _complete_wave() -> void:
	_wave_active = false
	var boss_wave := is_boss_wave()
	var bonus := 2 + wave / 2 + (10 + era_index() * 5 if boss_wave else 0)
	run_coins += bonus
	_hud.set_coins(run_coins)
	if is_instance_valid(player) and player.alive:
		var heal := player.max_hp * (0.35 if boss_wave else 0.12)
		player.hp = minf(player.hp + heal, player.max_hp)
		player.stamina = minf(player.stamina + 30.0, player.max_stamina)
		Fx.text(player.to_global(Vector2(0, -230)), "+%d VIDA" % int(heal), Color(1, 0.45, 0.45), 30, 1.2)
	if boss_wave:
		_hud.show_banner("ERA VENCIDA!  +%d moedas" % bonus, Color(0.6, 1, 0.5), 2.0)
		Sfx.play("record", -4.0)
		_wave_break = 3.5
	else:
		_hud.show_banner("ONDA %d COMPLETA!  +%d moedas" % [wave, bonus], Color(0.6, 1, 0.5), 1.4)
		Sfx.play("wave", -4.0)
		_wave_break = 2.2
	_update_wave_label()


func _update_wave_label() -> void:
	var left := _wave_queue.size() + enemies.size()
	_hud.set_wave(wave, era_title(), left if _wave_active else 0, _wave_size)


# --- Inimigos ------------------------------------------------------------------

## Tamanho total (ilhota × personagem) de cada tipo de inimigo nesta era.
func _kind_size(kind: String) -> float:
	match kind:
		"boss":
			return float(era_def()["boss"]["size"])
		"captain":
			return 1.2 * 1.12
	return 1.0


## Cria o inimigo. Retorna false se não há espaço livre agora (tenta de novo depois).
func _spawn_enemy(kind: String) -> bool:
	var era := era_def()
	var k := _skill()
	var over := _overflow()
	var is_boss := kind == "boss"
	var is_captain := kind == "captain"
	var spot := _find_enemy_spot(_kind_size(kind), BOSS_SPOT if is_boss else Vector2.INF)
	if spot == Vector2.INF:
		return false

	var platform := FloatingPlatform.new()
	var grass: Color = era["grass"]
	platform.grass_color = grass.lerp(Color(0.55, 0.5, 0.3), randf() * 0.4)
	if is_boss:
		platform.size = 1.35
		platform.rock_color = Color(0.32, 0.26, 0.24)
	elif is_captain:
		platform.size = 1.12
	_platforms.add_child(platform)
	platform.enter(spot, Vector2(420, randf_range(-220, 220)))

	var e := EnemyArcher.new()
	e.rank = kind
	e.max_hp = (48.0 + minf(wave * 2.6, 84.0)) * over
	e.aim_time = lerpf(2.4, 1.0, k) * randf_range(0.9, 1.1)
	e.shot_cooldown = lerpf(2.8, 1.2, k)
	e.aim_error = lerpf(115.0, 26.0, k)
	e.arrow_damage = (10.0 + minf(wave * 0.35, 9.0)) * minf(over, 1.6)
	e.score_value = 10 + era_index() * 5
	e.coin_value = 1 + era_index() / 2
	var style: Dictionary = (era["styles"] as Array).pick_random()
	var shield_hp := 0.0
	if randf() < float(era["shield_chance"]):
		shield_hp = float(era["shield_hp"]) * over

	if is_captain:
		style = era["captain"]
		e.display_name = style["name"]
		e.scale = Vector2.ONE * 1.2
		e.max_hp *= 2.6
		e.aim_error *= 0.8
		e.head_chance = 0.35
		e.score_value = 40 + era_index() * 10
		e.coin_value = 5 + era_index()
		e.show_hp_bar = true
		shield_hp = float(style["shield"]) * over
	elif is_boss:
		style = era["boss"]
		e.display_name = style["name"]
		e.scale = Vector2.ONE * (float(style["size"]) / platform.size)
		e.max_hp = (200.0 + wave * 14.0) * over
		e.aim_time *= 1.15
		e.shot_cooldown *= 1.1
		e.aim_error *= 0.85
		e.volley = style["volley"]
		e.volley_spread = 0.08
		# Rajadas maiores têm flechas mais fracas, para o chefe não matar de uma vez.
		e.arrow_damage *= 1.3 / sqrt(e.volley)
		e.head_chance = 0.3 if e.volley == 1 else 0.15
		e.score_value = 150 + era_index() * 50
		e.coin_value = 20 + era_index() * 5
		shield_hp = float(style["shield"]) * over
		_boss = e
	if style["acc"] in [Stickman.Accessory.HELMET, Stickman.Accessory.CROWN]:
		# Elmo e coroa protegem a cabeça.
		e.head_multiplier = 2.0
	e.shield_hp = shield_hp
	e.shield_color = era["shield_color"]
	e.body_color = style["body"]
	e.bow_color = style["bow"]
	e.accessory = style["acc"]
	e.accessory_color = style["acc_color"]
	e.eye_color = style.get("eye", Color.WHITE)
	e.target = player
	e.platform = platform
	e.effects_parent = _bodies
	platform.add_child(e)
	e.died.connect(_on_enemy_died)
	enemies.append(e)
	if is_boss:
		_hud.show_boss(e.display_name)
		add_shake(12.0)
		Sfx.play("boss")
	elif is_captain:
		_hud.show_banner("MINI-CHEFE: %s" % e.display_name.to_upper(), Color(1, 0.6, 0.3), 1.4)
		Sfx.play("spawn", -2.0)
	else:
		Sfx.play("spawn", -6.0)
	var enemy_id := e.get_instance_id()
	get_tree().create_timer(1.3 if is_boss else 0.9).timeout.connect(func() -> void:
		var obj := instance_from_id(enemy_id)
		if obj is EnemyArcher:
			obj.active = true)
	return true


## Espaço ocupado por um inimigo com os pés em "feet" e tamanho "size".
static func enemy_box(feet: Vector2, size: float) -> Rect2:
	return Rect2(feet + ENEMY_BOX.position * size, ENEMY_BOX.size * size)


func _occupied_boxes() -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for e in enemies:
		if is_instance_valid(e) and is_instance_valid(e.platform):
			var platform := e.platform as FloatingPlatform
			boxes.append(enemy_box(platform.base_position, e.scale.x * platform.size))
	for d in _dead_spots:
		boxes.append(d[0])
	return boxes


## Escolhe um ponto dentro da área limite onde o inimigo não encosta em nenhum
## outro. Se "fixed" for dado, só testa esse ponto. Retorna Vector2.INF se não há espaço.
func _find_enemy_spot(size: float, fixed := Vector2.INF) -> Vector2:
	var boxes := _occupied_boxes()
	var candidates: Array[Vector2] = []
	if fixed != Vector2.INF:
		candidates.append(fixed)
	else:
		for i in 60:
			candidates.append(Vector2(
				randf_range(ENEMY_AREA.position.x, ENEMY_AREA.end.x),
				randf_range(ENEMY_AREA.position.y, ENEMY_AREA.end.y)))
		# Se o sorteio falhar, varre a área toda em grade (sobra pouco espaço livre).
		var grid: Array[Vector2] = []
		for x in range(int(ENEMY_AREA.position.x), int(ENEMY_AREA.end.x) + 1, 15):
			for y in range(int(ENEMY_AREA.position.y), int(ENEMY_AREA.end.y) + 1, 15):
				grid.append(Vector2(x, y))
		grid.shuffle()
		candidates.append_array(grid)
	for p in candidates:
		var box := enemy_box(p, size).grow(BOX_MARGIN)
		var free := true
		for b in boxes:
			if box.intersects(b):
				free = false
				break
		if free:
			return p
	return Vector2.INF


func _on_enemy_died(s: Stickman, zone: String) -> void:
	var e := s as EnemyArcher
	enemies.erase(e)
	if is_instance_valid(e.platform):
		var platform := e.platform as FloatingPlatform
		_dead_spots.append([enemy_box(platform.base_position, e.scale.x * platform.size), DEAD_SPOT_TIME])
	kills += 1
	GameData.add_kill()
	var pos := e.to_global(Vector2(0, -170))
	var pts := e.score_value
	var coins := e.coin_value
	if zone == "belly":
		pts += 8
		Fx.text(pos + Vector2(0, -50), "NA BARRIGA!", Color(1, 0.6, 0.3), 40, 1.0)
	if zone == "head":
		headshots += 1
		pts += 15
		coins += 1
		Fx.text(pos + Vector2(0, -50), "NA CABEÇA!", UiKit.GOLD, 44, 1.2)
		_slow_motion(0.3, 0.35)
	if e == _boss:
		_boss = null
		_hud.hide_boss()
		Fx.text(pos + Vector2(0, -110), "CHEFE DERROTADO!", Color(1, 0.5, 0.3), 46, 1.6)
		_slow_motion(0.25, 0.6)
		add_shake(16.0)
	_combo = _combo + 1 if _combo_timer > 0.0 else 1
	_combo_timer = COMBO_WINDOW
	if _combo >= 2:
		pts += 10 * (_combo - 1)
		_hud.show_banner("COMBO x%d!" % _combo, Color(1, 0.6, 0.2), 1.0)
	score += pts
	run_coins += coins
	Fx.text(pos, "+%d" % pts, Color.WHITE, 38, 1.0)
	Fx.text(pos + Vector2(0, 42), "+%d moeda%s" % [coins, "s" if coins > 1 else ""], UiKit.GOLD, 26, 1.0)
	add_shake(6.0)
	if is_instance_valid(e.platform):
		(e.platform as FloatingPlatform).crumble(0.6)
	_spawn_timer = maxf(_spawn_timer, 1.0)

	for def in GameData.check_unlocks(kills):
		_new_arrows.append(def)
		_hud.show_banner("NOVA FLECHA: %s!" % def["name"], Color(0.6, 1, 0.5), 2.5)
		_hud.rebuild_arrow_bar()
		Sfx.play("unlock")
	_hud.set_score(score, kills)
	_hud.set_coins(run_coins)
	_update_wave_label()


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
	var st_ratio := player.stamina / player.max_stamina
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
		player.stamina = minf(player.stamina + STAMINA_AMOUNT, player.max_stamina)
		Fx.text(f.global_position, "+%d ESTAMINA" % int(STAMINA_AMOUNT), Color(1, 0.88, 0.3), 36, 1.2)
	score += 5
	_hud.set_score(score, kills)


# --- Laço principal ---------------------------------------------------------------

func _process(delta: float) -> void:
	_update_shake(delta)
	if state != State.PLAYING:
		return
	elapsed += delta
	for i in range(_dead_spots.size() - 1, -1, -1):
		_dead_spots[i][1] -= delta
		if _dead_spots[i][1] <= 0.0:
			_dead_spots.remove_at(i)
	_combo_timer = maxf(_combo_timer - delta, 0.0)

	if _wave_active:
		_spawn_timer -= delta
		if not _wave_queue.is_empty() and _spawn_timer <= 0.0 and enemies.size() < _max_enemies():
			if _spawn_enemy(_wave_queue.front()):
				_wave_queue.pop_front()
				_spawn_timer = 1.3
				_update_wave_label()
			else:
				# Sem espaço livre: espera alguém sair em vez de sobrepor.
				_spawn_timer = 0.3
		elif _wave_queue.is_empty() and enemies.is_empty():
			_complete_wave()
	else:
		_wave_break -= delta
		if _wave_break <= 0.0:
			_start_wave(wave + 1)

	if is_instance_valid(_boss) and _boss.alive:
		_hud.set_boss_hp(_boss.hp / _boss.max_hp, _boss.shield_hp / maxf(_boss.shield_max, 1.0) if _boss.has_shield() else 0.0)

	_fruit_timer -= delta
	if _fruit_timer <= 0.0:
		_spawn_fruit()
		_fruit_timer = randf_range(7.0, 12.0)

	if is_instance_valid(player):
		_hud.hp_bar.set_value(player.hp, player.max_hp)
		_hud.stamina_bar.set_value(player.stamina, player.max_stamina)


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
	# Guarda as moedas ganhas (só a diferença, caso a partida continue após reviver).
	GameData.add_coins(run_coins - _coins_banked)
	_coins_banked = run_coins
	return GameData.submit_result(score, kills, wave)


func _show_game_over() -> void:
	state = State.OVER
	var is_record := _finish_run() and score > 0
	var panel := GameOverPanel.new()
	panel.score = score
	panel.kills = kills
	panel.headshots = headshots
	panel.wave = wave
	panel.era_name = era_title()
	panel.coins = run_coins
	panel.seconds = elapsed
	panel.is_record = is_record
	panel.can_revive = not revived and Ads.is_rewarded_ready()
	panel.new_arrows = _new_arrows
	_overlay.add_child(panel)
	Sfx.play("gameover")
	panel.revive_pressed.connect(func() -> void: Ads.show_rewarded())
	panel.upgrades_pressed.connect(func() -> void: _overlay.add_child(UpgradePanel.new()))
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
