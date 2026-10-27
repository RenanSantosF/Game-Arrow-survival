extends Node
## Dados do jogo: definições das flechas, recorde e progresso salvos no aparelho.
## Fica disponível em qualquer script pelo nome "GameData" (Autoload).

signal sound_changed(enabled: bool)

const SAVE_PATH := "user://save.cfg"

## Multiplicador de dano por região do corpo. A barriga é quase tão letal quanto a cabeça.
const ZONE_MULTIPLIER := {
	"head": 3.0,
	"belly": 2.5,
	"torso": 1.0,
	"arm": 0.6,
	"leg": 0.7,
}

## Flechas disponíveis. "unlock" = abates seguidos (sem morrer) para desbloquear.
## "stamina" = custo de um tiro com o arco TOTALMENTE puxado; tiros mais fracos
## gastam menos (veja PlayerArcher.shot_cost()).
const ARROWS := [
	{
		"id": "normal", "name": "Comum", "unlock": 0,
		"desc": "Confiável e leve.\nGasta pouca estamina.",
		"damage": 25.0, "stamina": 7.0,
		"shaft": Color(0.45, 0.28, 0.12), "head": Color(0.78, 0.8, 0.85), "fletch": Color(0.96, 0.96, 0.96),
		"trail": Color(1, 1, 1, 0.0),
	},
	{
		"id": "poison", "name": "Veneno", "unlock": 8,
		"desc": "Envenena o alvo:\ndano contínuo por 4s.",
		"damage": 18.0, "stamina": 8.0,
		"shaft": Color(0.2, 0.35, 0.15), "head": Color(0.45, 0.95, 0.25), "fletch": Color(0.6, 1.0, 0.4),
		"trail": Color(0.45, 0.95, 0.25, 0.9),
	},
	{
		"id": "fire", "name": "Fogo", "unlock": 16,
		"desc": "Incendeia o alvo:\nqueima por 3s.",
		"damage": 22.0, "stamina": 9.0,
		"shaft": Color(0.35, 0.15, 0.08), "head": Color(1.0, 0.55, 0.1), "fletch": Color(1.0, 0.85, 0.2),
		"trail": Color(1.0, 0.5, 0.1, 0.95),
	},
	{
		"id": "ice", "name": "Gelo", "unlock": 25,
		"desc": "Congela o inimigo:\nele para de atirar por 3s.",
		"damage": 18.0, "stamina": 9.0,
		"shaft": Color(0.6, 0.75, 0.9), "head": Color(0.6, 0.95, 1.0), "fletch": Color(0.85, 0.97, 1.0),
		"trail": Color(0.7, 0.95, 1.0, 0.9),
	},
	{
		"id": "pierce", "name": "Perfurante", "unlock": 35,
		"desc": "Atravessa escudos e\naté 2 inimigos.",
		"damage": 28.0, "stamina": 10.0,
		"shaft": Color(0.3, 0.3, 0.35), "head": Color(0.92, 0.95, 1.0), "fletch": Color(0.4, 0.75, 1.0),
		"trail": Color(0.75, 0.9, 1.0, 0.7),
	},
	{
		"id": "vampire", "name": "Vampira", "unlock": 45,
		"desc": "Recupera sua vida\ncom o dano causado.",
		"damage": 22.0, "stamina": 10.0,
		"shaft": Color(0.25, 0.05, 0.1), "head": Color(0.85, 0.05, 0.2), "fletch": Color(0.55, 0.05, 0.15),
		"trail": Color(0.9, 0.1, 0.25, 0.85),
	},
	{
		"id": "explosive", "name": "Explosiva", "unlock": 55,
		"desc": "Explode no impacto e\nquebra escudos.",
		"damage": 30.0, "stamina": 14.0,
		"shaft": Color(0.25, 0.25, 0.25), "head": Color(0.95, 0.2, 0.15), "fletch": Color(1.0, 0.75, 0.1),
		"trail": Color(1.0, 0.8, 0.3, 0.8),
	},
	{
		"id": "lightning", "name": "Raio", "unlock": 70,
		"desc": "O raio salta para\naté 2 inimigos próximos.",
		"damage": 24.0, "stamina": 12.0,
		"shaft": Color(0.15, 0.2, 0.45), "head": Color(1.0, 0.95, 0.35), "fletch": Color(0.55, 0.8, 1.0),
		"trail": Color(1.0, 0.95, 0.45, 0.9),
	},
	{
		"id": "triple", "name": "Tripla", "unlock": 85,
		"desc": "Dispara três flechas\nde uma vez.",
		"damage": 20.0, "stamina": 15.0,
		"shaft": Color(0.5, 0.3, 0.6), "head": Color(0.85, 0.7, 1.0), "fletch": Color(0.95, 0.85, 1.0),
		"trail": Color(0.85, 0.7, 1.0, 0.8),
	},
	{
		"id": "homing", "name": "Teleguiada", "unlock": 100,
		"desc": "Faz curva sozinha\natrás do inimigo.",
		"damage": 22.0, "stamina": 11.0,
		"shaft": Color(0.1, 0.4, 0.4), "head": Color(0.3, 1.0, 0.85), "fletch": Color(0.6, 1.0, 0.9),
		"trail": Color(0.3, 1.0, 0.85, 0.85),
	},
	{
		"id": "heavy", "name": "Arpão", "unlock": 120,
		"desc": "Dano enorme, parte\no corpo e escudos.",
		"damage": 60.0, "stamina": 18.0,
		"shaft": Color(0.3, 0.2, 0.12), "head": Color(0.55, 0.55, 0.6), "fletch": Color(0.9, 0.3, 0.2),
		"trail": Color(0.6, 0.6, 0.65, 0.5),
	},
]

