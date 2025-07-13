# ForkArrowProjectile.gd - Version corrigée qui fork TOUJOURS
extends BaseProjectile
class_name ForkArrowProjectile

var fork_count: int = 3
var fork_range: float = 200.0
var fork_damage_ratio: float = 0.6
var fork_speed_ratio: float = 0.8
var piercing_power: int = 0
var spread_angle: float = PI / 3
var damage_multiplier: float = 1.0
var range_multiplier: float = 1.0

var has_forked: bool = false
var targets_pierced: int = 0

func _ready():
	super._ready()
	# AJOUT : Connecter le signal pour que _on_hit_target soit appelé
	body_entered.connect(_on_hit_target)
	setup_fork_arrow()

func setup_fork_arrow():
	if sprite:
		sprite.modulate = Color.PURPLE
		if direction != Vector2.ZERO:
			sprite.rotation = direction.angle()

func _physics_process(delta):
	super._physics_process(delta)
	
	if homing_strength > 0:
		apply_homing_force(delta)
	
	if sprite and direction != Vector2.ZERO:
		sprite.rotation = direction.angle()

func apply_homing_force(delta):
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var closest_target = null
	var closest_distance = fork_range * range_multiplier
	
	for target in potential_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	if closest_target:
		var target_direction = (closest_target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength * delta)
		direction = direction.normalized()

func _on_hit_target(body):
	print("🏹 Fork Arrow hit: ", body.name)
	
	if not should_damage_target(body):
		return
	
	# CORRECTION : Fork TOUJOURS en premier, même si ça va tuer
	if not has_forked:
		create_fork_projectiles(body.global_position)
		has_forked = true
		print("🏹 Forked at enemy position")
	
	# Puis infliger les dégâts
	if body.has_method("take_damage"):
		var initial_damage = damage * damage_multiplier
		body.take_damage(initial_damage)
		print("✅ Fork Arrow damage: ", initial_damage)
		targets_pierced += 1
	
	# Vérifier piercing APRÈS fork et dégâts
	if targets_pierced < piercing_power:
		print("🏹 Arrow pierces through (", targets_pierced, "/", piercing_power, ")")
		return
	
	queue_free()

func create_fork_projectiles(impact_position: Vector2):
	print("🏹 Creating ", fork_count, " fork arrows!")
	
	var nearby_targets = find_nearby_targets(impact_position)
	
	for i in range(fork_count):
		# Spawn immédiat des forks
		call_deferred("spawn_fork_projectile", i, impact_position, nearby_targets)

func spawn_fork_projectile(fork_index: int, impact_position: Vector2, nearby_targets: Array):
	# CORRECTION : Utiliser la scène BasicProjectile existante
	var fork_scene = load("res://scenes/projectiles/BasicProjectile.tscn")
	var fork = fork_scene.instantiate()
	
	get_tree().current_scene.add_child(fork)
	fork.global_position = impact_position
	
	var fork_direction = calculate_fork_direction(fork_index, nearby_targets, impact_position)
	fork.direction = fork_direction
	
	# Configuration de la fork
	var fork_damage = damage * fork_damage_ratio * damage_multiplier
	var fork_speed = speed * fork_speed_ratio
	var fork_lifetime = lifetime * 0.8
	
	fork.setup(fork_damage, fork_speed, fork_lifetime)
	fork.set_owner_type(owner_type)
	
	# Couleur distincte pour les forks
	if fork.sprite:
		fork.sprite.modulate = Color.LIGHT_BLUE
		fork.sprite.scale = Vector2(0.8, 0.8)
		# Rotation selon la direction
		if fork_direction != Vector2.ZERO:
			fork.sprite.rotation = fork_direction.angle()
	
	print("🏹 Fork ", fork_index+1, " spawned at ", fork.global_position, " going ", fork_direction)

func find_nearby_targets(impact_position: Vector2) -> Array:
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	var nearby_targets = []
	
	var effective_range = fork_range * range_multiplier
	
	for target in potential_targets:
		var distance = impact_position.distance_to(target.global_position)
		if distance <= effective_range and distance > 20:
			nearby_targets.append({
				"target": target,
				"distance": distance,
				"position": target.global_position
			})
	
	nearby_targets.sort_custom(func(a, b): return a.distance < b.distance)
	
	return nearby_targets

func calculate_fork_direction(fork_index: int, nearby_targets: Array, impact_position: Vector2) -> Vector2:
	if fork_index < nearby_targets.size():
		var target_pos = nearby_targets[fork_index].position
		return (target_pos - impact_position).normalized()
	else:
		var base_angle = direction.angle()
		var angle_step = spread_angle / max(1, fork_count - 1)
		var fork_angle = base_angle - (spread_angle / 2) + (fork_index * angle_step)
		
		# Variation aléatoire réduite
		fork_angle += randf_range(-PI/24, PI/24)  # ±7.5 degrés
		
		return Vector2(cos(fork_angle), sin(fork_angle))

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true
