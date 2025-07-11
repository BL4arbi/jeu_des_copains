# EnemySpawner.gd
extends Node
class_name EnemySpawner

@export var basic_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/basic_enemy.tscn")
@export var shooting_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/shooting_enemy.tscn")
@export var elite_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/elite_enemy.tscn")
@export var spawn_area: Rect2 = Rect2(50, 50, 700, 500)
@export var spawn_interval: float = 5.0
@export var max_enemies: int = 8

var spawn_timer: float = 0.0
var active_enemies: Array = []

# Types d'ennemis avec leurs scènes
var enemy_types: Array = [
	{
		"name": "Grunt",
		"scene": basic_enemy_scene,
		"weight": 60,
		"health": 30.0,
		"speed": 80.0,
		"damage": 5.0,
		"can_shoot": false
	},
	{
		"name": "Shooter", 
		"scene": shooting_enemy_scene,
		"weight": 30,
		"health": 20.0,
		"speed": 60.0,
		"damage": 8.0,
		"can_shoot": true,
		"projectile_path": "res://scenes/projectiles/BasicProjectile.tscn"
	},
	{
		"name": "Elite",
		"scene": elite_enemy_scene,
		"weight": 10,
		"health": 80.0,
		"speed": 50.0,
		"damage": 15.0,
		"can_shoot": true,
		"projectile_path": "res://scenes/projectiles/BasicProjectile.tscn"
	}
]

func _ready():
	spawn_enemy()

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval and active_enemies.size() < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	var spawn_pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	
	var enemy_type = choose_enemy_type()
	
	var enemy = enemy_type.scene.instantiate()
	enemy.global_position = spawn_pos
	
	get_tree().current_scene.add_child(enemy)
	
	call_deferred("configure_enemy", enemy, enemy_type)
	
	active_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	
	print("Spawned ", enemy_type.name, " at ", spawn_pos)

func choose_enemy_type():
	var total_weight = 0
	for type in enemy_types:
		total_weight += type.weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for type in enemy_types:
		current_weight += type.weight
		if random_value < current_weight:
			return type
	
	return enemy_types[0]

func configure_enemy(enemy, enemy_type):
	enemy.max_health = enemy_type.health
	enemy.current_health = enemy_type.health
	enemy.speed = enemy_type.speed
	enemy.damage = enemy_type.damage
	enemy.can_shoot = enemy_type.get("can_shoot", false)
	enemy.is_elite = (enemy_type.name == "Elite")
	enemy.enemy_type = enemy_type.name
	
	if enemy.can_shoot:
		enemy.projectile_scene_path = enemy_type.get("projectile_path", "")
		enemy.fire_rate = 2.5 if enemy_type.name == "Shooter" else 2.0
		if enemy_type.name == "Shooter":
			enemy.optimal_distance = 180.0
	
	enemy.update_health_bar()

func _on_enemy_died(enemy):
	active_enemies.erase(enemy)