## Experiência necessária para CADA nível da flecha (além das moedas).
## Acerto = 1, na cabeça/barriga = 3, abate = +2.
const ARROW_XP_LEVELS := [12, 30, 60, 100, 160]
## Nível máximo: a flecha vira MESTRE e ganha +10% de dano extra.
const MASTER_BONUS := 0.1
## Melhorias do arqueiro exigem também chegar a certas ondas (por nível).
const UPGRADE_WAVE_REQ := [0, 3, 6, 10, 15, 20]
## Moedas grátis por anúncio premiado no Arsenal (até FREE_COIN_ADS_PER_DAY por dia).
const FREE_COIN_REWARD := 40
const FREE_COIN_ADS_PER_DAY := 3

## Espaços de flecha: começa com 2; o preço de cada espaço extra (3º, 4º e 5º) é alto.
const START_SLOTS := 2
const SLOT_COSTS := [400, 1000, 2200]

## Melhorias do personagem, compradas no menu com moedas.
## "cost" tem um preço por nível (o tamanho da lista é o nível máximo).
const UPGRADES := [
	{"id": "hp", "name": "Vida", "desc": "+20 de vida máxima", "cost": [25, 50, 90, 140, 200, 280]},
	{"id": "damage", "name": "Força", "desc": "+10% de dano das flechas", "cost": [30, 60, 100, 160, 240, 340]},
	{"id": "stamina", "name": "Fôlego", "desc": "+15 de estamina máxima", "cost": [20, 45, 80, 125, 180]},
	{"id": "regen", "name": "Recuperação", "desc": "+20% de estamina por segundo", "cost": [20, 45, 80, 125, 180]},
	{"id": "armor", "name": "Armadura", "desc": "-7% de dano recebido", "cost": [35, 70, 120, 180, 260]},
	{"id": "bow", "name": "Arco Longo", "desc": "+6% de força do tiro", "cost": [25, 55, 95, 150]},
]

