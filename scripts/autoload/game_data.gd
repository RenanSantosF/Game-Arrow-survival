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
const ARROWS := [
	{
		"id": "normal", "name": "Comum", "unlock": 0,
		"desc": "Confiável e leve.\nGasta pouca estamina.",
		"damage": 25.0, "stamina": 12.0,
		"shaft": Color(0.45, 0.28, 0.12), "head": Color(0.78, 0.8, 0.85), "fletch": Color(0.96, 0.96, 0.96),
		"trail": Color(1, 1, 1, 0.0),
	},
	{
		"id": "poison", "name": "Veneno", "unlock": 10,
		"desc": "Envenena o alvo:\ndano contínuo por 4s.",
		"damage": 18.0, "stamina": 14.0,
		"shaft": Color(0.2, 0.35, 0.15), "head": Color(0.45, 0.95, 0.25), "fletch": Color(0.6, 1.0, 0.4),
		"trail": Color(0.45, 0.95, 0.25, 0.9),
	},
	{
		"id": "fire", "name": "Fogo", "unlock": 20,
		"desc": "Incendeia o alvo:\nqueima por 3s.",
		"damage": 22.0, "stamina": 16.0,
		"shaft": Color(0.35, 0.15, 0.08), "head": Color(1.0, 0.55, 0.1), "fletch": Color(1.0, 0.85, 0.2),
		"trail": Color(1.0, 0.5, 0.1, 0.95),
	},
	{
		"id": "ice", "name": "Gelo", "unlock": 35,
		"desc": "Congela o inimigo:\nele para de atirar por 3s.",
		"damage": 18.0, "stamina": 16.0,
		"shaft": Color(0.6, 0.75, 0.9), "head": Color(0.6, 0.95, 1.0), "fletch": Color(0.85, 0.97, 1.0),
		"trail": Color(0.7, 0.95, 1.0, 0.9),
	},
	{
		"id": "explosive", "name": "Explosiva", "unlock": 50,
		"desc": "Explode no impacto e\natinge quem estiver perto.",
		"damage": 30.0, "stamina": 24.0,
		"shaft": Color(0.25, 0.25, 0.25), "head": Color(0.95, 0.2, 0.15), "fletch": Color(1.0, 0.75, 0.1),
		"trail": Color(1.0, 0.8, 0.3, 0.8),
	},
	{
		"id": "triple", "name": "Tripla", "unlock": 75,
		"desc": "Dispara três flechas\nde uma vez.",
		"damage": 20.0, "stamina": 26.0,
		"shaft": Color(0.5, 0.3, 0.6), "head": Color(0.85, 0.7, 1.0), "fletch": Color(0.95, 0.85, 1.0),
		"trail": Color(0.85, 0.7, 1.0, 0.8),
	},
]

var best_score := 0
var best_kills := 0
var total_kills := 0
var games_played := 0
var sessions := 0
var sound_enabled := true
var selected_arrow := "normal"
var unlocked: Array = ["normal"]


func _ready() -> void:
	load_data()
	sessions += 1
	save_data()
	_apply_sound()


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
func submit_result(score: int, kills: int) -> bool:
	best_kills = maxi(best_kills, kills)
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
	total_kills = cfg.get_value("progress", "total_kills", 0)
	games_played = cfg.get_value("progress", "games_played", 0)
	unlocked = cfg.get_value("progress", "unlocked", ["normal"])
	selected_arrow = cfg.get_value("progress", "selected_arrow", "normal")
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
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "games_played", games_played)
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "selected_arrow", selected_arrow)
	cfg.set_value("app", "sessions", sessions)
	cfg.set_value("settings", "sound", sound_enabled)
	cfg.save(SAVE_PATH)
