# ForkArrowProjectile.gd - Version modulaire avec variables configurables
extends BaseProjectile
class_name ForkArrowProjectile

# === VARIABLES CONFIGURABLES (pour futurs accessoires) ===
var fork_count: int = 3               # Nombre de projectiles créés
var fork_range: float = 200.0         # Portée de détection des cibles
var fork_damage_ratio: float = 0.6    # Ratio de dégâts pour les forks
var fork_speed_ratio: float = 0.8     # Ratio de vitesse pour les forks
var piercing_power: int = 0           # Nombre de cibles traversées avant fork
#var homing_strength: float = 0.0      # Force d'attraction vers les cibles
var spread_angle: float = PI / 3      # Angle de dispersion (60°)
var damage_multiplier: float = 1.0    # Multiplicateur de dégâts
var range_multiplier: float = 1.0     # Multiplicateur de portée

# Variables internes
var has_forked: bool = false
var targets_pierced: int = 0

func _ready():
	super._ready()
	setup_fork_arrow()

func setup_fork_arrow():
	if sprite:
		sprite.modulate = Color.PURPLE
		# Rotation selon la direction
		if direction != Vector2.ZERO:
			sprite.rotation = direction.angle()

func _physics_process(delta):
	super._physics_process(delta)
	
	# Homing léger vers les cibles si configuré
	if homing_strength > 0:
		apply_homing_force(delta)
	
	# Mettre à jour la rotation
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
	
	# Vérifier si on peut toucher cette cible
	if not should_damage_target(body):
		return
	
	# Infliger les dégâts initiaux
	if body.has_method("take_damage"):
		var initial_damage = damage * damage_multiplier
		body.take_damage(initial_damage)
		print("✅ Initial damage: ", initial_damage)
		targets_pierced += 1
	
	# Vérifier si on doit forker ou continuer à percer
	if targets_pierced < piercing_power:
		# Continuer à percer
		print("🏹 Arrow pierces through (", targets_pierced, "/", piercing_power, ")")
		return
	
	# Fork si pas encore fait
	if not has_forked:
		create_fork_projectiles(body.global_position)
		has_forked = true
	
	queue_free()

func create_fork_projectiles(impact_position: Vector2):
	print("🏹 Creating ", fork_count, " fork arrows!")
	
	# Trouver les cibles proches
	var nearby_targets = find_nearby_targets(impact_position)
	
	# Créer les projectiles fork
	for i in range(fork_count):
		var fork = create_fork_projectile()
		if not fork:
			continue
		
		get_tree().current_scene.add_child(fork)
		fork.global_position = impact_position
		
		var fork_direction = calculate_fork_direction(i, nearby_targets, impact_position)
		fork.direction = fork_direction
		
		# Configuration de la fork
		var fork_damage = damage * fork_damage_ratio * damage_multiplier
		var fork_speed = speed * fork_speed_ratio
		var fork_lifetime = lifetime * 0.7
		
		fork.setup(fork_damage, fork_speed, fork_lifetime)
		
		print("🏹 Fork ", i+1, " launched towards ", fork_direction)

func find_nearby_targets(impact_position: Vector2) -> Array:
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	var nearby_targets = []
	
	var effective_range = fork_range * range_multiplier
	
	# Filtrer les cibles dans la portée
	for target in potential_targets:
		var distance = impact_position.distance_to(target.global_position)
		if distance <= effective_range and distance > 20:  # Pas trop proche
			nearby_targets.append({
				"target": target,
				"distance": distance,
				"position": target.global_position
			})
	
	# Trier par distance (plus proches en premier)
	nearby_targets.sort_custom(func(a, b): return a.distance < b.distance)
	
	return nearby_targets

func calculate_fork_direction(fork_index: int, nearby_targets: Array, impact_position: Vector2) -> Vector2:
	if fork_index < nearby_targets.size():
		# Viser une cible spécifique
		var target_pos = nearby_targets[fork_index].position
		return (target_pos - impact_position).normalized()
	else:
		# Direction en éventail si pas assez de cibles
		var base_angle = direction.angle()
		var angle_step = spread_angle / fork_count
		var fork_angle = base_angle - (spread_angle / 2) + (fork_index * angle_step)
		
		# Ajouter une variation aléatoire
		fork_angle += randf_range(-PI/12, PI/12)  # ±15 degrés
		
		return Vector2(cos(fork_angle), sin(fork_angle))

func create_fork_projectile() -> BaseProjectile:
	# Créer un projectile basique pour les forks
	var fork_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
	
	if not ResourceLoader.exists(fork_scene_path):
		print("ERROR: Cannot create fork - BasicProjectile scene not found")
		return null
	
	var fork_scene = load(fork_scene_path)
	var fork_projectile = fork_scene.instantiate()
	
	# Configuration de la fork
	fork_projectile.set_owner_type(owner_type)
	
	# Apparence différente pour les forks
	if fork_projectile.sprite:
		fork_projectile.sprite.modulate = Color.LIGHT_BLUE
		fork_projectile.sprite.scale = Vector2(0.7, 0.7)
	
	return fork_projectile

# === MÉTHODES POUR FUTURS ACCESSOIRES ===
func apply_accessory_modifiers(modifiers: Dictionary):
	# Exemple d'utilisation future :
	# fork_arrow.apply_accessory_modifiers({
	#   "fork_count_bonus": 2,
	#   "damage_multiplier": 1.3,
	#   "piercing_power_bonus": 1,
	#   "homing_strength": 2.0
	# })
	
	if modifiers.has("fork_count_bonus"):
		fork_count += modifiers.fork_count_bonus
	
	if modifiers.has("damage_multiplier"):
		damage_multiplier *= modifiers.damage_multiplier
	
	if modifiers.has("range_multiplier"):
		range_multiplier *= modifiers.range_multiplier
	
	if modifiers.has("piercing_power_bonus"):
		piercing_power += modifiers.piercing_power_bonus
	
	if modifiers.has("homing_strength"):
		homing_strength = modifiers.homing_strength
	
	if modifiers.has("fork_damage_ratio_bonus"):
		fork_damage_ratio += modifiers.fork_damage_ratio_bonus
	
	if modifiers.has("spread_angle_modifier"):
		spread_angle += modifiers.spread_angle_modifier
	
	print("Fork Arrow modifiers applied: ", modifiers)

# Méthode pour configurer des patterns spéciaux
func set_fork_pattern(pattern: String):
	match pattern:
		"shotgun":
			fork_count = 5
			spread_angle = PI / 2  # 90 degrés
			fork_damage_ratio = 0.4
		"sniper":
			fork_count = 1
			homing_strength = 3.0
			fork_damage_ratio = 1.2
		"chain":
			fork_count = 3
			homing_strength = 1.5
			fork_range *= 1.5
		"piercing":
			piercing_power = 2
			fork_count = 2
			fork_damage_ratio = 0.8

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true
