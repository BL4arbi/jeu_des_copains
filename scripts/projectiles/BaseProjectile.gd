# === BaseProjectile.gd ===
# Nouveau système complet avec Area2D
extends Area2D
class_name BaseProjectile

# Stats de base
var damage: float = 10.0
var speed: float = 400.0
var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT

# Propriétaire et comportement
var owner_type: String = "neutral"  # "player", "enemy", "neutral"
var projectile_type: String = "basic"  # "basic", "lightning", "meteor", "fork", "bounce"

# Effets de statut
var has_status_effect: bool = false
var status_type: String = ""  # "slow", "poison", "burn", "freeze"
var status_duration: float = 3.0
var status_power: float = 1.0

# Comportement spécial
var bounces_remaining: int = 0
var max_bounces: int = 0
var pierces_remaining: int = 0
var max_pierces: int = 0
var homing_strength: float = 0.0
var homing_target: Node2D = null

# Composants
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

# Variables internes
var lifetime_timer: float = 0.0
var targets_hit: Array = []

func _ready():
	# Connecter les signaux
	body_entered.connect(_on_hit_target)
	area_entered.connect(_on_hit_area)
	
	# Configuration initiale
	setup_collision_layers()
	setup_visual_effects()
	
	print("Projectile created: ", projectile_type, " | Owner: ", owner_type)

func setup_collision_layers():
	match owner_type:
		"player":
			collision_layer = 4  # Layer 3 (2^2 = 4)
			collision_mask = 2   # Peut toucher enemies (Layer 2)
		"enemy":
			collision_layer = 8  # Layer 4 (2^3 = 8)  
			collision_mask = 1   # Peut toucher players (Layer 1)
		_:
			collision_layer = 16 # Layer 5 (2^4 = 16)
			collision_mask = 3   # Peut toucher players et enemies

func setup_visual_effects():
	if not sprite:
		return
	
	# Couleur selon le propriétaire
	var base_color = Color.WHITE
	match owner_type:
		"player":
			base_color = Color.CYAN
		"enemy":
			base_color = Color.RED
		_:
			base_color = Color.WHITE
	
	# Modifier selon le type de projectile
	match projectile_type:
		"lightning":
			base_color = Color.YELLOW
			sprite.modulate = base_color
			if animation_player and animation_player.has_animation("lightning_effect"):
				animation_player.play("lightning_effect")
		"meteor":
			base_color = Color.ORANGE
			sprite.modulate = base_color
			if animation_player and animation_player.has_animation("meteor_trail"):
				animation_player.play("meteor_trail")
		"fork":
			base_color = Color.PURPLE
			sprite.modulate = base_color
		"bounce":
			base_color = Color.GREEN
			sprite.modulate = base_color
		_:
			sprite.modulate = base_color
	
	# Effet de statut (modifier la couleur)
	if has_status_effect:
		match status_type:
			"poison":
				sprite.modulate = Color.GREEN * 1.5
			"burn":
				sprite.modulate = Color.RED * 1.5
			"slow":
				sprite.modulate = Color.BLUE * 1.5
			"freeze":
				sprite.modulate = Color.LIGHT_BLUE * 1.5

func set_owner_type(type: String):
	owner_type = type
	call_deferred("setup_collision_layers")

func set_projectile_type(type: String):
	projectile_type = type
	
	# Configurer les propriétés selon le type
	match type:
		"lightning":
			speed *= 2.0  # Plus rapide
			lifetime = 1.0  # Courte durée
		"meteor":
			speed *= 0.5  # Plus lent
			damage *= 2.0  # Plus de dégâts
		"fork":
			# Sera configuré lors du tir
			pass
		"bounce":
			max_bounces = 3
			bounces_remaining = max_bounces
	
	setup_visual_effects()

func add_status_effect(type: String, duration: float = 3.0, power: float = 1.0):
	has_status_effect = true
	status_type = type
	status_duration = duration
	status_power = power
	setup_visual_effects()

func setup(projectile_damage: float, projectile_speed: float, projectile_lifetime: float):
	damage = projectile_damage
	speed = projectile_speed
	lifetime = projectile_lifetime

func launch(start_position: Vector2, target_position: Vector2):
	global_position = start_position
	direction = (target_position - start_position).normalized()
	
	# Effets spéciaux au lancement
	match projectile_type:
		"homing":
			find_homing_target()