var best_score := 0
var best_kills := 0
var best_wave := 0
var total_kills := 0
var games_played := 0
var sessions := 0
var sound_enabled := true
var selected_arrow := "normal"
## Flechas levadas para a partida (a Comum sempre ocupa o primeiro espaço).
var loadout: Array = ["normal"]
## Quantos espaços de flecha o jogador tem (compra mais na tela de flechas).
var arrow_slots := START_SLOTS
var unlocked: Array = ["normal"]
var coins := 0
var upgrades := {}
## Nível de melhoria de cada flecha (0 = sem melhoria).
var arrow_levels := {}
## Experiência de cada flecha: ganha usando (acertos e abates com ela).
var arrow_xp := {}
## Anúncios premiados de "moedas grátis" vistos hoje (limite diário).
var free_coin_ads := 0
var free_coin_day := ""


func _ready() -> void:
	load_data()
	sessions += 1
	save_data()
	_apply_sound()


# --- Melhorias -------------------------------------------------------------------

func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func get_upgrade(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}


## Preço do próximo nível, ou -1 se já está no máximo.
func upgrade_cost(id: String) -> int:
	var costs: Array = get_upgrade(id)["cost"]
	var lv := upgrade_level(id)
	return -1 if lv >= costs.size() else int(costs[lv])


## Onda que precisa ter alcançado para comprar o próximo nível (0 = sem exigência).
func upgrade_wave_needed(id: String) -> int:
	var lv := upgrade_level(id)
	return int(UPGRADE_WAVE_REQ[mini(lv, UPGRADE_WAVE_REQ.size() - 1)])


func upgrade_wave_ok(id: String) -> bool:
	return best_wave >= upgrade_wave_needed(id)


func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0 or coins < cost or not upgrade_wave_ok(id):
		return false
	coins -= cost
	upgrades[id] = upgrade_level(id) + 1
	save_data()
	return true


func add_coins(amount: int) -> void:
	coins += maxi(amount, 0)
	save_data()


func player_max_hp() -> float:
	return 150.0 + 20.0 * upgrade_level("hp")


func damage_mult() -> float:
	return 1.0 + 0.1 * upgrade_level("damage")


func player_max_stamina() -> float:
	return 100.0 + 15.0 * upgrade_level("stamina")


func stamina_regen_mult() -> float:
	return 1.0 + 0.2 * upgrade_level("regen")


func damage_taken_mult() -> float:
	return 1.0 - 0.07 * upgrade_level("armor")


func bow_mult() -> float:
	return 1.0 + 0.06 * upgrade_level("bow")


## Soma dos níveis de melhoria do personagem (define o visual do arqueiro).
func total_upgrade_levels() -> int:
	var total := 0
	for u in UPGRADES:
		total += upgrade_level(u["id"])
	return total


## Título do arqueiro conforme as melhorias compradas.
func player_rank_name() -> String:
	var t := total_upgrade_levels()
	if t >= 24:
		return "Rei Arqueiro"
	if t >= 14:
		return "Cavaleiro"
	if t >= 6:
		return "Caçador"
	return "Aprendiz"


# --- Flechas ----------------------------------------------------------------------

const ARROW_MAX_LEVEL := 5


func arrow_level(id: String) -> int:
	return int(arrow_levels.get(id, 0))


## Preço do próximo nível de uma flecha, ou -1 se já está no máximo.
func arrow_upgrade_cost(id: String) -> int:
	var lv := arrow_level(id)
	if lv >= ARROW_MAX_LEVEL:
		return -1
	var base := 20 + int(get_arrow(id)["unlock"]) / 2
	return base * (lv + 1)


func get_arrow_xp(id: String) -> int:
	return int(arrow_xp.get(id, 0))


## Experiência necessária para o próximo nível (-1 se já é mestre).
func arrow_xp_needed(id: String) -> int:
	var lv := arrow_level(id)
	return -1 if lv >= ARROW_MAX_LEVEL else int(ARROW_XP_LEVELS[lv])


