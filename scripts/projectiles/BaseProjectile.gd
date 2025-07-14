# BaseProjectile.gd - Version corrigée pour homing qui fonctionne
extends Area2D
class_name BaseProjectile

# Stats de base
var damage: float = 10.0
var speed: float = 400.0
var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT
var bounces_remaining: int = 0
var max_bounces: int = 0
var bounce_range: float = 200.0
var bounce_damage_multiplier: float = 0.8
var pierces_remaining: int = 0
var max_pierces: int = 0
var homing_strength: float = 0.0
var homing_target: Node2D = null
var homing_range: float = 400.0  # NOUVEAU : Range de détection

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
var homing_update_timer: float = 0.0  # NOUVEAU : Timer pour chercher cibles

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
# Dans BaseProjectile.gd - Fonction setup_visual_effects() corrigée
func setup_visual_effects():
	if not sprite:
		return
	
	var base_color = Color.WHITE
	
	# COULEURS SELON LE PROPRIÉTAIRE
	match owner_type:
		"player":
			base_color = Color.CYAN  # Bleu cyan pour le joueur
		"enemy":
			base_color = Color.ORANGE_RED  # Rouge-orange pour les ennemis
		_:
			base_color = Color.WHITE
	
	# COULEURS SELON LE TYPE DE PROJECTILE
	match projectile_type:
		"lightning":
			if owner_type == "player":
				base_color = Color.YELLOW  # Jaune électrique pour joueur
			else:
				base_color = Color.PURPLE  # Violet sombre pour ennemis
		"meteor":
			if owner_type == "player":
				base_color = Color.ORANGE  # Orange pour joueur
			else:
				base_color = Color.DARK_RED  # Rouge sombre pour ennemis
		"fork":
			if owner_type == "player":
				base_color = Color.PURPLE  # Violet pour joueur
			else:
				base_color = Color.MAROON  # Marron rouge pour ennemis
		"bounce":
			if owner_type == "player":
				base_color = Color.GREEN  # Vert pour joueur
			else:
				base_color = Color.DARK_GREEN  # Vert sombre pour ennemis
		"homing":
			if owner_type == "player":
				base_color = Color.MAGENTA  # Magenta pour joueur
			else:
				base_color = Color.DARK_RED  # Rouge sombre pour ennemis
		"laser":
			if owner_type == "player":
				base_color = Color.CYAN  # Cyan pour joueur
			else:
				base_color = Color.RED  # Rouge pour ennemis
		"nova":
			if owner_type == "player":
				base_color = Color.PURPLE  # Violet pour joueur
			else:
				base_color = Color.DARK_RED  # Rouge sombre pour ennemis
		"apocalypse":
			if owner_type == "player":
				base_color = Color.GOLD  # Or pour joueur
			else:
				base_color = Color.DARK_RED  # Rouge sombre pour ennemis
		"singularity":
			if owner_type == "player":
				base_color = Color.PURPLE  # Violet pour joueur
			else:
				base_color = Color.BLACK  # Noir pour ennemis
	
	sprite.modulate = base_color
	
	# COULEURS DES EFFETS DE STATUT (superposées)
	if has_status_effect:
		var status_tint = Color.WHITE
		match status_type:
			"poison":
				status_tint = Color.GREEN * 1.5
			"burn":
				status_tint = Color.RED * 1.5
			"slow":
				status_tint = Color.BLUE * 1.5
			"freeze":
				status_tint = Color.LIGHT_BLUE * 1.5
		
		# Mélanger la couleur de statut avec la couleur de base
		sprite.modulate = base_color.lerp(status_tint, 0.3)

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
			homing_strength = 5.0  # AUGMENTÉ pour plus de réactivité
			homing_range = 500.0
			print("🎯 Homing projectile configured: strength=", homing_strength, " range=", homing_range)
			call_deferred("find_homing_target")
	
	setup_visual_effects()

func add_status_effect(type: String, duration: float = 3.0, power: float = 1.0):
	has_status_effect = true
	status_type = type
	status_duration = duration
	status_power = power
	setup_visual_effects()
	print("Projectile status effect added: ", type, " power: ", power)

