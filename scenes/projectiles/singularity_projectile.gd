# SingularityProjectile.gd - Trou noir qui aspire et détruit
extends BaseProjectile
class_name SingularityProjectile

# Variables du trou noir
var singularity_radius: float = 200.0
var max_pull_force: float = 300.0
var growth_rate: float = 15.0
var collapse_time: float = 8.0
var damage_per_second: float = 20.0
var current_radius: float = 20.0

# Variables internes
var affected_targets: Array = []
var visual_effects: Array = []
var is_collapsing: bool = false
var collapse_timer: float = 0.0

func _ready():
	super._ready()
	setup_singularity()

func setup_singularity():
	speed = 100.0  # Vitesse lente vers la destination
	lifetime = 12.0
	current_radius = 20.0
	
	print("🌌 SINGULARITÉ CRÉÉE - Trou noir en formation")
	create_initial_visual()

func create_initial_visual():
	# Créer l'effet visuel du trou noir
	var singularity_core = Sprite2D.new()
	add_child(singularity_core)
	
	create_singularity_texture(singularity_core, current_radius)
	visual_effects.append(singularity_core)
	
	# Particules autour du trou noir
	create_particle_effects()

func create_singularity_texture(sprite: Sprite2D, radius: float):
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var intensity = 1.0 - (distance / radius)
				var alpha = intensity * intensity  # Effet quadratique pour le centre plus sombre
				
				# Couleur du trou noir - gradient du noir au violet
				var color: Color
				if intensity > 0.8:
					color = Color.BLACK  # Centre très noir
				elif intensity > 0.5:
					color = Color.PURPLE * 0.5  # Bord violet sombre
				else:
					color = Color.PURPLE  # Bord violet
				
				# Effet d'accrétion (spirale)
				var angle = atan2(y - center.y, x - center.x)
				var spiral_intensity = sin(angle * 8 + distance * 0.2) * 0.3 + 0.7
				alpha *= spiral_intensity
				
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture
	sprite.position = Vector2(-radius, -radius)

func create_particle_effects():
	# Créer des "étoiles" qui sont aspirées
	for i in range(15):
		var particle = Sprite2D.new()
		add_child(particle)
		
		# Petite étoile
		var star_size = 4
		var image = Image.create(star_size, star_size, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		particle.texture = texture
		
		# Position aléatoire autour du trou noir
		var angle = randf() * TAU
		var distance = randf_range(50, 150)
		particle.position = Vector2(cos(angle), sin(angle)) * distance
		
		visual_effects.append(particle)
		
		# Animation de spirale vers le centre
		animate_particle_spiral(particle)

func animate_particle_spiral(particle: Sprite2D):
	var tween = create_tween()
	tween.set_loops()
	
	# Mouvement en spirale vers le centre
	var start_pos = particle.position
	var spiral_duration = randf_range(2.0, 4.0)
	
	# Animation complexe de spirale
	for i in range(20):
		var progress = float(i) / 20.0
		var current_distance = start_pos.length() * (1.0 - progress)
		var angle_offset = progress * PI * 4  # 2 tours de spirale
		var current_angle = start_pos.angle() + angle_offset
		
		var target_pos = Vector2(cos(current_angle), sin(current_angle)) * current_distance
		tween.tween_property(particle, "position", target_pos, spiral_duration / 20.0)
	
	# Disparaître au centre
	tween.tween_property(particle, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): 
		# Recréer la particule
		particle.position = Vector2(cos(randf() * TAU), sin(randf() * TAU)) * randf_range(50, 150)
		particle.modulate.a = 1.0
	)

func _physics_process(delta):
	# Mouvement vers la destination (si pas encore arrivé)
	if speed > 0:
		global_position += direction * speed * delta
		speed = max(0, speed - 50 * delta)  # Ralentissement progressif
	
	# Croissance du trou noir
	if current_radius < singularity_radius and not is_collapsing:
		current_radius += growth_rate * delta
		update_visual_size()
	
	# Effet d'aspiration sur les ennemis
	apply_gravitational_pull(delta)
	
	# Dégâts continus
	apply_singularity_damage(delta)
	
	# Gestion de l'effondrement
	if not is_collapsing and lifetime_timer >= collapse_time:
		start_collapse()
	
	# Timer de vie
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		explode_singularity()

func update_visual_size():
	# Mettre à jour la taille visuelle du trou noir
	if visual_effects.size() > 0 and is_instance_valid(visual_effects[0]):
		var core = visual_effects[0]
		create_singularity_texture(core, current_radius)

func apply_gravitational_pull(delta):
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	affected_targets.clear()
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		var distance = global_position.distance_to(target.global_position)
		var pull_radius = current_radius * 2.5  # Zone d'attraction plus large
		
		if distance <= pull_radius:
			affected_targets.append(target)
			
			# Calculer la force d'attraction
			var pull_strength = max_pull_force * (1.0 - distance / pull_radius)
			var pull_direction = (global_position - target.global_position).normalized()
			
			# Appliquer la force d'attraction
			if target.has_method("set") and "velocity" in target:
				var pull_force = pull_direction * pull_strength * delta
				target.velocity += pull_force
			elif target.has_method("set") and "global_position" in target:
				# Fallback: déplacement direct
				var pull_movement = pull_direction * pull_strength * delta * 0.5
				target.global_position += pull_movement
			
			# Effet visuel de traction
			create_pull_effect(target.global_position)

