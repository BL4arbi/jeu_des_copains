# MeteorProjectile.gd - Version modulaire avec variables configurables
extends BaseProjectile
class_name MeteorProjectile

# === VARIABLES CONFIGURABLES (pour futurs accessoires) ===
var meteor_count: int = 1             # Nombre de météores
var explosion_radius: float = 100.0   # Rayon d'explosion
var warning_time: float = 1.5         # Temps d'avertissement
var fall_speed: float = 200.0         # Vitesse de chute
var burn_duration: float = 3.0        # Durée de brûlure
var spawn_spread: float = 150.0       # Dispersion du spawn
var damage_multiplier: float = 1.0    # Multiplicateur de dégâts
var radius_multiplier: float = 1.0    # Multiplicateur de rayon
var speed_multiplier: float = 1.0     # Multiplicateur de vitesse

# Variables internes
var is_falling: bool = false
var warning_indicators: Array = []
var meteor_positions: Array = []

func _ready():
	super._ready()
	setup_meteor_behavior()

func setup_meteor_behavior():
	speed = 0  # Pas de mouvement initial
	lifetime = 8.0
	
	# Déterminer les positions d'impact
	calculate_meteor_positions()
	
	# Créer les avertissements
	create_impact_warnings()
	
	# Délai avant de faire tomber les météores
	var warning_timer = Timer.new()
	add_child(warning_timer)
	warning_timer.wait_time = warning_time
	warning_timer.one_shot = true
	warning_timer.timeout.connect(_on_start_meteor_rain)
	warning_timer.start()
	
	print("☄️ Preparing ", meteor_count, " meteors")

func calculate_meteor_positions():
	var launcher = get_tree().get_first_node_in_group("players") if owner_type == "player" else null
	if not launcher:
		launcher = get_tree().get_first_node_in_group("enemies")
	
	if not launcher:
		meteor_positions.append(global_position)
		return
	
	var center_pos = launcher.global_position
	
	for i in range(meteor_count):
		var meteor_pos: Vector2
		
		if meteor_count == 1:
			# Un seul météore au centre
			meteor_pos = center_pos
		else:
			# Plusieurs météores en cercle ou aléatoire
			if meteor_count <= 5:
				# Pattern circulaire
				var angle = (i * PI * 2) / meteor_count
				var distance = spawn_spread * 0.7
				meteor_pos = center_pos + Vector2(cos(angle), sin(angle)) * distance
			else:
				# Pattern aléatoire
				var random_offset = Vector2(
					randf_range(-spawn_spread, spawn_spread),
					randf_range(-spawn_spread, spawn_spread)
				)
				meteor_pos = center_pos + random_offset
		
		meteor_positions.append(meteor_pos)

func create_impact_warnings():
	clear_warnings()
	
	for meteor_pos in meteor_positions:
		var warning = create_warning_circle(meteor_pos)
		warning_indicators.append(warning)
		get_tree().current_scene.add_child(warning)

func create_warning_circle(position: Vector2) -> Sprite2D:
	var warning = Sprite2D.new()
	
	# Calculer le rayon effectif
	var effective_radius = explosion_radius * radius_multiplier
	var size = int(effective_radius * 2)
	
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effective_radius:
				var alpha = 0.6 * (1.0 - distance / effective_radius)
				# Couleur orange/rouge pour météore
				var color = Color.ORANGE_RED if owner_type == "player" else Color.DARK_RED
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	warning.texture = texture
	warning.global_position = position - Vector2(effective_radius, effective_radius)
	
	# Animation pulsante
	var pulse_speed = 0.4 / warning_time
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(warning, "scale", Vector2(1.2, 1.2), pulse_speed)
	tween.tween_property(warning, "scale", Vector2(0.8, 0.8), pulse_speed)
	
	return warning

func _on_start_meteor_rain():
	is_falling = true
	print("☄️ Meteors falling!")
	
	# Supprimer les avertissements
	clear_warnings()
	
	# Faire tomber chaque météore avec un délai
	for i in range(meteor_positions.size()):
		spawn_falling_meteor(meteor_positions[i])
		# Délai entre les météores
		await get_tree().create_timer(0.3).timeout
	
	queue_free()

