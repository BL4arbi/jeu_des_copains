# ForkArrowProjectile.gd - Version corrigée pour voir les projectiles fork
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
	
	if body.has_method("take_damage"):
		var initial_damage = damage * damage_multiplier
		body.take_damage(initial_damage)
		print("✅ Initial damage: ", initial_damage)
		targets_pierced += 1
	
	if targets_pierced < piercing_power:
		print("🏹 Arrow pierces through (", targets_pierced, "/", piercing_power, ")")
		return
	
	if not has_forked:
		create_fork_projectiles(body.global_position)
		has_forked = true
	
	queue_free()

func create_fork_projectiles(impact_position: Vector2):
	print("🏹 Creating ", fork_count, " fork arrows!")
	
	var nearby_targets = find_nearby_targets(impact_position)
	
	for i in range(fork_count):
		# CORRECTION : Délai pour voir les projectiles apparaître
		call_deferred("spawn_fork_projectile", i, impact_position, nearby_targets)

# NOUVELLE MÉTHODE : Spawn différé pour voir les forks
func spawn_fork_projectile(fork_index: int, impact_position: Vector2, nearby_targets: Array):
	var fork = create_fork_projectile()
	if not fork:
		return
	
	get_tree().current_scene.add_child(fork)
	fork.global_position = impact_position
	
	var fork_direction = calculate_fork_direction(fork_index, nearby_targets, impact_position)
	fork.direction = fork_direction
	
	# Configuration de la fork
	var fork_damage = damage * fork_damage_ratio * damage_multiplier
	var fork_speed = speed * fork_speed_ratio
	var fork_lifetime = lifetime * 0.8  # Plus long pour voir les forks
	
	fork.setup(fork_damage, fork_speed, fork_lifetime)
	
	# AJOUT : Configuration visuelle spéciale pour les forks
	fork.set_owner_type(owner_type)
	fork.projectile_type = "fork_child"  # Type spécial pour les forks
	
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

func create_fork_projectile() -> BaseProjectile:
	# Utiliser BaseProjectile directement au lieu de BasicProjectile
	var fork_projectile = BaseProjectile.new()
	
	# AJOUT : Ajouter manuellement les composants nécessaires
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 4.0
	collision_shape.shape = circle_shape
	fork_projectile.add_child(collision_shape)
	
	var sprite = Sprite2D.new()
	# Créer un sprite simple pour la fork
	var image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var center = Vector2(6, 6)
	for x in range(12):
		for y in range(12):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 4:
				image.set_pixel(x, y, Color.LIGHT_BLUE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture
	fork_projectile.add_child(sprite)
	
	# Assigner le sprite à la variable
	fork_projectile.sprite = sprite
	fork_projectile.collision_shape = collision_shape
	
	return fork_projectile

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true

# AJOUT : Override pour BaseProjectile pour différencier les forks
func setup_visual_effects():
	super.setup_visual_effects()
	
	# Si c'est un fork enfant, couleur spéciale
	if projectile_type == "fork_child" and sprite:
		sprite.modulate = Color.LIGHT_BLUE
		sprite.scale = Vector2(0.7, 0.7)
