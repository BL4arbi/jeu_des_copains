# BaseProjectile.gd - Version corrigée pour penetration et lifesteal
extends Area2D
class_name BaseProjectile

# Stats de base
var damage: float = 10.0
var speed: float = 400.0
var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT
var bounces_remaining: int = 0
var max_bounces: int = 0
var bounce_range: float = 200.0  # Portée de recherche pour le prochain rebond
var bounce_damage_multiplier: float = 0.8  # Réduction des dégâts à chaque rebond
var pierces_remaining: int = 0
var max_pierces: int = 0
var homing_strength: float = 0.0
var homing_target: Node2D = null

# Propriétaire et comportement
var owner_type: String = "neutral"
var projectile_type: String = "basic"

# Effets de statut
var has_status_effect: bool = false
var status_type: String = ""
var status_duration: float = 3.0
var status_power: float = 1.0



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
	
	print("Projectile created: ", projectile_type, " | Owner: ", owner_type, " | Pierces: ", pierces_remaining)

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
		"meteor":
			base_color = Color.ORANGE
		"fork":
			base_color = Color.PURPLE
		"bounce":
			base_color = Color.GREEN
		"homing":
			base_color = Color.MAGENTA
	
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
			homing_strength = 3.0
			call_deferred("find_homing_target")
	
	setup_visual_effects()

func add_status_effect(type: String, duration: float = 3.0, power: float = 1.0):
	has_status_effect = true
	status_type = type
	status_duration = duration
	status_power = power
	setup_visual_effects()
	print("Projectile status effect added: ", type, " power: ", power)

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
	if not homing_target or not is_instance_valid(homing_target):
		find_homing_target()
	
	if homing_target and is_instance_valid(homing_target):
		var target_direction = (homing_target.global_position - global_position).normalized()
		var turn_strength = homing_strength * delta
		direction = direction.lerp(target_direction, turn_strength).normalized()
		
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

func _on_hit_target(body):
	print("Projectile hit body: ", body.name, " | Pierces left: ", pierces_remaining)
	
	if not should_damage_target(body):
		return
	
	# === CORRECTION PENETRATION ===
	# Ne plus vérifier si la cible est déjà touchée pour la penetration
	# Laisser le projectile traverser et continuer
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("✅ Damage dealt: ", damage)
		
		# === APPLIQUER LE LIFESTEAL ===
		if owner_type == "player":
			var player = get_tree().get_first_node_in_group("players")
			if player and player.has_method("apply_lifesteal_on_damage"):
				player.apply_lifesteal_on_damage(damage)
		
		# Effets de statut
		if has_status_effect and body.has_method("apply_status_effect"):
			body.apply_status_effect(status_type, status_duration, status_power)
			print("Applied status: ", status_type, " to ", body.name)
	
	# Ajouter à la liste des cibles touchées pour éviter les multihits instantanés
	targets_hit.append(body)
	
	# === GESTION DE LA PENETRATION CORRIGÉE ===
	if pierces_remaining > 0:
		pierces_remaining -= 1
		print("🏹 Pierced through ", body.name, "! Pierces left: ", pierces_remaining)
		
		# Effet visuel de perforation
		create_pierce_effect(body.global_position)
		
		# Le projectile continue sans être détruit
		return
	
	# === GESTION DES AUTRES TYPES ===
	match projectile_type:
		"fork":
			create_fork_projectiles(body.global_position)
		"bounce":
			handle_bounce(body)
		"lightning":
			create_lightning_chain(body)
		"homing":
			# Homing continue après avoir touché si pierces
			if pierces_remaining > 0:
				find_homing_target()
				return
	
	# Détruire le projectile si plus de pierces ou comportement normal
	if bounces_remaining > 0:
		pass  # Bounce géré dans handle_bounce
	else:
		on_impact()

func create_pierce_effect(position: Vector2):
	# Effet visuel quand le projectile perfore
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	# Cercle jaune pour la perforation
	var effect_size = 32
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(effect_size / 2, effect_size / 2)
	
	for x in range(effect_size):
		for y in range(effect_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effect_size / 2:
				var alpha = 1.0 - (distance / (effect_size / 2))
				image.set_pixel(x, y, Color(1.0, 1.0, 0.0, alpha))  # Jaune
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation de l'effet
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): effect.queue_free())

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
				
				# Lifesteal sur chain
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(chain_damage)
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
				
				# Lifesteal sur explosion
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(explosion_damage)


# ... (garder le code existant jusqu'aux variables de rebond)

# AMÉLIORATION : Variables de rebond

var last_bounce_target: Node2D = null  # NOUVEAU : éviter de rebondir sur la même cible

# ... (garder le code existant jusqu'à la méthode handle_bounce)

