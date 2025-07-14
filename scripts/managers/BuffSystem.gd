# BaseEnemy.gd - Version corrigée avec effets cumulatifs
extends BaseCharacter
class_name BaseEnemy

# === VARIABLES DE BASE ===
var enemy_type: String = "Grunt"
var is_elite: bool = false
var armor: float = 0.0
var active_status_effects: Dictionary = {}  # Stocke les effets actifs avec leurs stacks

# Stats de combat
var base_health: float = 25.0
var base_damage: float = 8.0
var can_shoot: bool = false
var projectile_scene_path: String = ""
var fire_rate: float = 3.0
var fire_timer: float = 0.0

# IA et mouvement
var target: Player = null
var detection_range: float = 400.0
var melee_range: float = 50.0
var optimal_distance: float = 200.0
var last_position: Vector2
var stuck_timer: float = 0.0

# OPTIMISATION: Cache de target pour éviter get_tree() constant
var target_cache: Player = null
var target_cache_timer: float = 0.0

# Attaque mêlée
var melee_attack_cooldown: float = 0.0
var melee_attack_rate: float = 1.5
var is_melee_attacking: bool = false
var melee_attack_duration: float = 0.5
var melee_hitbox: Area2D = null

# Attaques spéciales
var special_attack_cooldown: float = 0.0
var special_attack_delay: float = 15.0

# Effets visuels
var armor_indicator: Sprite2D = null
var attack_visual: Sprite2D = null

func _ready():
	super._ready()
	add_to_group("enemies")
	
	collision_layer = 2
	collision_mask = 1
	
	# OPTIMISATION: Cache initial du target
	target_cache = get_tree().get_first_node_in_group("players")
	target = target_cache
	last_position = global_position
	
	setup_melee_hitbox()
	print("🐺 ", enemy_type, " enemy ready!")

func configure_enemy_deferred(enemy_data: Dictionary):
	if not is_instance_valid(self):
		print("❌ Enemy instance invalid during configuration")
		return
	
	enemy_type = enemy_data.name
	base_health = enemy_data.health * 1.3
	base_damage = enemy_data.damage
	speed = enemy_data.speed
	can_shoot = enemy_data.get("can_shoot", false)
	is_elite = (enemy_type == "Elite")
	
	apply_difficulty_scaling()
	
	if can_shoot:
		projectile_scene_path = enemy_data.get("projectile_path", "")
		configure_shooting_stats()
	
	call_deferred("update_visuals")
	
	print("🐺 ", enemy_type, " configured: ", max_health, "HP, ", damage, " damage")

func update_visuals():
	if is_instance_valid(self):
		update_health_bar()
		setup_armor_visual()

func apply_difficulty_scaling():
	var kill_bonus = GlobalData.total_kills if GlobalData else 0
	
	var health_multiplier = 1.0 + (kill_bonus * 0.05)
	var damage_multiplier = 1.0 + (kill_bonus * 0.03)
	
	max_health = base_health * health_multiplier
	current_health = max_health
	damage = base_damage * damage_multiplier
	
	match enemy_type:
		"Elite":
			armor = 0.2 + (kill_bonus * 0.01)
		"Shooter":
			armor = 0.1 + (kill_bonus * 0.005)
		_:
			armor = kill_bonus * 0.002
	
	armor = min(armor, 0.8)

func configure_shooting_stats():
	match enemy_type:
		"Shooter":
			fire_rate = 2.8
			optimal_distance = 160.0
		"Elite":
			fire_rate = 2.5
			special_attack_delay = 10.0

