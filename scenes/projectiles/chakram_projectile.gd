# ChakramProjectile.gd - Correction conflit max_bounces
extends BaseProjectile
class_name ChakramProjectile

# Variables spéciales du Chakram (SANS redéclarer max_bounces)
var return_to_player: bool = false
var player_target: Node2D = null
var bounce_targets: Array = []
var bounce_range: float = 150.0
var return_speed_multiplier: float = 1.5

# Variables de rotation
var rotation_speed: float = 15.0
var orbit_radius: float = 0.0
var orbit_time: float = 0.0

func _ready():
	super._ready()
	setup_chakram_behavior()

func setup_chakram_behavior():
	# Configuration spéciale du Chakram
	projectile_type = "bounce"
	# CORRECTION : Utiliser les variables héritées de BaseProjectile
	max_bounces = 3
	bounces_remaining = max_bounces
	
	# Trouver le joueur pour le retour
	player_target = get_tree().get_first_node_in_group("players")
	
	# Configuration visuelle
	if sprite:
		sprite.modulate = Color.ORANGE
	
	print("🪃 Chakram initialized with ", max_bounces, " bounces")

func _physics_process(delta):
	# Rotation visuelle continue
	if sprite:
		sprite.rotation += rotation_speed * delta
	
	# Comportement selon l'état
	if return_to_player:
		handle_return_to_player(delta)
	else:
		handle_normal_movement(delta)
	
	# Timer de vie
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		on_lifetime_end()

func handle_normal_movement(delta):
	# Mouvement normal avec légère orbite
	orbit_time += delta * 2.0
	orbit_radius = sin(orbit_time) * 10.0
	
	var orbit_offset = Vector2(
		cos(direction.angle() + PI/2) * orbit_radius,
		sin(direction.angle() + PI/2) * orbit_radius
	)
	
	global_position += (direction * speed + orbit_offset) * delta

func handle_return_to_player(delta):
	if not player_target or not is_instance_valid(player_target):
		global_position += direction * speed * return_speed_multiplier * delta
		return
	
	var player_direction = (player_target.global_position - global_position).normalized()
	direction = direction.lerp(player_direction, 5.0 * delta).normalized()
	
	global_position += direction * speed * return_speed_multiplier * delta
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	if distance_to_player < 30.0:
		print("🪃 Chakram returned to player!")
		queue_free()

func _on_hit_target(body):
	print("🪃 Chakram hit: ", body.name)
	
	if not should_damage_target(body):
		return
	
	if body in bounce_targets:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("✅ Chakram damage: ", damage)
		
		if has_status_effect and body.has_method("apply_status_effect"):
			body.apply_status_effect(status_type, status_duration, status_power)
	
	bounce_targets.append(body)
	
	if bounces_remaining > 0:
		handle_chakram_bounce(body)
	else:
		start_return_to_player()

func handle_chakram_bounce(hit_target):
	bounces_remaining -= 1
	print("🪃 Chakram bouncing! Bounces left: ", bounces_remaining)
	
	create_bounce_effect()
	
	var next_target = find_next_bounce_target(hit_target)
	
	if next_target:
		direction = (next_target.global_position - global_position).normalized()
		print("🪃 Bouncing to: ", next_target.name)
		speed *= 1.1
	else:
		var random_angle = randf() * TAU
		direction = Vector2(cos(random_angle), sin(random_angle))
		print("🪃 Random bounce direction")
	
	if bounces_remaining <= 0:
		var return_timer = Timer.new()
		add_child(return_timer)
		return_timer.wait_time = 1.0
		return_timer.one_shot = true
		return_timer.timeout.connect(start_return_to_player)
		return_timer.start()

func find_next_bounce_target(current_target):
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	var best_target = null
	var closest_distance = bounce_range
	
	for target in potential_targets:
		if target == current_target or target in bounce_targets:
			continue
		
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			best_target = target
	
	return best_target

func start_return_to_player():
	return_to_player = true
	bounce_targets.clear()
	
	if sprite:
		sprite.modulate = Color.CYAN
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)
	
	print("🪃 Chakram returning to player!")

func create_bounce_effect():
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center = Vector2(16, 16)
	
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 12:
				var alpha = 1.0 - (distance / 12.0)
				image.set_pixel(x, y, Color(1.0, 0.6, 0.0, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = global_position
	
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2.0, 2.0), 0.4)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): 
		if is_instance_valid(effect):
			effect.queue_free()
	)

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true

func set_projectile_type(type: String):
	projectile_type = "bounce"
	max_bounces = 3
	bounces_remaining = max_bounces

func on_lifetime_end():
	if not return_to_player:
		start_return_to_player()
	else:
		queue_free()

func configure_chakram(config: Dictionary):
	if config.has("max_bounces"):
		max_bounces = config.max_bounces
		bounces_remaining = max_bounces
	
	if config.has("bounce_range"):
		bounce_range = config.bounce_range
	
	if config.has("return_speed_multiplier"):
		return_speed_multiplier = config.return_speed_multiplier
	
	if config.has("rotation_speed"):
		rotation_speed = config.rotation_speed
	
	print("🪃 Chakram configured: ", config)
