extends Node2D

@export var enemy_scene: PackedScene = preload("res://SCENES/enemy/enemy.tscn")
@export var projectile_item_scene: PackedScene = preload("res://SCENES/Projectile_Item.tscn")
@export var spawn_interval = 2.0  # Secondes entre chaque spawn
@export var item_spawn_interval = 4.0
var spawn_timer: Timer
var item_spawn_timer: Timer

var projectile_types = [
	ProjectileItem.ProjectileType.FIRE,
	ProjectileItem.ProjectileType.POISON,
	ProjectileItem.ProjectileType.LIGHTNING
]

func _ready():
	# Créer un timer pour faire apparaître des ennemis
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)
	
	item_spawn_timer = Timer.new()
	item_spawn_timer.wait_time = item_spawn_interval
	item_spawn_timer.timeout.connect(_on_item_spawn_timer_timeout)
	item_spawn_timer.autostart = true
	add_child(item_spawn_timer)

func _on_spawn_timer_timeout():
	# Position aléatoire pour le nouvel ennemi
	var spawn_pos = Vector2(
		randf_range(100, 1000),
		randf_range(100, 600)
	)
	spawn_enemy_at(spawn_pos)
	
func _on_item_spawn_timer_timeout():	
	
	var spawn_pos_item = Vector2(
		randf_range(100,1000),
		randf_range(100,600)
	)
	spawn_item_at(spawn_pos_item)

func spawn_item_at(position: Vector2):
	var item = projectile_item_scene.instantiate()
	item.global_position = position
	item.projectile_type = projectile_types[randi() % projectile_types.size()]
	add_child(item)	
	
func spawn_enemy_at(position: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	add_child(enemy)