func apply_singularity_damage(delta):
	# Appliquer des dégâts aux cibles très proches du centre
	var damage_radius = current_radius * 0.8
	
	for target in affected_targets:
		if not is_instance_valid(target):
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance <= damage_radius:
			if target.has_method("take_damage"):
				var damage_this_frame = damage_per_second * delta
				# Dégâts plus forts au centre
				var distance_ratio = 1.0 - (distance / damage_radius)
				var final_damage = damage_this_frame * (1.0 + distance_ratio)
				
				target.take_damage(final_damage)
				
				# Effet de désintégration
				if target.has_method("apply_status_effect"):
					target.apply_status_effect("slow", 1.0, 0.2)  # Ralentissement extrême
				
				# Lifesteal pour le joueur
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(final_damage)

func create_pull_effect(target_position: Vector2):
	# Effet visuel de ligne d'attraction
	var pull_line = Line2D.new()
	get_tree().current_scene.add_child(pull_line)
	
	pull_line.add_point(global_position)
	pull_line.add_point(target_position)
	pull_line.width = 2.0
	pull_line.default_color = Color.PURPLE
	pull_line.default_color.a = 0.6
	
	# Disparaître rapidement
	var tween = create_tween()
	tween.tween_property(pull_line, "default_color:a", 0.0, 0.3)
	tween.tween_callback(func(): pull_line.queue_free())

func start_collapse():
	is_collapsing = true
	print("🌌 SINGULARITÉ EN EFFONDREMENT!")
	
	# Effet visuel d'effondrement
	create_collapse_warning()

func create_collapse_warning():
	# Avertissement d'effondrement imminent
	var warning = Sprite2D.new()
	get_tree().current_scene.add_child(warning)
	
	var warning_radius = current_radius * 3
	var size = int(warning_radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= warning_radius and distance >= warning_radius - 20:
				var alpha = 0.7
				var color = Color.RED
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	warning.texture = texture
	warning.global_position = global_position - Vector2(warning_radius, warning_radius)
	
	# Animation de clignotement
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(warning, "modulate:a", 0.2, 0.1)
	tween.tween_property(warning, "modulate:a", 1.0, 0.1)
	
	visual_effects.append(warning)

func explode_singularity():
	print("🌌 EXPLOSION DE SINGULARITÉ!")
	
	# Dégâts massifs d'explosion
	var explosion_damage = damage * 5.0
	var explosion_radius = current_radius * 2.0
	
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance <= explosion_radius:
			if target.has_method("take_damage"):
				# Dégâts selon la distance
				var distance_ratio = 1.0 - (distance / explosion_radius)
				var final_damage = explosion_damage * distance_ratio
				target.take_damage(final_damage)
				
				# Lifesteal massif
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(final_damage)
				
				print("🌌 Singularity explosion hit ", target.name, " for ", int(final_damage), " damage")
	
	# Effet visuel d'explosion
	create_singularity_explosion_effect()
	
	# Nettoyer et détruire
	cleanup_effects()
	queue_free()

func create_singularity_explosion_effect():
	# Explosion spectaculaire de la singularité
	for i in range(8):
		var explosion_ring = Sprite2D.new()
		get_tree().current_scene.add_child(explosion_ring)
		
		var ring_radius = current_radius * (1.0 + i * 0.5)
		var size = int(ring_radius * 2)
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(size / 2, size / 2)
		
		# Couleurs d'explosion dimensionnelle
		var colors = [Color.PURPLE, Color.MAGENTA, Color.BLUE, Color.WHITE]
		var ring_color = colors[i % colors.size()]
		
		# Créer l'anneau d'explosion
		for x in range(size):
			for y in range(size):
				var distance = Vector2(x, y).distance_to(center)
				if distance <= ring_radius and distance >= ring_radius - 25:
					var alpha = 0.8
					image.set_pixel(x, y, Color(ring_color.r, ring_color.g, ring_color.b, alpha))
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		explosion_ring.texture = texture
		explosion_ring.global_position = global_position - Vector2(ring_radius, ring_radius)
		
		# Animation avec délai
		var tween = create_tween()
		var delay = i * 0.1
		tween.tween_delay(delay)
		tween.parallel().tween_property(explosion_ring, "scale", Vector2(3, 3), 0.8)
		tween.parallel().tween_property(explosion_ring, "modulate:a", 0.0, 0.8)
		tween.tween_callback(func(): explosion_ring.queue_free())

func cleanup_effects():
	for effect in visual_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	visual_effects.clear()

# Override pour empêcher collision normale
func _on_hit_target(_body):
	# La singularité gère ses propres interactions
	pass