func spawn_falling_meteor(impact_position: Vector2):
	# Créer un météore visible qui tombe
	var meteor_visual = Sprite2D.new()
	get_tree().current_scene.add_child(meteor_visual)
	
	# Position de départ dans le ciel
	var sky_position = impact_position + Vector2(0, -400)
	meteor_visual.global_position = sky_position
	
	# Apparence du météore
	var meteor_size = int(20 * radius_multiplier)
	var image = Image.create(meteor_size, meteor_size, false, Image.FORMAT_RGB8)
	image.fill(Color.ORANGE_RED)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	meteor_visual.texture = texture
	
	# Animation de chute
	var effective_speed = fall_speed * speed_multiplier
	var fall_time = 400.0 / effective_speed  # Temps pour parcourir 400 pixels
	
	var tween = create_tween()
	tween.parallel().tween_property(meteor_visual, "global_position", impact_position, fall_time)
	tween.parallel().tween_property(meteor_visual, "rotation", PI * 2, fall_time)
	
	# À l'impact
	tween.tween_callback(func(): 
		meteor_impact(impact_position)
		meteor_visual.queue_free()
	)

func meteor_impact(impact_position: Vector2):
	print("☄️ Meteor impact at ", impact_position)
	
	var effective_radius = explosion_radius * radius_multiplier
	var effective_damage = damage * damage_multiplier
	
	# Trouver toutes les cibles dans le rayon
	var target_group = "enemies" if owner_type == "player" else "players"
	var all_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in all_targets:
		var distance = impact_position.distance_to(target.global_position)
		if distance <= effective_radius:
			if target.has_method("take_damage"):
				# Dégâts selon la distance (plus fort au centre)
				var distance_ratio = 1.0 - (distance / effective_radius)
				var final_damage = effective_damage * distance_ratio
				target.take_damage(final_damage)
				
				# Effet de brûlure
				if target.has_method("apply_status_effect"):
					target.apply_status_effect("burn", burn_duration, 2.0)
				
				print("☄️ Meteor hit ", target.name, " for ", final_damage, " damage")
	
	# Effet visuel d'explosion
	create_meteor_explosion_effect(impact_position)

func create_meteor_explosion_effect(position: Vector2):
	# Créer plusieurs effets d'explosion
	for i in range(3):
		var explosion = Sprite2D.new()
		get_tree().current_scene.add_child(explosion)
		
		# Couleurs d'explosion variées
		var colors = [Color.ORANGE, Color.RED, Color.YELLOW]
		var explosion_color = colors[i % colors.size()]
		
		var explosion_size = int(32 * radius_multiplier)
		var image = Image.create(explosion_size, explosion_size, false, Image.FORMAT_RGBA8)
		image.fill(explosion_color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		explosion.texture = texture
		
		# Position aléatoire autour de l'impact
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30)) * radius_multiplier
		explosion.global_position = position + offset - Vector2(explosion_size / 2, explosion_size / 2)
		
		# Animation d'explosion avec délai
		var tween = create_tween()
		var delay = i * 0.1
		
		tween.tween_delay(delay)
		tween.parallel().tween_property(explosion, "scale", Vector2(3, 3), 0.4)
		tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
		tween.tween_callback(func(): explosion.queue_free())

func clear_warnings():
	for warning in warning_indicators:
		if is_instance_valid(warning):
			warning.queue_free()
	warning_indicators.clear()

# === MÉTHODES POUR FUTURS ACCESSOIRES ===
func apply_accessory_modifiers(modifiers: Dictionary):
	# Exemple d'utilisation future :
	# meteor.apply_accessory_modifiers({
	#   "meteor_count_bonus": 2,
	#   "damage_multiplier": 1.4,
	#   "radius_multiplier": 1.2
	# })
	
	if modifiers.has("meteor_count_bonus"):
		meteor_count += modifiers.meteor_count_bonus
	
	if modifiers.has("damage_multiplier"):
		damage_multiplier *= modifiers.damage_multiplier
	
	if modifiers.has("radius_multiplier"):
		radius_multiplier *= modifiers.radius_multiplier
	
	if modifiers.has("speed_multiplier"):
		speed_multiplier *= modifiers.speed_multiplier
	
	if modifiers.has("warning_time_reduction"):
		warning_time = max(0.5, warning_time - modifiers.warning_time_reduction)
	
	if modifiers.has("burn_duration_bonus"):
		burn_duration += modifiers.burn_duration_bonus
	
	if modifiers.has("spawn_spread_bonus"):
		spawn_spread += modifiers.spawn_spread_bonus
	
	print("Meteor modifiers applied: ", modifiers)

# Override pour empêcher collision normale
func _on_hit_target(_body):
	# Les météores ne touchent que lors de l'impact
	pass

func _physics_process(delta):
	# Pas de mouvement pendant la préparation
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		clear_warnings()
		queue_free()
