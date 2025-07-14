# NovaProjectile.gd - Explosion stellaire massive
extends BaseProjectile
class_name NovaProjectile

# Variables de la nova
var charge_time: float = 2.0
var explosion_radius: float = 300.0
var explosion_damage_multiplier: float = 3.0
var shockwave_count: int = 3
var shockwave_delay: float = 0.5

# États
var is_charging: bool = true
var charge_timer: float = 0.0
var warning_circles: Array = []

func _ready():
	super._ready()
	setup_nova_behavior()

func setup_nova_behavior():
	speed = 0  # La nova ne bouge pas
	lifetime = 10.0
	
	# Créer l'effet de charge
	create_charging_effect()
	
	print("✨ Nova Stellaire en charge...")

func create_charging_effect():
	# Créer plusieurs cercles d'avertissement qui grandissent
	for i in range(3):
		var warning = create_warning_circle(explosion_radius * (0.4 + i * 0.3))
		warning_circles.append(warning)
		get_tree().current_scene.add_child(warning)

func create_warning_circle(radius: float) -> Sprite2D:
	var warning = Sprite2D.new()
	
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius and distance >= radius - 10:
				var alpha = 0.6
				# Couleur stellaire
				var color = Color.PURPLE if owner_type == "player" else Color.DARK_RED
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	warning.texture = texture
	warning.global_position = global_position - Vector2(radius, radius)
	
	# Animation pulsante
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(warning, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(warning, "scale", Vector2(0.9, 0.9), 0.5)
	
	return warning

func _physics_process(delta):
	if is_charging:
		charge_timer += delta
		
		# Effets visuels pendant la charge
		if int(charge_timer * 10) % 2 == 0:  # Clignotement
			modulate = Color.WHITE
		else:
			modulate = Color.PURPLE if owner_type == "player" else Color.RED
		
		# Déclencher l'explosion
		if charge_timer >= charge_time:
			trigger_nova_explosion()
	
	# Timer de vie normal
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		cleanup_and_destroy()

func trigger_nova_explosion():
	is_charging = false
	print("✨ NOVA STELLAIRE EXPLOSE!")
	
	# Supprimer les avertissements
	clear_warnings()
	
	# Créer les ondes de choc successives
	for i in range(shockwave_count):
		create_shockwave(i)
		await get_tree().create_timer(shockwave_delay).timeout
	
	# Effet final
	create_final_nova_effect()
	
	# Se détruire après toutes les explosions
	await get_tree().create_timer(1.0).timeout
	cleanup_and_destroy()

func create_shockwave(wave_index: int):
	var wave_radius = explosion_radius * (0.5 + wave_index * 0.4)
	var wave_damage = damage * explosion_damage_multiplier * (1.0 - wave_index * 0.2)
	
	print("✨ Shockwave ", wave_index + 1, " - Radius: ", wave_radius, " Damage: ", wave_damage)
	
	# Dégâts dans le rayon
	damage_targets_in_radius(wave_radius, wave_damage)
	
	# Effet visuel de l'onde de choc
	create_shockwave_visual(wave_radius, wave_index)

func damage_targets_in_radius(radius: float, wave_damage: float):
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance <= radius:
			if target.has_method("take_damage"):
				# Dégâts selon la distance (plus fort au centre)
				var distance_ratio = 1.0 - (distance / radius)
				var final_damage = wave_damage * distance_ratio
				target.take_damage(final_damage)
				
				# Effets de statut stellaires
				if target.has_method("apply_status_effect"):
					target.apply_status_effect("burn", 5.0, 3.0)  # Brûlure stellaire
					target.apply_status_effect("slow", 3.0, 0.5)  # Ralentissement
				
				# Lifesteal pour le joueur
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(final_damage)
				
				print("✨ Nova hit ", target.name, " for ", int(final_damage), " damage")

func create_shockwave_visual(radius: float, wave_index: int):
	# Créer l'onde de choc visuelle
	var shockwave = Sprite2D.new()
	get_tree().current_scene.add_child(shockwave)
	
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	# Couleurs selon l'onde
	var colors = [Color.PURPLE, Color.MAGENTA, Color.WHITE]
	var wave_color = colors[wave_index % colors.size()]
	
	if owner_type != "player":
		wave_color = Color.DARK_RED
	
	# Créer l'anneau d'onde de choc
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius and distance >= radius - 20:
				var alpha = 1.0 - abs(distance - (radius - 10)) / 10.0
				alpha = clamp(alpha, 0.0, 0.8)
				image.set_pixel(x, y, Color(wave_color.r, wave_color.g, wave_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	shockwave.texture = texture
	shockwave.global_position = global_position - Vector2(radius, radius)
	
	# Animation de l'onde de choc
	var tween = create_tween()
	tween.parallel().tween_property(shockwave, "scale", Vector2(1.5, 1.5), 1.0)
	tween.parallel().tween_property(shockwave, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): shockwave.queue_free())

func create_final_nova_effect():
	print("✨ Creating final nova effect")
	
	# Effet final spectaculaire
	for i in range(12):  # 12 explosions en étoile
		var explosion = Sprite2D.new()
		get_tree().current_scene.add_child(explosion)
		
		var angle = (i * PI * 2) / 12
		var distance = explosion_radius * 0.7
		var explosion_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Créer l'explosion
		var explosion_size = 80
		var image = Image.create(explosion_size, explosion_size, false, Image.FORMAT_RGBA8)
		var explosion_color = Color.WHITE if owner_type == "player" else Color.ORANGE
		image.fill(explosion_color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		explosion.texture = texture
		explosion.global_position = explosion_pos - Vector2(explosion_size / 2, explosion_size / 2)
		
		# Animation avec délai
		var tween = create_tween()
		var delay = i * 0.1
		tween.tween_delay(delay)
		tween.parallel().tween_property(explosion, "scale", Vector2(4, 4), 0.6)
		tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.6)
		tween.tween_callback(func(): explosion.queue_free())

func clear_warnings():
	for warning in warning_circles:
		if is_instance_valid(warning):
			warning.queue_free()
	warning_circles.clear()

func cleanup_and_destroy():
	clear_warnings()
	queue_free()

# Override pour empêcher collision normale
func _on_hit_target(_body):
	# La nova gère ses propres dégâts
	pass
