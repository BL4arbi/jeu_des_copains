# LightningProjectile.gd - Version simple qui fonctionne
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

func _ready():
	print("⚡ Lightning created!")
	
	# Trouver les ennemis IMMÉDIATEMENT
	find_nearby_enemies()
	
	if target_enemies.size() == 0:
		print("❌ No enemies found, destroying lightning")
		queue_free()
		return
	
	# Créer les cercles d'avertissement
	create_warning_circles()
	
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

func strike_all_targets():
	print("⚡ LIGHTNING STRIKES!")
	
	# Supprimer les avertissements
	for warning in warning_circles:
		if is_instance_valid(warning):
			warning.queue_free()
	warning_circles.clear()
	
	# Frapper chaque cible
	for target_data in target_enemies:
		strike_position(target_data.position)
		await get_tree().create_timer(0.1).timeout  # Petit délai entre les frappes
	
	# Détruire le projectile
	queue_free()

func strike_position(strike_pos: Vector2):
	print("⚡ Lightning strikes at: ", strike_pos)
	
	# Créer l'effet visuel d'éclair
	create_lightning_effect(strike_pos)
	
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

func create_lightning_effect(pos: Vector2):
	# Effet visuel d'éclair
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	# Créer un effet d'explosion électrique
	var effect_size = int(strike_radius * 1.5)
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	
	# Remplir avec des lignes d'éclair aléatoires
	var center = Vector2(effect_size / 2, effect_size / 2)
	for i in range(15):  # 15 éclairs
		var angle = randf() * PI * 2
		var length = randf() * (effect_size / 2)
		var end_pos = center + Vector2(cos(angle), sin(angle)) * length
		
		# Dessiner une ligne d'éclair (simple)
		draw_lightning_line(image, center, end_pos)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = pos - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation d'explosion
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.4)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): effect.queue_free())

func draw_lightning_line(image: Image, start: Vector2, end: Vector2):
	# Dessiner une ligne simple entre deux points
	var distance = start.distance_to(end)
	var steps = int(distance)
	
	for i in range(steps):
		var t = float(i) / float(steps) if steps > 0 else 0.0
		var pos = start.lerp(end, t)
		
		# Ajouter du bruit pour l'effet éclair
		pos += Vector2(randf_range(-2, 2), randf_range(-2, 2))
		
		var x = int(pos.x)
		var y = int(pos.y)
		
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, Color.YELLOW)

# Méthodes pour compatibilité
func setup(projectile_damage: float, projectile_speed: float, projectile_lifetime: float):
	damage = projectile_damage

func set_owner_type(type: String):
	owner_type = type

func launch(start_position: Vector2, target_position: Vector2):
	# La foudre ne bouge pas, elle reste où elle est créée
	pass
