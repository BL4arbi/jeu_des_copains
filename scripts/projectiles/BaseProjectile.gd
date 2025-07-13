# BaseProjectile.gd - Corrections pour homing et bouncing
extends Area2D
class_name BaseProjectile

# Stats de base
var damage: float = 10.0
var speed: float = 400.0
var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT

# Propriétaire et comportement
var owner_type: String = "neutral"
var projectile_type: String = "basic"

# Effets de statut
var has_status_effect: bool = false
var status_type: String = ""
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
	body_entered.connect(_on_hit_target)
	area_entered.connect(_on_hit_area)
	
	setup_collision_layers()
	setup_visual_effects()
	
	print("Projectile created: ", projectile_type, " | Owner: ", owner_type)

func setup_collision_layers():
	match owner_type:
		"player":
			collision_layer = 4
			collision_mask = 2
		"enemy":
			collision_layer = 8
			collision_mask = 1
		_:
			collision_layer = 16
			collision_mask = 3

func setup_visual_effects():
	if not sprite:
		return
	
	var base_color = Color.WHITE
	match owner_type:
		"player":
			base_color = Color.CYAN
		"enemy":
			base_color = Color.RED
		_:
			base_color = Color.WHITE
	
	match projectile_type:
		"lightning":
			base_color = Color.YELLOW
			sprite.modulate = base_color
		"meteor":
			base_color = Color.ORANGE
			sprite.modulate = base_color
		"fork":
			base_color = Color.PURPLE
			sprite.modulate = base_color
		"bounce":
			base_color = Color.GREEN
			sprite.modulate = base_color
		"homing":
			base_color = Color.MAGENTA
			sprite.modulate = base_color
		_:
			sprite.modulate = base_color
	
	# Effet de statut
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
	
	match type:
		"lightning":
			speed *= 2.0
			lifetime = 1.0
		"meteor":
			speed *= 0.5
			damage *= 2.0
		"fork":
			pass
		"bounce":
			max_bounces = 3
			bounces_remaining = max_bounces
		"homing":
			# CORRECTION : Configuration automatique du homing
			homing_strength = 3.0
			call_deferred("find_homing_target")
	
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
	
	# Rotation du sprite selon la direction
	if sprite:
		sprite.rotation = direction.angle()
	
	match projectile_type:
		"homing":
			call_deferred("find_homing_target")

func _physics_process(delta):
	match projectile_type:
		"homing":
			handle_homing_movement(delta)
		"meteor":
			handle_meteor_movement(delta)
		_:
			handle_basic_movement(delta)
	
	# Rotation continue du sprite selon la direction
	if sprite and direction != Vector2.ZERO:
		sprite.rotation = direction.angle()
	
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		on_lifetime_end()

func handle_basic_movement(delta):
	global_position += direction * speed * delta

func handle_homing_movement(delta):
	# CORRECTION : Meilleur système de homing
	if not homing_target or not is_instance_valid(homing_target):
		find_homing_target()
	
	if homing_target and is_instance_valid(homing_target):
		var target_direction = (homing_target.global_position - global_position).normalized()
		# Interpolation plus fluide
		var turn_strength = homing_strength * delta
		direction = direction.lerp(target_direction, turn_strength).normalized()
		
		# Debug visuel
		if sprite:
			sprite.modulate = Color.MAGENTA
	
	global_position += direction * speed * delta

func handle_meteor_movement(delta):
	var gravity_force = Vector2(0, 200)
	direction += gravity_force * delta
	global_position += direction * speed * delta

func find_homing_target():
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var closest_target = null
	var closest_distance = 500.0
	
	for target in potential_targets:
		if target in targets_hit:
			continue
			
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	homing_target = closest_target
	
	if homing_target:
		print("🎯 Homing target acquired: ", homing_target.name)
	else:
		print("🎯 No homing target found")

func _on_hit_target(body):
	print("Projectile hit body: ", body.name, " | Type: ", projectile_type)
	
	if not should_damage_target(body):
		return
	
	if body in targets_hit and pierces_remaining <= 0:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("✅ Damage dealt: ", damage)
		
		if has_status_effect and body.has_method("apply_status_effect"):
			body.apply_status_effect(status_type, status_duration, status_power)
	
	targets_hit.append(body)
	
	match projectile_type:
		"fork":
			create_fork_projectiles(body.global_position)
		"bounce":
			handle_bounce(body)
		"lightning":
			create_lightning_chain(body)
		"homing":
			# Homing continue après avoir touché
			if pierces_remaining > 0:
				pierces_remaining -= 1
				find_homing_target()
				return
	
	if pierces_remaining > 0:
		pierces_remaining -= 1
	elif bounces_remaining > 0:
		pass
	else:
		on_impact()

func _on_hit_area(area):
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
	var fork_angle = PI / 3
	
	for i in range(fork_count):
		var angle_offset = (i - 1) * fork_angle / 2
		var fork_direction = direction.rotated(angle_offset)
		
		var fork_projectile = duplicate()
		get_tree().current_scene.add_child(fork_projectile)
		
		fork_projectile.global_position = impact_position
		fork_projectile.direction = fork_direction
		fork_projectile.damage *= 0.7
		fork_projectile.projectile_type = "basic"

func handle_bounce(hit_body):
	if bounces_remaining <= 0:
		on_impact()
		return
	
	bounces_remaining -= 1
	
	# CORRECTION : Meilleur système de bounce
	var surface_normal = (global_position - hit_body.global_position).normalized()
	direction = direction.bounce(surface_normal)
	
	# Trouver une nouvelle cible pour le bounce
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var closest_target = null
	var closest_distance = 200.0
	
	for target in potential_targets:
		if target == hit_body or target in targets_hit:
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	if closest_target:
		# Rediriger vers la nouvelle cible
		direction = (closest_target.global_position - global_position).normalized()
		print("🪃 Bouncing towards: ", closest_target.name)
	
	# Effet visuel de bounce
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

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
			if target.has_method("take_damage"):
				target.take_damage(chain_damage)
			break

func on_impact():
	match projectile_type:
		"meteor":
			create_explosion_effect()
	
	queue_free()

func on_lifetime_end():
	match projectile_type:
		"meteor":
			create_explosion_effect()
	
	queue_free()

func create_explosion_effect():
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