func _physics_process(delta):
	# Mouvement de base
	match projectile_type:
		"homing":
			handle_homing_movement(delta)
		"meteor":
			handle_meteor_movement(delta)
		_:
			handle_basic_movement(delta)
	
	# Timer de vie
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		on_lifetime_end()

func handle_basic_movement(delta):
	global_position += direction * speed * delta

func handle_homing_movement(delta):
	if homing_target and is_instance_valid(homing_target):
		var target_direction = (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength * delta)
	
	global_position += direction * speed * delta

func handle_meteor_movement(delta):
	# Mouvement en arc avec gravité
	var gravity = Vector2(0, 200)  # Gravité vers le bas
	direction += gravity * delta
	global_position += direction * speed * delta

func find_homing_target():
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var closest_target = null
	var closest_distance = 500.0  # Portée max du homing
	
	for target in potential_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	homing_target = closest_target
	homing_strength = 2.0

func _on_hit_target(body):
	print("Projectile hit body: ", body.name, " | Type: ", projectile_type)
	
	# Vérifier si on peut toucher cette cible
	if not should_damage_target(body):
		return
	
	# Éviter de toucher la même cible plusieurs fois (sauf si piercing)
	if body in targets_hit and pierces_remaining <= 0:
		return
	
	# Infliger les dégâts
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("✅ Damage dealt: ", damage)
		
		# Appliquer l'effet de statut
		if has_status_effect and body.has_method("apply_status_effect"):
			body.apply_status_effect(status_type, status_duration, status_power)
	
	targets_hit.append(body)
	
	# Gestion des effets spéciaux
	match projectile_type:
		"fork":
			create_fork_projectiles(body.global_position)
		"bounce":
			handle_bounce(body)
		"lightning":
			create_lightning_chain(body)
	
	# Détruire ou continuer selon le type
	if pierces_remaining > 0:
		pierces_remaining -= 1
	elif bounces_remaining > 0:
		# Le bounce est géré séparément
		pass
	else:
		on_impact()

func _on_hit_area(area):
	# Gestion des collisions avec d'autres Area2D (autres projectiles, etc.)
	print("Projectile hit area: ", area.name)

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true

func create_fork_projectiles(impact_position: Vector2):
	var fork_count = 3
	var fork_angle = PI / 3  # 60 degrés
	
	for i in range(fork_count):
		var angle_offset = (i - 1) * fork_angle / 2
		var fork_direction = direction.rotated(angle_offset)
		
		# Créer un nouveau projectile
		var fork_projectile = duplicate()
		get_tree().current_scene.add_child(fork_projectile)
		
		fork_projectile.global_position = impact_position
		fork_projectile.direction = fork_direction
		fork_projectile.damage *= 0.7  # Dégâts réduits pour les forks
		fork_projectile.projectile_type = "basic"  # Éviter la récursion

func handle_bounce(hit_body):
	if bounces_remaining <= 0:
		on_impact()
		return
	
	bounces_remaining -= 1
	
	# Calculer la nouvelle direction (bounce simple)
	var surface_normal = (global_position - hit_body.global_position).normalized()
	direction = direction.bounce(surface_normal)
	
	# Chercher une nouvelle cible proche
	find_homing_target()

func create_lightning_chain(first_target):
	var chain_range = 150.0
	var chain_damage = damage * 0.6
	
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in potential_targets:
		if target == first_target or target in targets_hit:
			continue
		
		var distance = first_target.global_position.distance_to(target.global_position)
		if distance <= chain_range:
			# Créer un effet visuel de chaîne (optionnel)
			if target.has_method("take_damage"):
				target.take_damage(chain_damage)
			break

func on_impact():
	# Effets spéciaux à l'impact
	match projectile_type:
		"meteor":
			create_explosion_effect()
	
	queue_free()

func on_lifetime_end():
	# Effets spéciaux en fin de vie
	match projectile_type:
		"meteor":
			create_explosion_effect()
	
	queue_free()

func create_explosion_effect():
	# Créer une zone d'explosion
	var explosion_radius = 100.0
	var explosion_damage = damage * 0.5
	
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in potential_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance <= explosion_radius:
			if target.has_method("take_damage"):
				target.take_damage(explosion_damage)
				print("💥 Explosion damage: ", explosion_damage, " to ", target.name)