func setup(dmg: float, spd: float, lifetime: float, player_ref: Player = null):
	damage = dmg
	speed = spd
	max_lifetime = lifetime
	owner_player = player_ref

func launch(start_position: Vector2, target_position: Vector2):
	global_position = start_position
	direction = (target_position - start_position).normalized()
	
	# Rotation du sprite selon la direction
	if sprite:
		sprite.rotation = direction.angle()
	
	# CORRECTION : Chercher une cible immédiatement pour homing
	if projectile_type == "homing":
		find_homing_target()

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

# CORRECTION MAJEURE : Nouveau système de homing qui fonctionne
func handle_homing_movement(delta):
	# Mettre à jour le timer de recherche de cibles
	homing_update_timer += delta
	
	# Chercher une nouvelle cible toutes les 0.2 secondes
	if homing_update_timer >= 0.2:
		if not homing_target or not is_instance_valid(homing_target):
			find_homing_target()
		homing_update_timer = 0.0
	
	# Si on a une cible valide, se diriger vers elle
	if homing_target and is_instance_valid(homing_target):
		var distance_to_target = global_position.distance_to(homing_target.global_position)
		
		# Vérifier que la cible est encore dans la portée
		if distance_to_target <= homing_range:
			var target_direction = (homing_target.global_position - global_position).normalized()
			
			# CORRECTION : Force de guidage plus importante et plus fluide
			var turn_rate = homing_strength * delta
			direction = direction.lerp(target_direction, turn_rate).normalized()
			
			# Effet visuel pour montrer le homing
			if sprite:
				sprite.modulate = Color.MAGENTA
				# Légère augmentation de vitesse quand on a une cible
				var current_speed = speed * 1.1
				global_position += direction * current_speed * delta
			else:
				global_position += direction * speed * delta
			
			print("🎯 Homing to: ", homing_target.name, " at distance: ", int(distance_to_target))
		else:
			# Cible trop loin, chercher une nouvelle cible
			homing_target = null
			global_position += direction * speed * delta
	else:
		# Pas de cible, mouvement normal
		global_position += direction * speed * delta

# CORRECTION MAJEURE : Méthode de recherche de cibles améliorée
func find_homing_target():
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	if potential_targets.is_empty():
		print("🎯 No potential targets in group: ", target_group)
		return
	
	var best_target = null
	var closest_distance = homing_range
	
	print("🎯 Searching for homing target among ", potential_targets.size(), " candidates")
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		# Éviter les cibles déjà touchées (si pas de penetration)
		if target in targets_hit and pierces_remaining <= 0:
			continue
		
		var distance = global_position.distance_to(target.global_position)
		print("🎯 Target candidate: ", target.name, " at distance: ", int(distance))
		
		if distance < closest_distance:
			closest_distance = distance
			best_target = target
	
	if best_target:
		homing_target = best_target
		print("🎯 HOMING TARGET ACQUIRED: ", best_target.name, " at distance: ", int(closest_distance))
		
		# Effet visuel pour montrer qu'on a trouvé une cible
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		homing_target = null
		print("🎯 No valid homing target found")

func handle_meteor_movement(delta):
	var gravity_force = Vector2(0, 200)
	direction += gravity_force * delta
	global_position += direction * speed * delta

func _on_hit_target(body):
	print("Projectile hit body: ", body.name, " | Pierces left: ", pierces_remaining)
	
	if not should_damage_target(body):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("✅ Damage dealt: ", damage)
		
		# Lifesteal
		if owner_type == "player":
			var player = get_tree().get_first_node_in_group("players")
			if player and player.has_method("apply_lifesteal_on_damage"):
				player.apply_lifesteal_on_damage(damage)
		
		# Effets de statut
		if has_status_effect and body.has_method("apply_status_effect"):
			body.apply_status_effect(status_type, status_duration, status_power)
			print("Applied status: ", status_type, " to ", body.name)
	
	# Ajouter à la liste des cibles touchées
	targets_hit.append(body)
	
	# Gestion de la penetration
	if pierces_remaining > 0:
		pierces_remaining -= 1
		print("🏹 Pierced through ", body.name, "! Pierces left: ", pierces_remaining)
		create_pierce_effect(body.global_position)
		
		# CORRECTION : Pour homing, chercher une nouvelle cible après penetration
		if projectile_type == "homing":
			call_deferred("find_homing_target")
		
		return
	
	# Gestion des autres types
	match projectile_type:
		"fork":
			create_fork_projectiles(body.global_position)
		"bounce":
			handle_bounce(body)
		"lightning":
			create_lightning_chain(body)
		"homing":
			# Homing se détruit après avoir touché (sauf si penetration)
			pass
	
	if bounces_remaining > 0:
		pass  # Bounce géré dans handle_bounce
	else:
		on_impact()

