# LightningProjectile.gd - Version avec animation corrigée
extends Area2D
class_name LightningProjectile

# Variables simples
var damage: float = 30.0
var owner_type: String = "player"
var max_targets: int = 3
var strike_radius: float = 80.0
var warning_time: float = 1.0

# Variables internes
var target_enemies: Array = []
var warning_circles: Array = []
var lightning_animations: Array = []

func _ready():
	print("⚡ Lightning created!")
	
	# Trouver les ennemis IMMÉDIATEMENT
	find_nearby_enemies()
	
	if target_enemies.size() == 0:
		print("❌ No enemies found, destroying lightning")
		queue_free()
		return
	
	# Créer les cercles d'avertissement ET les animations
	create_warning_circles()
	create_lightning_animations()
	
	# Frapper après le délai
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = warning_time
	timer.one_shot = true
	timer.timeout.connect(strike_all_targets)
	timer.start()
	
	print("⚡ Lightning will strike ", target_enemies.size(), " enemies in ", warning_time, "s")

func find_nearby_enemies():
	# Chercher tous les ennemis
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	print("⚡ Found ", all_enemies.size(), " total enemies")
	
	# Calculer les distances
	var enemy_distances = []
	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		enemy_distances.append({
			"enemy": enemy,
			"distance": distance,
			"position": enemy.global_position
		})
	
	# Trier par distance (plus proches en premier)
	enemy_distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Prendre les 3 plus proches
	target_enemies.clear()
	for i in range(min(max_targets, enemy_distances.size())):
		target_enemies.append(enemy_distances[i])
		print("⚡ Target ", i+1, ": ", enemy_distances[i].enemy.name, " at distance ", int(enemy_distances[i].distance))

func create_warning_circles():
	# Créer un cercle d'avertissement pour chaque cible
	for target_data in target_enemies:
		var warning = create_warning_circle(target_data.position)
		warning_circles.append(warning)
		get_tree().current_scene.add_child(warning)

func create_warning_circle(pos: Vector2) -> Sprite2D:
	var warning = Sprite2D.new()
	
	# Créer un cercle rouge d'avertissement
	var size = int(strike_radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= strike_radius:
				var alpha = 0.5
				if distance > strike_radius - 8:  # Bordure plus visible
					alpha = 0.8
				image.set_pixel(x, y, Color(1.0, 1.0, 0.0, alpha))  # Jaune
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	warning.texture = texture
	warning.global_position = pos - Vector2(strike_radius, strike_radius)
	
	# Animation clignotante
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(warning, "modulate:a", 0.3, 0.3)
	tween.tween_property(warning, "modulate:a", 1.0, 0.3)
	
	return warning

# Créer les animations de foudre sur les cercles
func create_lightning_animations():
	for target_data in target_enemies:
		var lightning_anim = create_lightning_animation_sprite(target_data.position)
		lightning_animations.append(lightning_anim)
		get_tree().current_scene.add_child(lightning_anim)

func create_lightning_animation_sprite(pos: Vector2) -> Sprite2D:
	var lightning_sprite = Sprite2D.new()
	
	# Créer une texture d'éclair vertical
	var lightning_width = 32
	var lightning_height = int(strike_radius * 2.5)  # Un peu plus haut
	var image = Image.create(lightning_width, lightning_height, false, Image.FORMAT_RGBA8)
	
	# Dessiner l'éclair avec du bruit
	var center_x = lightning_width / 2
	var segments = 20
	var points = []
	
	# Créer les points de l'éclair avec variation
	for i in range(segments + 1):
		var y = (float(i) / segments) * lightning_height
		var x_variation = randf_range(-8, 8) if i > 0 and i < segments else 0
		var x = center_x + x_variation
		points.append(Vector2(x, y))
	
	# Dessiner les segments de l'éclair
	for i in range(points.size() - 1):
		draw_lightning_segment(image, points[i], points[i + 1])
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	lightning_sprite.texture = texture
	
	# POSITIONNER AU CENTRE DU CERCLE (pas au-dessus)
	lightning_sprite.global_position = pos - Vector2(lightning_width / 2, lightning_height / 2)
	
	# COMMENCER INVISIBLE - sera rendu visible au strike
	lightning_sprite.modulate.a = 0.0
	lightning_sprite.z_index = 10  # Au-dessus de tout
	
	return lightning_sprite

func draw_lightning_segment(image: Image, start: Vector2, end: Vector2):
	var distance = start.distance_to(end)
	var steps = int(distance)
	
	for i in range(steps):
		var t = float(i) / float(steps) if steps > 0 else 0.0
		var pos = start.lerp(end, t)
		
		# Ajouter variation pour effet d'éclair
		pos.x += randf_range(-1, 1)
		
		var x = int(pos.x)
		var y = int(pos.y)
		
		# Dessiner le point principal en blanc brillant
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, Color.WHITE)
		
		# Ajouter des branches aléatoires
		if randf() < 0.1:  # 10% de chance de branche
			var branch_length = randi_range(3, 8)
			var branch_angle = randf_range(-PI/3, PI/3)
			var branch_end = pos + Vector2(cos(branch_angle), sin(branch_angle)) * branch_length
			
			# Dessiner mini-branche
			var bx = int(branch_end.x)
			var by = int(branch_end.y)
			if bx >= 0 and bx < image.get_width() and by >= 0 and by < image.get_height():
				image.set_pixel(bx, by, Color(0.8, 0.8, 1.0, 0.8))

