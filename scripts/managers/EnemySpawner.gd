# EnemySpawner.gd - Version réparée qui fonctionne
extends Node
class_name EnemySpawner

# Scenes d'ennemis
@export var basic_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/basic_enemy.tscn")
@export var shooting_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/shooting_enemy.tscn")
@export var elite_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/elite_enemy.tscn")

# Configuration équilibrée
@export var spawn_interval: float = 3.0      # Retour à la valeur d'origine
@export var max_enemies: int = 15            # Retour à la valeur d'origine
@export var spawn_distance_min: float = 400.0
@export var spawn_distance_max: float = 600.0
@export var despawn_distance: float = 800.0

var spawn_timer: float = 0.0
var active_enemies: Array = []
var player: Player = null
var total_spawned: int = 0

# Types d'ennemis avec la configuration d'origine
var enemy_types: Array = [
	{
		"name": "Grunt",
		"scene": basic_enemy_scene,
		"weight": 60,
		"health": 25.0,
		"speed": 80.0,
		"damage": 8.0,
		"can_shoot": false
	},
	{
		"name": "Shooter", 
		"scene": shooting_enemy_scene,
		"weight": 30,
		"health": 20.0,
		"speed": 60.0,
		"damage": 6.0,
		"can_shoot": true,
		"projectile_path": "res://scenes/projectiles/BasicProjectile.tscn"
	},
	{
		"name": "Elite",
		"scene": elite_enemy_scene,
		"weight": 10,
		"health": 60.0,
		"speed": 50.0,
		"damage": 10.0,
		"can_shoot": true,
		"projectile_path": "res://scenes/projectiles/BasicProjectile.tscn"
	}
]

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	find_player()
	
	# Spawn initial modéré
	for i in range(3):
		spawn_enemy_around_player()

func find_player():
	player = get_tree().get_first_node_in_group("players")
	if not player:
		print("❌ Player not found for enemy spawning!")

func _process(delta):
	if not player or not is_instance_valid(player):
		find_player()
		return
	
	spawn_timer += delta
	var current_enemy_count = active_enemies.size()
	
	# Spawn normal seulement
	if spawn_timer >= spawn_interval and current_enemy_count < max_enemies:
		spawn_enemy_around_player()
		spawn_timer = 0.0
	
	# Nettoyage des ennemis distants
	cleanup_distant_enemies()

func spawn_enemy_around_player():
	if not player:
		return
	
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	if current_enemies >= max_enemies:
		return
	
	var spawn_pos = get_spawn_position_around_player()
	var enemy_type = choose_enemy_type()
	
	if not enemy_type.scene:
		print("ERROR: Enemy scene is null for type: ", enemy_type.name)
		return
	
	var enemy = enemy_type.scene.instantiate()
	enemy.global_position = spawn_pos
	
	# CORRECTION IMPORTANTE : Garder l'ajout synchrone
	get_tree().current_scene.add_child(enemy)
	
	# CORRECTION IMPORTANTE : Garder la configuration synchrone
	if enemy.has_method("configure_enemy_deferred"):
		enemy.configure_enemy_deferred(enemy_type)
	
	# Ajouter à la liste avec signal de mort
	active_enemies.append(enemy)
	if enemy.has_signal("tree_exiting"):
		enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	
	total_spawned += 1
	print("🐺 Spawned ", enemy_type.name, " at ", spawn_pos, " (Active: ", active_enemies.size(), ")")

func get_spawn_position_around_player() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	var screen_center = player.global_position
	
	if camera:
		screen_center = camera.global_position
	
	# Position aléatoire en cercle autour du joueur
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	
	var spawn_offset = Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)
	
	var spawn_position = screen_center + spawn_offset
	
	return validate_spawn_position_simple(spawn_position)

func validate_spawn_position_simple(pos: Vector2) -> Vector2:
	# Validation simple - juste vérifier qu'on n'est pas dans un mur
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 16  # Layer des murs
	
	var space_state = get_tree().current_scene.get_viewport().world_2d.direct_space_state
	
	if not space_state:
		return pos + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	
	var result = space_state.intersect_point(query)
	if not result.is_empty():
		var random_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		return pos + random_offset
	
	return pos

func cleanup_distant_enemies():
	if not player:
		return
	
	var enemies_to_remove = []
	
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		
		if distance > despawn_distance:
			print("🧹 Despawning distant enemy: ", enemy.name, " (distance: ", int(distance), ")")
			enemies_to_remove.append(enemy)
			enemy.queue_free()
	
	# Nettoyer la liste
	for enemy in enemies_to_remove:
		active_enemies.erase(enemy)

func choose_enemy_type():
	# Sélection pondérée simple
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

func _on_enemy_died(enemy):
	active_enemies.erase(enemy)
	print("💀 Enemy died. Active count: ", active_enemies.size())

# Fonctions utiles pour ajuster la difficulté si besoin
func increase_spawn_rate():
	spawn_interval = max(1.0, spawn_interval - 0.5)
	print("🔥 Spawn rate increased to: ", spawn_interval, "s")

func decrease_spawn_rate():
	spawn_interval = min(5.0, spawn_interval + 0.5)
	print("❄️ Spawn rate decreased to: ", spawn_interval, "s")

func increase_max_enemies():
	max_enemies = min(30, max_enemies + 5)
	print("🔥 Max enemies increased to: ", max_enemies)

func decrease_max_enemies():
	max_enemies = max(5, max_enemies - 5)
	print("❄️ Max enemies decreased to: ", max_enemies)

# Debug
func get_spawn_stats() -> Dictionary:
	return {
		"active_enemies": active_enemies.size(),
		"max_enemies": max_enemies,
		"total_spawned": total_spawned,
		"spawn_interval": spawn_interval,
		"player_found": player != null
	}

func force_spawn_enemy():
	spawn_enemy_around_player()

func clear_all_enemies():
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	print("🧹 Cleared all enemies")
