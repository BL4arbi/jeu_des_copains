extends Node2D

@export var enemy_scene: PackedScene = preload("res://SCENES/enemy/enemy.tscn")
@export var spawn_interval = 2.0  # Secondes entre chaque spawn
var spawn_timer: Timer

func _ready():
	# Créer un timer pour faire apparaître des ennemis
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	# Position aléatoire pour le nouvel ennemi
	var spawn_pos = Vector2(
		randf_range(100, 1000),
		randf_range(100, 600)
	)
	spawn_enemy_at(spawn_pos)

func spawn_enemy_at(position: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	add_child(enemy)
