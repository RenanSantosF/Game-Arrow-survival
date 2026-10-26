extends Node
## Dados do jogo: definições das flechas, recorde e progresso salvos no aparelho.
## Fica disponível em qualquer script pelo nome "GameData" (Autoload).

signal sound_changed(enabled: bool)

const SAVE_PATH := "user://save.cfg"

## Multiplicador de dano por região do corpo.
const ZONE_MULTIPLIER := {
	"head": 3.0,
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
var unlocked: Array = ["normal"]
var coins := 0
var upgrades := {}


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


func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0 or coins < cost:
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


# --- Flechas ----------------------------------------------------------------------

func get_arrow(id: String) -> Dictionary:
	for a in ARROWS:
		if a["id"] == id:
			return a
	return ARROWS[0]


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func select_arrow(id: String) -> void:
	if is_unlocked(id):
		selected_arrow = id
		save_data()


## Desbloqueia as flechas cuja meta foi atingida. Retorna as recém-desbloqueadas.
func check_unlocks(kills_in_a_row: int) -> Array:
	var new_ones: Array = []
	for a in ARROWS:
		if kills_in_a_row >= a["unlock"] and not unlocked.has(a["id"]):
			unlocked.append(a["id"])
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
	sessions = cfg.get_value("app", "sessions", 0)
	sound_enabled = cfg.get_value("settings", "sound", true)
	if not unlocked.has("normal"):
		unlocked.append("normal")
	if not is_unlocked(selected_arrow):
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
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "upgrades", upgrades)
	cfg.set_value("app", "sessions", sessions)
	cfg.set_value("settings", "sound", sound_enabled)
	cfg.save(SAVE_PATH)
