extends Node2D

@export var enemy_scene: PackedScene = preload("res://SCENES/enemy/enemy.tscn")
@export var spawn_interval = 1 # Secondes entre chaque spawn
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
	
	# FORCER les couches de collision pour l'ennemi
	enemy.collision_layer = 2
	enemy.collision_mask = 1
	
	# Assigner le joueur
	var player = get_node("CharacterBody2D")
	enemy.player = player
	
	add_child(enemy)
	
	# Attendre que l'ennemi soit ajouté, puis configurer l'Area2D
	await get_tree().process_frame
	
	# FORCER les couches pour l'Area2D
	if enemy.has_node("Area2D"):
		enemy.get_node("Area2D").collision_layer = 2
		enemy.get_node("Area2D").collision_mask = 3  # Pour détecter les balles (layer 3)
		print("Area2D configuré pour ", enemy.name)
