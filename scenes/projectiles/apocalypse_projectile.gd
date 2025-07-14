# ApocalypseProjectile.gd - L'arme de destruction massive ultime
extends BaseProjectile
class_name ApocalypseProjectile

# Variables de l'Apocalypse
var apocalypse_radius: float = 500.0
var meteor_count: int = 8
var lightning_count: int = 6
var explosion_count: int = 10
var total_phases: int = 4
var current_phase: int = 0
var phase_duration: float = 2.0
var phase_timer: float = 0.0

# États
var is_active: bool = false
var warning_effects: Array = []

func _ready():
	super._ready()
	setup_apocalypse()

func setup_apocalypse():
	speed = 0  # L'apocalypse ne bouge pas
	lifetime = 12.0  # Dure 12 secondes au total
	
	print("💀 APOCALYPSE ACTIVÉE - DESTRUCTION IMMINENTE!")
	create_apocalypse_warning()
	
	# Commencer la séquence après 1 seconde d'avertissement
	await get_tree().create_timer(1.0).timeout
	start_apocalypse_sequence()

func create_apocalypse_warning():
	# Avertissement global de l'apocalypse
	var screen_warning = ColorRect.new()
	screen_warning.color = Color(1.0, 0.0, 0.0, 0.3)  # Rouge translucide
	screen_warning.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(screen_warning)
	warning_effects.append(screen_warning)
	
	# Animation de clignotement
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(screen_warning, "color:a", 0.1, 0.2)
	tween.tween_property(screen_warning, "color:a", 0.5, 0.2)
	
	# Cercles d'avertissement
	for i in range(3):
		var radius = apocalypse_radius * (0.3 + i * 0.35)
		var warning_circle = create_warning_circle(radius)
		warning_effects.append(warning_circle)
		get_tree().current_scene.add_child(warning_circle)

func create_warning_circle(radius: float) -> Sprite2D:
	var warning = Sprite2D.new()
	
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius and distance >= radius - 15:
				var alpha = 0.7
				# Couleur de l'apocalypse
				var color = Color.DARK_RED
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	warning.texture = texture
	warning.global_position = global_position - Vector2(radius, radius)
	
	return warning

func start_apocalypse_sequence():
	is_active = true
	clear_warnings()
	
	print("💀 APOCALYPSE SEQUENCE STARTED!")
	
	# Phase 1: Pluie de météores
	await execute_meteor_phase()
	
	# Phase 2: Tempête d'éclairs
	await execute_lightning_phase()
	
	# Phase 3: Explosions en chaîne
	await execute_explosion_phase()
	
	# Phase 4: Dévastation finale
	await execute_final_devastation()
	
	print("💀 APOCALYPSE COMPLETE - DÉVASTATION TOTALE")
	queue_free()

func execute_meteor_phase():
	print("💀 Phase 1: Pluie de Météores Apocalyptique")
	
	for i in range(meteor_count):
		spawn_apocalypse_meteor()
		await get_tree().create_timer(0.3).timeout

func spawn_apocalypse_meteor():
	# Créer un météore d'apocalypse
	var meteor_scene = load("res://scenes/projectiles/MeteorProjectile.tscn")
	if not meteor_scene:
		return
	
	var meteor = meteor_scene.instantiate()
	get_tree().current_scene.add_child(meteor)
	
	meteor.set_owner_type(owner_type)
	meteor.setup(damage * 1.5, 0, 8.0)
	
	# Position aléatoire dans le rayon
	var random_angle = randf() * TAU
	var random_distance = randf() * apocalypse_radius
	var meteor_pos = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	meteor.global_position = meteor_pos
	
	# Modifier les propriétés du météore pour l'apocalypse
	if meteor.has_method("apply_accessory_modifiers"):
		meteor.apply_accessory_modifiers({
			"damage_multiplier": 2.0,
			"radius_multiplier": 1.5,
			"speed_multiplier": 1.5
		})

func execute_lightning_phase():
	print("💀 Phase 2: Tempête d'Éclairs Apocalyptique")
	
	for i in range(lightning_count):
		spawn_apocalypse_lightning()
		await get_tree().create_timer(0.4).timeout