func setup_armor_visual():
	if armor <= 0.1 or not is_instance_valid(self):
		return
	
	if armor_indicator and is_instance_valid(armor_indicator):
		armor_indicator.queue_free()
	
	armor_indicator = Sprite2D.new()
	add_child(armor_indicator)
	armor_indicator.z_index = 1
	
	var armor_color = Color.GRAY
	if armor >= 0.7:
		armor_color = Color.GOLD
	elif armor >= 0.5:
		armor_color = Color.PURPLE
	elif armor >= 0.3:
		armor_color = Color.BLUE
	
	var armor_size = 40
	var image = Image.create(armor_size, armor_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(armor_size / 2, armor_size / 2)
	
	for x in range(armor_size):
		for y in range(armor_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance >= 15 and distance <= 18:
				var alpha = 0.6 * armor
				image.set_pixel(x, y, Color(armor_color.r, armor_color.g, armor_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	armor_indicator.texture = texture
	armor_indicator.position = Vector2(-armor_size / 2, -armor_size / 2)

func setup_melee_hitbox():
	if melee_hitbox:
		return
	
	melee_hitbox = Area2D.new()
	add_child(melee_hitbox)
	
	var hitbox_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 45.0
	hitbox_shape.shape = circle_shape
	melee_hitbox.add_child(hitbox_shape)
	
	melee_hitbox.collision_layer = 0
	melee_hitbox.collision_mask = 1
	melee_hitbox.body_entered.connect(_on_melee_hit_player)
	melee_hitbox.monitoring = false

# === TAKE DAMAGE CORRIGÉ ===
func take_damage(amount: float):
	var damage_reduction = amount * armor
	var base_damage = amount - damage_reduction
	
	# CORRECTION: Appliquer la malédiction si présente
	var curse_multiplier = get_meta("curse_multiplier", 1.0)
	var final_damage = base_damage * curse_multiplier
	
	if damage_reduction > 0:
		show_armor_effect()
	
	super.take_damage(final_damage)
	print("🛡️ ", enemy_type, " took ", int(final_damage), "/", int(amount), " damage (", int(damage_reduction), " blocked, ", curse_multiplier, "x curse)")

func show_armor_effect():
	if armor_indicator and is_instance_valid(armor_indicator):
		var tween = create_tween()
		tween.tween_property(armor_indicator, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(armor_indicator, "scale", Vector2(1.0, 1.0), 0.1)

# === PHYSICS PROCESS OPTIMISÉ ===
func _physics_process(delta):
	super._physics_process(delta)
	
	# OPTIMISATION: Mettre à jour le cache de target moins souvent
	target_cache_timer -= delta
	if target_cache_timer <= 0:
		target_cache = get_tree().get_first_node_in_group("players")
		target = target_cache
		target_cache_timer = 0.5  # Mise à jour toutes les 0.5s
	
	# Traitement des effets de statut cumulatifs
	process_status_effects(delta)
	
	# Cooldowns
	if melee_attack_cooldown > 0:
		melee_attack_cooldown -= delta
	if special_attack_cooldown > 0:
		special_attack_cooldown -= delta
	
	# Attaque mêlée en cours
	if is_melee_attacking:
		melee_attack_duration -= delta
		if melee_attack_duration <= 0:
			end_melee_attack()
	
	check_if_stuck(delta)
	
	# Comportement IA avec target en cache
	if target_cache and is_instance_valid(target_cache):
		var distance = global_position.distance_to(target_cache.global_position)
		
		match enemy_type:
			"Grunt":
				grunt_behavior(distance)
			"Shooter":
				shooter_behavior(delta, distance)
			"Elite":
				elite_behavior(delta, distance)

# === EFFETS DE STATUT CUMULATIFS ===
func apply_cumulative_status_effect(effect_type: String, duration: float, base_power: float, stacks: int):
	if active_status_effects.has(effect_type):
		var existing = active_status_effects[effect_type]
		existing.stacks = min(existing.stacks + stacks, get_max_stacks_for_status(effect_type))
		existing.power = base_power * existing.stacks
		existing.duration = max(existing.duration, duration)
		print("🔥 ", effect_type, " stacked to ", existing.stacks, " (", existing.power, " power)")
	else:
		active_status_effects[effect_type] = {
			"stacks": stacks,
			"power": base_power * stacks,
			"duration": duration,
			"tick_timer": 0.0
		}
		print("✨ New ", effect_type, " effect applied (", stacks, " stacks, ", base_power * stacks, " power)")
	
	update_status_effect_visuals(effect_type)

func get_max_stacks_for_status(effect_type: String) -> int:
	match effect_type:
		"poison": return 10
		"fire": return 8
		"bleeding": return 12
		"electric": return 6
		"slow": return 5
		_: return 5

func process_status_effects(delta: float):
	var effects_to_remove = []
	
	for effect_type in active_status_effects.keys():
		var effect = active_status_effects[effect_type]
		
		effect.duration -= delta
		
		if effect.duration <= 0:
			effects_to_remove.append(effect_type)
			continue
		
		effect.tick_timer += delta
		var tick_rate = get_tick_rate_for_effect(effect_type)
		
		if effect.tick_timer >= tick_rate:
			effect.tick_timer = 0.0
			apply_status_damage(effect_type, effect.power, effect.stacks)
	
	for effect_type in effects_to_remove:
		remove_status_effect(effect_type)

func get_tick_rate_for_effect(effect_type: String) -> float:
	match effect_type:
		"poison": return 0.5
		"fire": return 0.3
		"bleeding": return 1.0
		"electric": return 0.4
		"slow": return 999.0  # Slow n'a pas de ticks
		_: return 1.0

func apply_status_damage(effect_type: String, power: float, stacks: int):
	match effect_type:
		"poison":
			take_damage(power)
			show_poison_visual(stacks)
		"fire":
			take_damage(power)
			show_fire_visual(stacks)
		"bleeding":
			take_damage(power)
			show_bleeding_visual(stacks)
		"electric":
			take_damage(power)
			show_electric_visual(stacks)
			propagate_electric_effect(power * 0.3, stacks)
		"slow":
			apply_slow_modifier(power, stacks)

func remove_status_effect(effect_type: String):
	if active_status_effects.has(effect_type):
		print("🏁 ", effect_type, " effect ended")
		active_status_effects.erase(effect_type)
		
		match effect_type:
			"slow":
				restore_original_speed()
	
	# SUPPRIMÉ: Plus de nettoyage d'indicateurs

func apply_slow_modifier(power: float, stacks: int):
	var slow_multiplier = 1.0 - (power * stacks)
	slow_multiplier = max(slow_multiplier, 0.1)
	
	if not has_meta("original_speed"):
		set_meta("original_speed", speed)
	
	var original_speed = get_meta("original_speed", speed)
	speed = original_speed * slow_multiplier

func restore_original_speed():
	if has_meta("original_speed"):
		speed = get_meta("original_speed")
		remove_meta("original_speed")

func propagate_electric_effect(power: float, stacks: int):
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	var propagation_range = 60 + (stacks * 10)
	
	for nearby in nearby_enemies:
		if nearby != self and nearby.global_position.distance_to(global_position) < propagation_range:
			if nearby.has_method("apply_cumulative_status_effect"):
				nearby.apply_cumulative_status_effect("electric", 1.0, power * 0.5, max(1, stacks - 1))

# === EFFETS VISUELS AVEC STACKS ===
func show_poison_visual(stacks: int):
	var poison_effect = Sprite2D.new()
	add_child(poison_effect)
	
	var size = 30 + (stacks * 3)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = Color.LIME_GREEN
	color.a = 0.6 + (stacks * 0.05)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	poison_effect.texture = texture
	poison_effect.position = Vector2(-size/2, -size/2)
	
	var timer = Timer.new()
	poison_effect.add_child(timer)
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.timeout.connect(poison_effect.queue_free)
	timer.start()

func show_fire_visual(stacks: int):
	var fire_effect = Sprite2D.new()
	add_child(fire_effect)
	
	var size = 35 + (stacks * 4)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = Color.ORANGE_RED
	color.a = 0.7 + (stacks * 0.04)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	fire_effect.texture = texture
	fire_effect.position = Vector2(-size/2, -size/2)
	fire_effect.modulate = Color(1.0, 0.5 + (stacks * 0.05), 0.0, color.a)
	
	var timer = Timer.new()
	fire_effect.add_child(timer)
	timer.wait_time = 0.25
	timer.one_shot = true
	timer.timeout.connect(fire_effect.queue_free)
	timer.start()

func show_electric_visual(stacks: int):
	var electric_effect = Sprite2D.new()
	add_child(electric_effect)
	
	var size = 40 + (stacks * 5)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = Color.CYAN
	color.a = 0.8 + (stacks * 0.02)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	electric_effect.texture = texture
	electric_effect.position = Vector2(-size/2, -size/2)
	electric_effect.modulate = Color(0.0, 0.8 + (stacks * 0.02), 1.0, color.a)
	
	var timer = Timer.new()
	electric_effect.add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(electric_effect.queue_free)
	timer.start()

func show_bleeding_visual(stacks: int):
	var bleeding_effect = Sprite2D.new()
	add_child(bleeding_effect)
	
	var size = 25 + (stacks * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = Color.DARK_RED
	color.a = 0.6 + (stacks * 0.03)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	bleeding_effect.texture = texture
	bleeding_effect.position = Vector2(-size/2, -size/2)
	
	var timer = Timer.new()
	bleeding_effect.add_child(timer)
	timer.wait_time = 0.4
	timer.one_shot = true
	timer.timeout.connect(bleeding_effect.queue_free)
	timer.start()

func update_status_effect_visuals(effect_type: String):
	# SUPPRIMÉ: Plus d'indicateurs visuels pour simplifier
	pass

func get_status_icon(effect_type: String) -> String:
	match effect_type:
		"poison": return "[P]"
		"fire": return "[F]"
		"electric": return "[E]"
		"bleeding": return "[B]"
		"slow": return "[S]"
		_: return "[?]"

func get_status_color(effect_type: String) -> Color:
	match effect_type:
		"poison": return Color.LIME_GREEN
		"fire": return Color.ORANGE_RED
		"electric": return Color.CYAN
		"bleeding": return Color.DARK_RED
		"slow": return Color.GRAY
		_: return Color.WHITE

# === COMPATIBILITÉ AVEC L'ANCIEN SYSTÈME ===
func apply_status_effect(effect_type: String, duration: float, power: float = 1.0):
	apply_cumulative_status_effect(effect_type, duration, power, 1)

# === LE RESTE DE TON CODE (inchangé) ===
func grunt_behavior(distance: float):
	if distance <= melee_range and can_melee_attack():
		start_melee_attack()
		return
	
	if distance > detection_range:
		return
	
	var direction = (target_cache.global_position - global_position).normalized()
	if stuck_timer > 1.0:
		direction = direction.rotated(randf_range(-PI/3, PI/3))
	
	velocity = direction * speed
	move_and_slide()

func shooter_behavior(delta: float, distance: float):
	if distance > optimal_distance + 50:
		var direction = (target_cache.global_position - global_position).normalized()
		velocity = direction * speed * 0.7
		move_and_slide()
	elif distance < optimal_distance - 30:
		var direction = (global_position - target_cache.global_position).normalized()
		velocity = direction * speed * 0.8
		move_and_slide()
	else:
		if randf() < 0.02:
			var random_angle = randf() * TAU
			velocity = Vector2(cos(random_angle), sin(random_angle)) * speed * 0.5
			move_and_slide()
	
	if can_shoot and distance <= optimal_distance + 80:
		handle_shooting(delta)

func elite_behavior(delta: float, distance: float):
	if try_special_attack():
		return
	
	if distance <= melee_range + 15 and can_melee_attack():
		start_melee_attack()
		return
	
	if distance > 30 and distance <= 200:
		var direction = (target_cache.global_position - global_position).normalized()
		var circle_direction = direction.rotated(PI/2 if randf() < 0.5 else -PI/2)
		velocity = (direction * 0.6 + circle_direction * 0.4) * speed * 0.8
		move_and_slide()
	
	if can_shoot and distance > 80 and distance < 300 and not is_melee_attacking:
		handle_shooting(delta)

func can_melee_attack() -> bool:
	return melee_attack_cooldown <= 0 and not is_melee_attacking

func start_melee_attack():
	if not can_melee_attack():
		return
	
	is_melee_attacking = true
	melee_attack_duration = 0.5
	melee_attack_cooldown = melee_attack_rate
	velocity = Vector2.ZERO
	
	call_deferred("activate_melee_hitbox")
	show_melee_attack_visual()

func activate_melee_hitbox():
	if melee_hitbox and is_instance_valid(melee_hitbox):
		melee_hitbox.monitoring = true

func end_melee_attack():
	if not is_melee_attacking:
		return
	
	is_melee_attacking = false
	call_deferred("deactivate_melee_hitbox")
	hide_melee_attack_visual()

func deactivate_melee_hitbox():
	if melee_hitbox and is_instance_valid(melee_hitbox):
		melee_hitbox.monitoring = false

func _on_melee_hit_player(body):
	if not is_melee_attacking or not body.is_in_group("players"):
		return
	
	if body.has_method("take_damage"):
		var melee_damage = damage * 1.2
		body.take_damage(melee_damage)
		print("👊 Melee hit for ", melee_damage, " damage!")
		end_melee_attack()

func show_melee_attack_visual():
	if attack_visual and is_instance_valid(attack_visual):
		attack_visual.queue_free()
	
	attack_visual = Sprite2D.new()
	add_child(attack_visual)
	
	var image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.3, 0.3, 0.6))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	attack_visual.texture = texture
	attack_visual.position = Vector2(-40, -40)

func hide_melee_attack_visual():
	if attack_visual and is_instance_valid(attack_visual):
		attack_visual.queue_free()
		attack_visual = null

func handle_shooting(delta: float):
	if not can_shoot or projectile_scene_path == "" or is_melee_attacking:
		return
	
	fire_timer += delta
	if fire_timer >= fire_rate:
		shoot_at_player()
		fire_timer = 0.0

func shoot_at_player():
	if not ResourceLoader.exists(projectile_scene_path):
		return
	
	var projectile_scene = load(projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	# OPTIMISATION: Utiliser call_deferred pour éviter les conflicts
	get_tree().current_scene.add_child.call_deferred(projectile)
	
	if projectile.has_method("set_owner_type"):
		projectile.set_owner_type("enemy")
	
	var projectile_damage = damage * 0.7
	if projectile.has_method("setup"):
		projectile.setup(projectile_damage, 280.0, 4.0)
	
	var direction = (target_cache.global_position - global_position).normalized()
	var spawn_pos = global_position + direction * 30
	
	if projectile.has_method("launch"):
		projectile.launch(spawn_pos, target_cache.global_position)

func try_special_attack() -> bool:
	if enemy_type != "Elite" or special_attack_cooldown > 0:
		return false
	
	if randf() < 0.008:
		cast_special_attack()
		special_attack_cooldown = special_attack_delay
		return true
	
	return false

func cast_special_attack():
	print("⚡ Elite special attack!")
	
	if not ResourceLoader.exists(projectile_scene_path):
		return
	
	for i in range(3):
		var projectile_scene = load(projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(projectile)
		
		if projectile.has_method("set_owner_type"):
			projectile.set_owner_type("enemy")
		
		if projectile.has_method("setup"):
			projectile.setup(damage * 0.9, 320.0, 5.0)
		
		var base_direction = (target_cache.global_position - global_position).normalized()
		var angle_offset = (i - 1) * 0.4
		var direction = base_direction.rotated(angle_offset)
		var spawn_pos = global_position + direction * 40
		var target_pos = global_position + direction * 350
		
		if projectile.has_method("launch"):
			projectile.launch(spawn_pos, target_pos)

func check_if_stuck(delta: float):
	if global_position.distance_to(last_position) < 10.0:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	last_position = global_position

func die():
	var death_type = enemy_type
	var death_position = global_position
	
	print("💀 ", enemy_type, " died!")
	
	# Signal au système de drops
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(death_type, death_position)
	
	# Signal au buff system
	var buff_system = get_tree().get_first_node_in_group("buff_system")
	if buff_system and buff_system.has_method("_on_enemy_killed"):
		buff_system._on_enemy_killed(death_type, death_position)
	
	# Stats selon le type
	if is_elite:
		GlobalData.add_kill("Elite")
	elif armor >= 0.5:
		GlobalData.add_kill("Armored")
	else:
		GlobalData.add_kill("basic")
	
	if GlobalData.has_signal("enemy_killed"):
		GlobalData.enemy_killed.emit(death_type, death_position)
	
	queue_free()
