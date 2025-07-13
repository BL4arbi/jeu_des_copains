# EnemySpawner.gd - Version améliorée qui suit le joueur
extends Node
class_name EnemySpawner

@export var basic_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/basic_enemy.tscn")
@export var shooting_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/shooting_enemy.tscn")
@export var elite_enemy_scene: PackedScene = preload("res://scenes/characters/enemies/elite_enemy.tscn")

# NOUVELLES VARIABLES pour spawn dynamique
@export var spawn_interval: float = 3.0  # Plus rapide
@export var max_enemies: int = 15        # Plus d'ennemis
@export var spawn_distance_min: float = 400.0  # Distance minimale du joueur
@export var spawn_distance_max: float = 600.0  # Distance maximale du joueur
@export var despawn_distance: float = 800.0    # Distance pour despawn automatique

var spawn_timer: float = 0.0
var active_enemies: Array = []
var player: Player = null

# Types d'ennemis équilibrés
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
	# Trouver le joueur
	find_player()
	
	# Premier spawn
	spawn_enemy()
	
	print("🐺 EnemySpawner ready - following player!")

func find_player():
	player = get_tree().get_first_node_in_group("players")
	if not player:
		print("❌ Player not found for enemy spawning!")

func _process(delta):
	if not player or not is_instance_valid(player):
		find_player()
		return
	
	spawn_timer += delta
	
	# Spawn selon la distance et le nombre d'ennemis
	if spawn_timer >= spawn_interval and active_enemies.size() < max_enemies:
		spawn_enemy_around_player()
		spawn_timer = 0.0
	
	# Nettoyer les ennemis trop loin
	cleanup_distant_enemies()

func spawn_enemy_around_player():
	if not player:
		return
	
	var spawn_pos = get_spawn_position_around_player()
	var enemy_type = choose_enemy_type()
	
	if not enemy_type.scene:
		print("ERROR: Enemy scene is null for type: ", enemy_type.name)
		return
	
	var enemy = enemy_type.scene.instantiate()
	enemy.global_position = spawn_pos
	
	get_tree().current_scene.add_child(enemy)
	
	enemy.call_deferred("configure_enemy_deferred", enemy_type)	
	active_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	
	print("🐺 Spawned ", enemy_type.name, " around player at ", spawn_pos)

func get_spawn_position_around_player() -> Vector2:
	# Obtenir la position de la caméra/écran visible
	var camera = get_viewport().get_camera_2d()
	var screen_center = player.global_position
	
	if camera:
		screen_center = camera.global_position
	
	# Calculer une position en dehors de l'écran visible
	var angle = randf() * TAU  # Angle aléatoire
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	
	var spawn_offset = Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)
	
	var spawn_position = screen_center + spawn_offset
	
	# Vérifier que la position n'est pas dans un mur (optionnel)
	spawn_position = validate_spawn_position(spawn_position)
	
	return spawn_position

func validate_spawn_position(pos: Vector2) -> Vector2:
	# Add a maximum attempt counter to prevent infinite recursion
	return validate_spawn_position_with_attempts(pos, 10)

func validate_spawn_position_with_attempts(pos: Vector2, max_attempts: int) -> Vector2:
	# If we've exhausted our attempts, return the original position
	if max_attempts <= 0:
		print("Warning: Could not find valid spawn position after maximum attempts")
		return pos
	
	# Vérifier les collisions avec les murs (si tu as des TileMaps)
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 16  # Layer des murs (layer 5)
	
	var space_state = get_tree().current_scene.get_viewport().world_2d.direct_space_state
	var result = space_state.intersect_point(query)
	
	# If no collision, position is valid
	if result.is_empty():
		return pos
	
	# Generate a new random position and try again with one less attempt
	var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	return validate_spawn_position_with_attempts(pos + offset, max_attempts - 1)
func cleanup_distant_enemies():
	if not player:
		return
	
	var enemies_to_remove = []
	
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		
		# Despawn si trop loin
		if distance > despawn_distance:
			print("🧹 Despawning distant enemy: ", enemy.name)
			enemies_to_remove.append(enemy)
			enemy.queue_free()
	
	# Nettoyer la liste
	for enemy in enemies_to_remove:
		active_enemies.erase(enemy)

func spawn_enemy():
	# Méthode de fallback pour le spawn initial
	if player:
		spawn_enemy_around_player()
	else:
		# Spawn fixe si pas de joueur trouvé
		spawn_enemy_fixed_position()

func spawn_enemy_fixed_position():
	# Version de fallback avec position fixe
	var spawn_area = Rect2(50, 50, 700, 500)
	var spawn_pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	
	var enemy_type = choose_enemy_type()
	
	if not enemy_type.scene:
		print("ERROR: Enemy scene is null for type: ", enemy_type.name)
		return
	
	var enemy = enemy_type.scene.instantiate()
	enemy.global_position = spawn_pos
	
	get_tree().current_scene.add_child(enemy)
	
	enemy.call_deferred("configure_enemy_deferred", enemy_type)	
	active_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	
	print("🐺 Spawned ", enemy_type.name, " at fixed position ", spawn_pos)

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
	if not is_instance_valid(enemy):
		return
	
	# Configuration des stats
	enemy.max_health = enemy_type.health
	enemy.current_health = enemy_type.health
	enemy.speed = enemy_type.speed
	enemy.damage = enemy_type.damage
	enemy.can_shoot = enemy_type.get("can_shoot", false)
	enemy.is_elite = (enemy_type.name == "Elite")
	enemy.enemy_type = enemy_type.name
	
	if enemy.can_shoot:
		enemy.projectile_scene_path = enemy_type.get("projectile_path", "")
		
		# Cadences de tir équilibrées
		match enemy_type.name:
			"Shooter":
				enemy.fire_rate = 3.5
				enemy.optimal_distance = 180.0
			"Elite":
				enemy.fire_rate = 4.0
	
	# Mettre à jour la health bar si elle existe
	if enemy.has_method("update_health_bar"):
		enemy.update_health_bar()

func _on_enemy_died(enemy):
	active_enemies.erase(enemy)

# Méthodes pour ajuster la difficulté
func increase_spawn_rate():
	spawn_interval = max(1.0, spawn_interval - 0.5)
	max_enemies = min(25, max_enemies + 2)
	print("🔥 Spawn rate increased! Interval: ", spawn_interval, " Max: ", max_enemies)

func decrease_spawn_rate():
	spawn_interval = min(5.0, spawn_interval + 0.5)
	max_enemies = max(5, max_enemies - 2)
	print("❄️ Spawn rate decreased! Interval: ", spawn_interval, " Max: ", max_enemies)

# Debug - info sur le spawning
func get_spawn_info() -> Dictionary:
	return {
		"active_enemies": active_enemies.size(),
		"max_enemies": max_enemies,
		"spawn_interval": spawn_interval,
		"player_found": player != null
	}