func handle_bounce(hit_body):
	if bounces_remaining <= 0:
		on_impact()
		return
	
	bounces_remaining -= 1
	last_bounce_target = hit_body  # Mémoriser la dernière cible
	
	# Réduction des dégâts à chaque rebond
	damage *= bounce_damage_multiplier
	
	print("🪃 Bounce! Remaining: ", bounces_remaining, " | New damage: ", damage)
	
	# NOUVEAU : Trouver la meilleure cible pour rebondir
	var best_target = find_best_bounce_target(hit_body)
	
	if best_target:
		# Rebond dirigé vers la nouvelle cible
		var new_direction = (best_target.global_position - global_position).normalized()
		direction = new_direction
		
		# Accélération légère pour un effet cool
		speed *= 1.1
		
		print("🪃 Bouncing to: ", best_target.name, " at distance: ", int(global_position.distance_to(best_target.global_position)))
	else:
		# Aucune cible trouvée - rebond aléatoire
		var random_angle = randf() * TAU
		direction = Vector2(cos(random_angle), sin(random_angle))
		print("🪃 Random bounce (no targets)")
	
	# Effet visuel de rebond
	create_bounce_effect()
	
	# Son de rebond (si tu as des sons plus tard)
	# AudioManager.play_sound("bounce")

func find_best_bounce_target(current_target: Node2D) -> Node2D:
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var valid_targets = []
	
	# Filtrer les cibles valides
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		# Éviter la cible actuelle et la précédente
		if target == current_target or target == last_bounce_target:
			continue
		
		# Éviter les cibles déjà touchées (pour certains types de projectiles)
		if target in targets_hit and pierces_remaining <= 0:
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance <= bounce_range:
			valid_targets.append({
				"target": target,
				"distance": distance,
				"priority": calculate_bounce_priority(target, distance)
			})
	
	if valid_targets.is_empty():
		return null
	
	# Trier par priorité (distance + autres facteurs)
	valid_targets.sort_custom(func(a, b): return a.priority > b.priority)
	
	return valid_targets[0].target

func calculate_bounce_priority(target: Node2D, distance: float) -> float:
	# Système de priorité pour choisir la meilleure cible
	var priority = 100.0
	
	# Plus proche = meilleure priorité
	var distance_factor = 1.0 - (distance / bounce_range)
	priority += distance_factor * 50.0
	
	# Bonus selon le type d'ennemi (si applicable)
	if target.has_method("get") and target.get("enemy_type"):
		match target.enemy_type:
			"Elite":
				priority += 30.0  # Priorité élevée pour les Elite
			"Shooter":
				priority += 20.0  # Priorité moyenne pour les Shooter
			"Grunt":
				priority += 10.0  # Priorité normale pour les Grunt
	
	# Bonus pour les ennemis avec peu de vie (finisher)
	if target.has_method("get") and target.get("current_health"):
		var health_ratio = target.current_health / target.max_health
		if health_ratio < 0.3:  # Moins de 30% de vie
			priority += 25.0
	
	# Malus si c'est une cible déjà touchée
	if target in targets_hit:
		priority -= 40.0
	
	return priority

func create_bounce_effect():
	# Effet visuel de rebond
	var bounce_effect = Sprite2D.new()
	get_tree().current_scene.add_child(bounce_effect)
	
	# Créer un effet d'onde de choc
	var effect_size = 40
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(effect_size / 2, effect_size / 2)
	
	for x in range(effect_size):
		for y in range(effect_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effect_size / 2:
				var alpha = 1.0 - (distance / (effect_size / 2))
				var bounce_color = Color.YELLOW if owner_type == "player" else Color.ORANGE
				image.set_pixel(x, y, Color(bounce_color.r, bounce_color.g, bounce_color.b, alpha * 0.8))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	bounce_effect.texture = texture
	bounce_effect.global_position = global_position - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation d'expansion
	var tween = create_tween()
	tween.parallel().tween_property(bounce_effect, "scale", Vector2(3.0, 3.0), 0.4)
	tween.parallel().tween_property(bounce_effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): 
		if is_instance_valid(bounce_effect):
			bounce_effect.queue_free()
	)

# AMÉLIORATION : Configuration facile du rebond
func setup_bouncing_projectile(max_bounces_count: int, bounce_range_distance: float = 200.0, damage_reduction: float = 0.8):
	projectile_type = "bounce"
	max_bounces = max_bounces_count
	bounces_remaining = max_bounces
	bounce_range = bounce_range_distance
	bounce_damage_multiplier = damage_reduction
	
	print("🪃 Bouncing projectile setup: ", max_bounces, " bounces, ", bounce_range, " range, ", int(damage_reduction * 100), "% damage retention")

# NOUVEAU : Méthode pour les armes qui créent des projectiles rebondissants
func configure_as_boomerang():
	setup_bouncing_projectile(5, 250.0, 0.9)  # 5 rebonds, longue portée, faible réduction
	projectile_type = "boomerang"
	
	# Effet visuel spécial pour boomerang
	if sprite:
		sprite.modulate = Color.CYAN
		# Rotation continue
		var rotation_tween = create_tween()
		rotation_tween.set_loops()
		rotation_tween.tween_property(sprite, "rotation", sprite.rotation + TAU, 0.5)

# Méthode pour debug - afficher les cibles potentielles
func debug_show_bounce_targets():
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	print("🎯 Bounce targets in range:")
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance <= bounce_range:
			var priority = calculate_bounce_priority(target, distance)
			print("  - ", target.name, " | Distance: ", int(distance), " | Priority: ", int(priority))