func arrow_xp_ok(id: String) -> bool:
	var need := arrow_xp_needed(id)
	return need >= 0 and get_arrow_xp(id) >= need


func is_master(id: String) -> bool:
	return arrow_level(id) >= ARROW_MAX_LEVEL


## Soma experiência à flecha. Retorna true se ela acabou de ficar pronta para melhorar.
func add_arrow_xp(id: String, amount: int) -> bool:
	var need := arrow_xp_needed(id)
	var before := get_arrow_xp(id)
	if need < 0:
		return false
	arrow_xp[id] = mini(before + amount, need)
	return before < need and int(arrow_xp[id]) >= need


func buy_arrow_upgrade(id: String) -> bool:
	var cost := arrow_upgrade_cost(id)
	if not is_unlocked(id) or cost < 0 or coins < cost or not arrow_xp_ok(id):
		return false
	coins -= cost
	arrow_levels[id] = arrow_level(id) + 1
	# A experiência recomeça para o próximo nível.
	arrow_xp[id] = 0
	save_data()
	return true


## Pode ganhar moedas grátis com anúncio hoje?
func free_coin_ads_left() -> int:
	var today := Time.get_date_string_from_system()
	if free_coin_day != today:
		free_coin_day = today
		free_coin_ads = 0
	return FREE_COIN_ADS_PER_DAY - free_coin_ads


func claim_free_coins() -> void:
	free_coin_ads_left()
	free_coin_ads += 1
	add_coins(FREE_COIN_REWARD)


## Preço para comprar uma flecha ainda bloqueada (sem precisar dos abates seguidos).
func arrow_unlock_cost(id: String) -> int:
	return 40 + int(get_arrow(id)["unlock"]) * 4


func buy_arrow(id: String) -> bool:
	var cost := arrow_unlock_cost(id)
	if is_unlocked(id) or coins < cost:
		return false
	coins -= cost
	unlocked.append(id)
	equip(id)
	save_data()
	return true


# --- Espaços de flecha e equipamento --------------------------------------------------

func max_slots() -> int:
	return START_SLOTS + SLOT_COSTS.size()


## Preço do próximo espaço de flecha, ou -1 se já tem todos.
func next_slot_cost() -> int:
	var i := arrow_slots - START_SLOTS
	return -1 if i >= SLOT_COSTS.size() else int(SLOT_COSTS[i])


func buy_slot() -> bool:
	var cost := next_slot_cost()
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	arrow_slots += 1
	save_data()
	return true


func is_equipped(id: String) -> bool:
	return loadout.has(id)


func has_free_slot() -> bool:
	return loadout.size() < arrow_slots


## Coloca a flecha num espaço livre. Retorna false se não há espaço.
func equip(id: String) -> bool:
	if not is_unlocked(id) or is_equipped(id) or not has_free_slot():
		return false
	loadout.append(id)
	save_data()
	return true


## Tira a flecha da partida (a Comum não sai).
func unequip(id: String) -> void:
	if id == "normal" or not is_equipped(id):
		return
	loadout.erase(id)
	if selected_arrow == id:
		selected_arrow = "normal"
	save_data()


## Dano da flecha com a melhoria (+12% por nível).
func arrow_damage(def: Dictionary) -> float:
	var master := MASTER_BONUS if is_master(def["id"]) else 0.0
	return float(def["damage"]) * (1.0 + 0.12 * arrow_level(def["id"]) + master)


## Estamina da flecha com a melhoria (-6% por nível).
func arrow_stamina(def: Dictionary) -> float:
	return float(def["stamina"]) * (1.0 - 0.06 * arrow_level(def["id"]))


## Força do efeito especial (veneno, fogo, gelo, explosão, raio...): +15% por nível.
func arrow_effect(id: String) -> float:
	return 1.0 + 0.15 * arrow_level(id)


func get_arrow(id: String) -> Dictionary:
	for a in ARROWS:
		if a["id"] == id:
			return a
	return ARROWS[0]


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func select_arrow(id: String) -> void:
	if is_equipped(id):
		selected_arrow = id
		save_data()