func strike_all_targets():
	print("⚡ LIGHTNING STRIKES!")
	
	# Supprimer les avertissements
	for warning in warning_circles:
		if is_instance_valid(warning):
			warning.queue_free()
	warning_circles.clear()
	
	# MONTRER les animations de foudre et frapper
	for i in range(target_enemies.size()):
		var target_data = target_enemies[i]
		
		# Rendre l'animation visible avec effet flash
		if i < lightning_animations.size() and is_instance_valid(lightning_animations[i]):
			var lightning_anim = lightning_animations[i]
			lightning_anim.modulate.a = 1.0
			
			# Effet de flash CORRIGÉ
			var flash_tween = create_tween()
			flash_tween.tween_property(lightning_anim, "modulate", Color.WHITE, 0.1)
			flash_tween.tween_property(lightning_anim, "modulate", Color.CYAN, 0.1)
			flash_tween.tween_property(lightning_anim, "modulate", Color.WHITE, 0.1)
			flash_tween.tween_property(lightning_anim, "modulate", Color.WHITE, 0.5)  # PAUSE au lieu de tween_delay
			flash_tween.tween_property(lightning_anim, "modulate:a", 0.0, 0.3)
			flash_tween.tween_callback(func(): 
				if is_instance_valid(lightning_anim):
					lightning_anim.queue_free()
			)
		
		# Frapper la position
		strike_position(target_data.position)
		await get_tree().create_timer(0.15).timeout  # Petit délai entre les frappes
	
	# Nettoyer les animations restantes
	for anim in lightning_animations:
		if is_instance_valid(anim):
			anim.queue_free()
	lightning_animations.clear()
	
	# Détruire le projectile
	queue_free()

func strike_position(strike_pos: Vector2):
	print("⚡ Lightning strikes at: ", strike_pos)
	
	# Créer l'effet au sol aussi
	create_ground_lightning_effect(strike_pos)
	
	# Chercher tous les ennemis dans le rayon
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	var enemies_hit = 0
	
	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = strike_pos.distance_to(enemy.global_position)
		if distance <= strike_radius:
			if enemy.has_method("take_damage"):
				# Dégâts selon la distance
				var distance_ratio = 1.0 - (distance / strike_radius)
				var final_damage = damage * distance_ratio
				enemy.take_damage(final_damage)
				
				# Effet de paralysie
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect("freeze", 1.5, 1.0)
				
				print("⚡ Hit ", enemy.name, " for ", int(final_damage), " damage")
				enemies_hit += 1
	
	print("⚡ Lightning strike hit ", enemies_hit, " enemies")

func create_ground_lightning_effect(pos: Vector2):
	# Effet au sol quand la foudre frappe
	var ground_effect = Sprite2D.new()
	get_tree().current_scene.add_child(ground_effect)
	
	var effect_size = int(strike_radius * 1.2)
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(effect_size / 2, effect_size / 2)
	
	# Créer un effet de cratère électrique
	for x in range(effect_size):
		for y in range(effect_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effect_size / 2:
				var alpha = 1.0 - (distance / (effect_size / 2))
				alpha *= 0.8
				
				# Couleur électrique
				var color = Color.CYAN if randf() < 0.7 else Color.WHITE
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ground_effect.texture = texture
	ground_effect.global_position = pos - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation d'explosion électrique
	var tween = create_tween()
	tween.parallel().tween_property(ground_effect, "scale", Vector2(2, 2), 0.4)
	tween.parallel().tween_property(ground_effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): ground_effect.queue_free())

# Méthodes pour compatibilité
func setup(projectile_damage: float, projectile_speed: float, projectile_lifetime: float):
	damage = projectile_damage

func set_owner_type(type: String):
	owner_type = type

func launch(start_position: Vector2, target_position: Vector2):
	# La foudre ne bouge pas, elle reste où elle est créée
	pass
