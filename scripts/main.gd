extends Node2D
## Cena principal da Etapa 1: cria as flechas pedidas pelos personagens,
## limita quantas existem ao mesmo tempo e conta os acertos no inimigo.

const MAX_ARROWS := 30  ## Limite de flechas simultâneas (desempenho no celular).

@export var arrow_scene: PackedScene

var _arrows: Array = []
var _hits := 0

@onready var _arrows_root: Node2D = $Arrows
@onready var _player := $Player
@onready var _enemy := $Enemy
@onready var _hits_label: Label = $HUD/HitsLabel


func _ready() -> void:
	_player.shot_fired.connect(_on_shot_fired)
	_enemy.hit_taken.connect(_on_enemy_hit_taken)
	_update_hud()


func _on_shot_fired(spawn_position: Vector2, velocity: Vector2, mask: int, shooter: Node2D) -> void:
	var arrow := arrow_scene.instantiate() as Arrow
	_arrows_root.add_child(arrow)
	arrow.launch(spawn_position, velocity, mask, shooter)

	# Remove da lista as flechas que já sumiram e apaga as mais antigas se passar do limite.
	_arrows = _arrows.filter(func(a): return is_instance_valid(a))
	_arrows.append(arrow)
	while _arrows.size() > MAX_ARROWS:
		var oldest = _arrows.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()


func _on_enemy_hit_taken(_arrow: Node2D, _hit_position: Vector2) -> void:
	_hits += 1
	_update_hud()


func _update_hud() -> void:
	_hits_label.text = "Acertos: %d" % _hits