func create_pierce_effect(position: Vector2):
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var effect_size = 32
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(effect_size / 2, effect_size / 2)
	
	for x in range(effect_size):
		for y in range(effect_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effect_size / 2:
				var alpha = 1.0 - (distance / (effect_size / 2))
				image.set_pixel(x, y, Color(1.0, 1.0, 0.0, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position - Vector2(effect_size / 2, effect_size / 2)
	
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
				
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(chain_damage)
			break

func handle_bounce(hit_body):
	if bounces_remaining <= 0:
		on_impact()
		return
	
	bounces_remaining -= 1
	damage *= bounce_damage_multiplier
	
	print("🪃 Bounce! Remaining: ", bounces_remaining, " | New damage: ", damage)
	
	var best_target = find_best_bounce_target(hit_body)
	
	if best_target:
		var new_direction = (best_target.global_position - global_position).normalized()
		direction = new_direction
		speed *= 1.1
		print("🪃 Bouncing to: ", best_target.name)
	else:
		var random_angle = randf() * TAU
		direction = Vector2(cos(random_angle), sin(random_angle))
		print("🪃 Random bounce (no targets)")
	
	create_bounce_effect()

func find_best_bounce_target(current_target: Node2D) -> Node2D:
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var best_target = null
	var closest_distance = bounce_range
	
	for target in potential_targets:
		if not is_instance_valid(target) or target == current_target:
			continue
		
		if target in targets_hit and pierces_remaining <= 0:
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			best_target = target
	
	return best_target

func create_bounce_effect():
	var bounce_effect = Sprite2D.new()
	get_tree().current_scene.add_child(bounce_effect)
	
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
	
	var tween = create_tween()
	tween.parallel().tween_property(bounce_effect, "scale", Vector2(3.0, 3.0), 0.4)
	tween.parallel().tween_property(bounce_effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): 
		if is_instance_valid(bounce_effect):
			bounce_effect.queue_free()
	)

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
				
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(explosion_damage)
# Code à ajouter dans ta classe Projectile

# === VARIABLES À AJOUTER ===
var owner_player: Player = null  # Référence au joueur qui a tiré

# === MODIFIER TA FONCTION setup() ===
  # Stocker la référence du joueur

# === MODIFIER TA FONCTION DE COLLISION AVEC LES ENNEMIS ===
func _on_enemy_hit(enemy):
	if not enemy.is_in_group("enemies"):
		return
	
	# Appliquer les dégâts normaux
	enemy.take_damage(damage)
	
	# Appliquer les effets de statut si le joueur en a
	if owner_player:
		var buff_system = get_tree().get_first_node_in_group("buff_system")
		if buff_system and buff_system.has_method("apply_bullet_effects_to_enemy"):
			buff_system.apply_bullet_effects_to_enemy(enemy, owner_player)
	
	# Effet visuel d'impact
	create_impact_effect()
	
	# Détruire le projectile (sauf si penetration)
	queue_free()

# === FONCTION POUR EFFET VISUEL D'IMPACT ===
func create_impact_effect():
	var impact = Sprite2D.new()
	get_tree().current_scene.add_child(impact)
	
	var image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color.YELLOW)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	impact.texture = texture
	impact.global_position = global_position
	
	var tween = create_tween()
	tween.tween_property(impact, "scale", Vector2(2, 2), 0.2)
	tween.tween_property(impact, "modulate", Color.TRANSPARENT, 0.1)
	tween.tween_callback(impact.queue_free)