## Desbloqueia as flechas cuja meta foi atingida. Retorna as recém-desbloqueadas.
func check_unlocks(kills_in_a_row: int) -> Array:
	var new_ones: Array = []
	for a in ARROWS:
		if kills_in_a_row >= a["unlock"] and not unlocked.has(a["id"]):
			unlocked.append(a["id"])
			# Equipa sozinha se houver espaço livre.
			equip(a["id"])
			new_ones.append(a)
	if not new_ones.is_empty():
		save_data()
	return new_ones


func start_game() -> void:
	games_played += 1
	save_data()


func add_kill() -> void:
	total_kills += 1


## Salva o resultado da partida. Retorna true se for um novo recorde.
func submit_result(score: int, kills: int, wave := 0) -> bool:
	best_kills = maxi(best_kills, kills)
	best_wave = maxi(best_wave, wave)
	var is_record := score > best_score
	if is_record:
		best_score = score
	save_data()
	return is_record


func set_sound(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound()
	save_data()
	sound_changed.emit(enabled)


func _apply_sound() -> void:
	AudioServer.set_bus_mute(0, not sound_enabled)


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_score = cfg.get_value("progress", "best_score", 0)
	best_kills = cfg.get_value("progress", "best_kills", 0)
	best_wave = cfg.get_value("progress", "best_wave", 0)
	total_kills = cfg.get_value("progress", "total_kills", 0)
	games_played = cfg.get_value("progress", "games_played", 0)
	unlocked = cfg.get_value("progress", "unlocked", ["normal"])
	selected_arrow = cfg.get_value("progress", "selected_arrow", "normal")
	coins = cfg.get_value("progress", "coins", 0)
	upgrades = cfg.get_value("progress", "upgrades", {})
	arrow_levels = cfg.get_value("progress", "arrow_levels", {})
	arrow_xp = cfg.get_value("progress", "arrow_xp", {})
	free_coin_ads = cfg.get_value("ads", "free_coin_ads", 0)
	free_coin_day = cfg.get_value("ads", "free_coin_day", "")
	sessions = cfg.get_value("app", "sessions", 0)
	sound_enabled = cfg.get_value("settings", "sound", true)
	if not unlocked.has("normal"):
		unlocked.append("normal")
	arrow_slots = clampi(cfg.get_value("progress", "arrow_slots", START_SLOTS), START_SLOTS, max_slots())
	loadout = cfg.get_value("progress", "loadout", [])
	# Saves antigos (sem espaços): leva a Comum e a flecha que estava escolhida.
	if loadout.is_empty():
		loadout = ["normal"]
		if selected_arrow != "normal" and is_unlocked(selected_arrow):
			loadout.append(selected_arrow)
	loadout = loadout.filter(func(id): return is_unlocked(id))
	if not loadout.has("normal"):
		loadout.push_front("normal")
	loadout.resize(mini(loadout.size(), arrow_slots))
	if not is_equipped(selected_arrow):
		selected_arrow = "normal"


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "best_score", best_score)
	cfg.set_value("progress", "best_kills", best_kills)
	cfg.set_value("progress", "best_wave", best_wave)
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "games_played", games_played)
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "selected_arrow", selected_arrow)
	cfg.set_value("progress", "loadout", loadout)
	cfg.set_value("progress", "arrow_slots", arrow_slots)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "upgrades", upgrades)
	cfg.set_value("progress", "arrow_levels", arrow_levels)
	cfg.set_value("progress", "arrow_xp", arrow_xp)
	cfg.set_value("ads", "free_coin_ads", free_coin_ads)
	cfg.set_value("ads", "free_coin_day", free_coin_day)
	cfg.set_value("app", "sessions", sessions)
	cfg.set_value("settings", "sound", sound_enabled)
	cfg.save(SAVE_PATH)
