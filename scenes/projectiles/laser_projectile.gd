# LaserProjectile.gd - Laser qui tourne et traverse tout
extends BaseProjectile
class_name LaserProjectile

# Variables du laser
var laser_length: float = 800.0
var rotation_speed: float = 2.0
var beam_width: float = 20.0
var continuous_damage: bool = true
var damage_per_tick: float = 5.0
var damage_tick_rate: float = 0.1
var damage_timer: float = 0.0

# Gestion des cibles touchées (pour éviter spam de dégâts)
var targets_in_beam: Array = []
var beam_sprites: Array = []

func _ready():
	super._ready()
	setup_laser_behavior()

func setup_laser_behavior():
	speed = 0  # Le laser ne bouge pas
	lifetime = 8.0  # Dure 8 secondes
	continuous_damage = true
	
	# Créer le faisceau laser visuel
	create_laser_beam()
	
	print("🔴 Laser Rotatif activé!")

func create_laser_beam():
	# Créer plusieurs segments pour le laser
	var segments = 20
	var segment_length = laser_length / segments
	
	for i in range(segments):
		var beam_segment = Sprite2D.new()
		add_child(beam_segment)
		
		# Créer texture de segment laser
		var segment_size = Vector2(segment_length, beam_width)
		var image = Image.create(int(segment_size.x), int(segment_size.y), false, Image.FORMAT_RGBA8)
		
		# Couleur selon le propriétaire
		var beam_color = Color.RED if owner_type == "player" else Color.DARK_RED
		if owner_type == "player":
			beam_color = Color.CYAN  # Cyan pour joueur
		
		# Gradient du centre vers les bords
		for x in range(int(segment_size.x)):
			for y in range(int(segment_size.y)):
				var distance_from_center = abs(y - segment_size.y / 2)
				var intensity = 1.0 - (distance_from_center / (segment_size.y / 2))
				var alpha = intensity * 0.8
				
				image.set_pixel(x, y, Color(beam_color.r, beam_color.g, beam_color.b, alpha))
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		beam_segment.texture = texture
		
		# Position du segment
		beam_segment.position.x = i * segment_length + segment_length / 2
		beam_segment.z_index = 5  # Au-dessus de tout
		
		beam_sprites.append(beam_segment)

func _physics_process(delta):
	# Rotation continue
	rotation += rotation_speed * delta
	
	# Dégâts continus
	if continuous_damage:
		damage_timer += delta
		if damage_timer >= damage_tick_rate:
			check_laser_collisions()
			damage_timer = 0.0
	
	# Timer de vie
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		on_lifetime_end()

func check_laser_collisions():
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	targets_in_beam.clear()
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
		
		# Vérifier si la cible est dans le faisceau laser
		if is_target_in_laser_beam(target):
			targets_in_beam.append(target)
			
			# Appliquer les dégâts
			if target.has_method("take_damage"):
				target.take_damage(damage_per_tick)
				
				# Effet de brûlure du laser
				if target.has_method("apply_status_effect"):
					target.apply_status_effect("burn", 2.0, 1.0)
				
				# Lifesteal pour le joueur
				if owner_type == "player":
					var player = get_tree().get_first_node_in_group("players")
					if player and player.has_method("apply_lifesteal_on_damage"):
						player.apply_lifesteal_on_damage(damage_per_tick)

func is_target_in_laser_beam(target: Node2D) -> bool:
	# Convertir la position de la cible dans le référentiel du laser
	var local_target_pos = to_local(target.global_position)
	
	# Vérifier si c'est dans la longueur du laser
	if local_target_pos.x < 0 or local_target_pos.x > laser_length:
		return false
	
	# Vérifier si c'est dans la largeur du laser
	if abs(local_target_pos.y) > beam_width / 2:
		return false
	
	return true

func create_hit_effect(position: Vector2):
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
				var effect_color = Color.YELLOW if owner_type == "player" else Color.ORANGE
				image.set_pixel(x, y, Color(effect_color.r, effect_color.g, effect_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation de l'effet
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): effect.queue_free())

func on_lifetime_end():
	print("🔴 Laser Rotatif terminé")
	
	# Effet final d'explosion
	create_laser_explosion()
	
	queue_free()

func create_laser_explosion():
	# Explosion finale quand le laser se termine
	for i in range(5):
		var explosion = Sprite2D.new()
		get_tree().current_scene.add_child(explosion)
		
		var explosion_size = 64
		var image = Image.create(explosion_size, explosion_size, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		explosion.texture = texture
		
		var random_pos = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		explosion.global_position = random_pos
		
		var tween = create_tween()
		var delay = i * 0.1
		tween.tween_delay(delay)
		tween.parallel().tween_property(explosion, "scale", Vector2(3, 3), 0.4)
		tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
		tween.tween_callback(func(): explosion.queue_free())

# Override pour empêcher collision normale
func _on_hit_target(_body):
	# Le laser gère ses propres collisions
	pass