func spawn_apocalypse_lightning():
	# Créer un éclair d'apocalypse
	var lightning_scene = load("res://scenes/projectiles/Lightning_projectile.tscn")
	if not lightning_scene:
		return
	
	var lightning = lightning_scene.instantiate()
	get_tree().current_scene.add_child(lightning)
	
	lightning.set_owner_type(owner_type)
	lightning.setup(damage * 1.2, 0, 5.0)
	
	# Position aléatoire
	var random_offset = Vector2(randf_range(-apocalypse_radius, apocalypse_radius), 
							   randf_range(-apocalypse_radius, apocalypse_radius))
	lightning.global_position = global_position + random_offset
	
	# Augmenter les cibles et dégâts
	lightning.max_targets = 6
	lightning.damage = damage * 1.2

func execute_explosion_phase():
	print("💀 Phase 3: Explosions en Chaîne Apocalyptique")
	
	for i in range(explosion_count):
		create_apocalypse_explosion(i)
		await get_tree().create_timer(0.2).timeout

func create_apocalypse_explosion(explosion_index: int):
	# Position en spirale pour les explosions
	var angle = (explosion_index * PI * 2) / explosion_count + (explosion_index * 0.5)
	var distance = (explosion_index * apocalypse_radius) / explosion_count
	var explosion_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Dégâts d'explosion
	var explosion_radius = 120.0
	var explosion_damage = damage * 1.3
	
	damage_targets_in_radius(explosion_pos, explosion_radius, explosion_damage)
	create_explosion_visual(explosion_pos, explosion_radius)

func execute_final_devastation():
	print("💀 Phase 4: DÉVASTATION FINALE APOCALYPTIQUE")
	
	# Explosion finale massive
	var final_damage = damage * 3.0
	damage_targets_in_radius(global_position, apocalypse_radius, final_damage)
	
	# Effet visuel spectaculaire
	create_final_apocalypse_effect()

func damage_targets_in_radius(center_pos: Vector2, radius: float, explosion_damage: float):
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		var distance = center_pos.distance_to(target.global_position)
		if distance <= radius:
			if target.has_method("take_damage"):
				# Dégâts selon la distance
				var distance_ratio = 1.0 - (distance / radius)
				var final_damage = explosion_damage * distance_ratio
				target.take_damage(final_damage)
				
				# Effets de statut apocalyptiques
				if target.has_method("apply_status_effect"):
					target.apply_status_effect("burn", 8.0, 5.0)     # Brûlure intense
					target.apply_status_effect("poison", 6.0, 3.0)   # Poison toxique
					target.apply_status_effect("slow", 5.0, 0.3)     # Ralentissement sévère
				
				# Lifesteal massif pour le joueur
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(final_damage)
				
				print("💀 Apocalypse hit ", target.name, " for ", int(final_damage), " damage")

func create_explosion_visual(position: Vector2, radius: float):
	# Explosion visuelle
	var explosion = Sprite2D.new()
	get_tree().current_scene.add_child(explosion)
	
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				alpha *= 0.9
				var color = Color.ORANGE_RED
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	explosion.texture = texture
	explosion.global_position = position - Vector2(radius, radius)
	
	# Animation
	var tween = create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(2, 2), 0.8)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): explosion.queue_free())

func create_final_apocalypse_effect():
	# Effet final de dévastation totale
	for i in range(20):
		var final_explosion = Sprite2D.new()
		get_tree().current_scene.add_child(final_explosion)
		
		var explosion_size = 100
		var image = Image.create(explosion_size, explosion_size, false, Image.FORMAT_RGBA8)
		
		# Couleurs apocalyptiques variées
		var colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.WHITE, Color.PURPLE]
		var explosion_color = colors[i % colors.size()]
		image.fill(explosion_color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		final_explosion.texture = texture
		
		# Position aléatoire dans un grand rayon
		var random_offset = Vector2(randf_range(-apocalypse_radius, apocalypse_radius), 
								   randf_range(-apocalypse_radius, apocalypse_radius))
		final_explosion.global_position = global_position + random_offset
		
		# Animation avec délai
		var tween = create_tween()
		var delay = i * 0.05  # Délai très court entre explosions
		tween.tween_delay(delay)
		tween.parallel().tween_property(final_explosion, "scale", Vector2(5, 5), 1.0)
		tween.parallel().tween_property(final_explosion, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): final_explosion.queue_free())

func clear_warnings():
	for warning in warning_effects:
		if is_instance_valid(warning):
			warning.queue_free()
	warning_effects.clear()

# Override pour empêcher collision normale
func _on_hit_target(_body):
	# L'apocalypse gère ses propres dégâts
	pass
