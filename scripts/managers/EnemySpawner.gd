# EnemySpawner.gd - Version équilibrée avec plus d'ennemis
extends Node
class_name EnemySpawner
const MAX_ENEMIES_AT_STARTUP = 10
@export var basic_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/basic_enemy.tscn")
@export var shooting_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/shooting_enemy.tscn")
@export var elite_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/elite_enemy.tscn")

# NOUVELLES VALEURS ÉQUILIBRÉES
@export var spawn_interval: float = 2.0      # Plus rapide (était 3.0)
@export var max_enemies: int = 25            # Plus d'ennemis (était 15)
@export var spawn_distance_min: float = 300.0  # Plus proche (était 400.0)
@export var spawn_distance_max: float = 500.0  # Plus proche (était 600.0)
@export var despawn_distance: float = 1200.0   # Plus loin (était 800.0)

# Variables de spawn agressif
var aggressive_spawn_timer: float = 0.0
var aggressive_spawn_interval: float = 0.8   # Spawn très rapide parfois
var wave_spawn_active: bool = false

var spawn_timer: float = 0.0
var active_enemies: Array = []
var player: Player = null
var total_spawned: int = 0

# Types d'ennemis avec poids ajustés
var enemy_types: Array = [
	{
		"name": "Grunt",
		"scene": basic_enemy_scene,
		"weight": 50,  # Réduit (était 60)
		"health": 25.0,
		"speed": 80.0,
		"damage": 8.0,
		"can_shoot": false
	},
	{
		"name": "Shooter", 
		"scene": shooting_enemy_scene,
		"weight": 35,  # Augmenté (était 30)
		"health": 20.0,
		"speed": 60.0,
		"damage": 6.0,
		"can_shoot": true,
		"projectile_path": "res://scenes/projectiles/BasicProjectile.tscn"
	},
	{
		"name": "Elite",
		"scene": elite_enemy_scene,
		"weight": 15,  # Augmenté (était 10)
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
	
	# Spawn initial plus agressif
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
	
	# Spawn principal
	spawn_timer += delta
	aggressive_spawn_timer += delta
	
	var current_enemy_count = active_enemies.size()
	
	# Spawn normal
	if spawn_timer >= spawn_interval and current_enemy_count < max_enemies:
		spawn_enemy_around_player()
		spawn_timer = 0.0
	
	# NOUVEAU : Spawn agressif si pas assez d'ennemis
	if current_enemy_count < max_enemies * 0.6:  # Si moins de 60% du max
		if aggressive_spawn_timer >= aggressive_spawn_interval:
			spawn_multiple_enemies()
			aggressive_spawn_timer = 0.0
	
	# NOUVEAU : Wave spawn périodique
	if total_spawned > 0 and total_spawned % 20 == 0 and not wave_spawn_active:
		trigger_enemy_wave()
	
	# Nettoyage moins agressif
	cleanup_distant_enemies()
	
	# Debug info
	if spawn_timer == 0.0:  # Juste après un spawn
		print("🐺 Active enemies: ", current_enemy_count, "/", max_enemies, " | Total spawned: ", total_spawned)

func spawn_multiple_enemies():
	# Spawn 2-3 ennemis rapidement
	var spawn_count = randi_range(2, 3)
	
	for i in range(spawn_count):
		if active_enemies.size() < max_enemies:
			spawn_enemy_around_player()
			await get_tree().create_timer(0.2).timeout
	
	print("⚡ Aggressive spawn: ", spawn_count, " enemies")

func trigger_enemy_wave():
	wave_spawn_active = true
	print("🌊 ENEMY WAVE INCOMING!")
	
	# Spawn d'une vague de 5-8 ennemis
	var wave_size = randi_range(5, 8)
	
	for i in range(wave_size):
		if active_enemies.size() < max_enemies + 5:  # Permet de dépasser temporairement
			spawn_enemy_around_player()
			await get_tree().create_timer(0.3).timeout
	
	print("🌊 Wave complete: ", wave_size, " enemies spawned")
	
	# Cooldown avant la prochaine vague
	await get_tree().create_timer(15.0).timeout
	wave_spawn_active = false

func spawn_enemy_around_player():
	if not player:
		return
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	var spawn_pos = get_spawn_position_around_player()
	var enemy_type = choose_enemy_type()
	var max_enemies = MAX_ENEMIES_AT_STARTUP
	if not enemy_type.scene:
		print("ERROR: Enemy scene is null for type: ", enemy_type.name)
		return
	
	var enemy = enemy_type.scene.instantiate()
	enemy.global_position = spawn_pos
	
	get_tree().current_scene.add_child.call_deferred(enemy)	
	# Configuration différée pour éviter les erreurs
	enemy.call_deferred("configure_enemy_deferred", enemy_type)
	
	# Ajouter à la liste avec signal de mort
	active_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	
	total_spawned += 1
	if get_tree().current_scene.has_meta("game_started"):
		max_enemies = 50  # Limite normale après
	
	if current_enemies >= max_enemies:
		return
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
	
	# Validation avec moins de tentatives pour éviter les boucles
	return validate_spawn_position_simple(spawn_position)

func validate_spawn_position_simple(pos: Vector2) -> Vector2:
	# Validation simple - juste vérifier qu'on n'est pas dans un mur
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 16  # Layer des murs
	
	var space_state = get_tree().current_scene.get_viewport().world_2d.direct_space_state
	var result = space_state.intersect_point(query)
	
	# Si collision, décaler légèrement
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
		
		# Despawn seulement si VRAIMENT trop loin
		if distance > despawn_distance:
			print("🧹 Despawning very distant enemy: ", enemy.name, " (distance: ", int(distance), ")")
			enemies_to_remove.append(enemy)
			enemy.queue_free()
	
	# Nettoyer la liste
	for enemy in enemies_to_remove:
		active_enemies.erase(enemy)

func choose_enemy_type():
	# Progression dans la difficulté
	var difficulty_multiplier = 1.0 + (total_spawned * 0.01)  # +1% par ennemi spawné
	
	# Ajuster les poids selon la progression
	var adjusted_types = enemy_types.duplicate(true)
	
	if total_spawned > 30:  # Plus d'Elite après 30 spawns
		for type in adjusted_types:
			if type.name == "Elite":
				type.weight = int(type.weight * 1.5)
	
	if total_spawned > 50:  # Encore plus d'Elite après 50
		for type in adjusted_types:
			if type.name == "Elite":
				type.weight = int(type.weight * 2.0)
			elif type.name == "Grunt":
				type.weight = int(type.weight * 0.7)  # Moins de Grunt
	
	# Sélection pondérée
	var total_weight = 0
	for type in adjusted_types:
		total_weight += type.weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for type in adjusted_types:
		current_weight += type.weight
		if random_value < current_weight:
			return type
	
	return adjusted_types[0]

func _on_enemy_died(enemy):
	active_enemies.erase(enemy)
	print("💀 Enemy died. Active count: ", active_enemies.size())

# Méthodes d'ajustement dynamique
func increase_difficulty():
	spawn_interval = max(1.0, spawn_interval - 0.3)
	max_enemies = min(35, max_enemies + 3)
	aggressive_spawn_interval = max(0.5, aggressive_spawn_interval - 0.1)
	
	print("🔥 Difficulty increased! Spawn: ", spawn_interval, "s | Max: ", max_enemies)

func decrease_difficulty():
	spawn_interval = min(4.0, spawn_interval + 0.5)
	max_enemies = max(15, max_enemies - 2)
	aggressive_spawn_interval = min(1.2, aggressive_spawn_interval + 0.1)
	
	print("❄️ Difficulty decreased! Spawn: ", spawn_interval, "s | Max: ", max_enemies)

# Debug et statistiques
func get_spawn_stats() -> Dictionary:
	return {
		"active_enemies": active_enemies.size(),
		"max_enemies": max_enemies,
		"total_spawned": total_spawned,
		"spawn_interval": spawn_interval,
		"wave_active": wave_spawn_active,
		"player_found": player != null
	}

func force_spawn_wave():
	# Pour debug - forcer une vague
	if not wave_spawn_active:
		trigger_enemy_wave()

# Spawn d'urgence si plus d'ennemis
func emergency_spawn():
	if active_enemies.size() < 5:
		print("🚨 Emergency spawn activated!")
		for i in range(5):
			spawn_enemy_around_player()
			await get_tree().create_timer(0.1).timeout
