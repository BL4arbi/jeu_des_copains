# BaseEnemy.gd - Version avec erreur process_frame corrigée
extends BaseCharacter
class_name BaseEnemy

# === VARIABLES DE BASE ===
var enemy_type: String = "Grunt"
var is_elite: bool = false
var armor: float = 0.0

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
	
	target = get_tree().get_first_node_in_group("players")
	last_position = global_position
	
	setup_melee_hitbox()
	print("🐺 ", enemy_type, " enemy ready!")

# CORRECTION : Version simplifiée sans await process_frame
func configure_enemy_deferred(enemy_data: Dictionary):
	# Vérifier que l'objet existe toujours
	if not is_instance_valid(self):
		print("❌ Enemy instance invalid during configuration")
		return
	
	# Configuration de base
	enemy_type = enemy_data.name
	base_health = enemy_data.health * 1.3
	base_damage = enemy_data.damage
	speed = enemy_data.speed
	can_shoot = enemy_data.get("can_shoot", false)
	is_elite = (enemy_type == "Elite")
	
	# Appliquer la progression des kills
	apply_difficulty_scaling()
	
	# Configuration tir
	if can_shoot:
		projectile_scene_path = enemy_data.get("projectile_path", "")
		configure_shooting_stats()
	
	# Mise à jour visuelle
	call_deferred("update_visuals")
	
	print("🐺 ", enemy_type, " configured: ", max_health, "HP, ", damage, " damage")

func update_visuals():
	# Séparer la mise à jour visuelle pour éviter les erreurs
	if is_instance_valid(self):
		update_health_bar()
		setup_armor_visual()

func apply_difficulty_scaling():
	# Version simplifiée sans dépendance externe
	var kill_bonus = GlobalData.total_kills if GlobalData else 0
	
	# Bonus simple basé sur les kills
	var health_multiplier = 1.0 + (kill_bonus * 0.05)  # +5% par kill
	var damage_multiplier = 1.0 + (kill_bonus * 0.03)  # +3% par kill
	
	max_health = base_health * health_multiplier
	current_health = max_health
	damage = base_damage * damage_multiplier
	
	# Armure simple selon le type
	match enemy_type:
		"Elite":
			armor = 0.2 + (kill_bonus * 0.01)  # 20% + 1% par kill
		"Shooter":
			armor = 0.1 + (kill_bonus * 0.005)  # 10% + 0.5% par kill
		_:
			armor = kill_bonus * 0.002  # 0.2% par kill
	
	armor = min(armor, 0.8)  # Max 80%

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
	
	# Nettoyer l'ancien indicateur
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
		return  # Déjà configuré
	
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

# === OVERRIDE TAKE_DAMAGE POUR L'ARMURE ===
func take_damage(amount: float):
	var damage_reduction = amount * armor
	var final_damage = amount - damage_reduction
	
	if damage_reduction > 0:
		show_armor_effect()
	
	super.take_damage(final_damage)
	print("🛡️ ", enemy_type, " took ", final_damage, "/", amount, " damage (", int(damage_reduction), " blocked)")

func show_armor_effect():
	if armor_indicator and is_instance_valid(armor_indicator):
		var tween = create_tween()
		tween.tween_property(armor_indicator, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(armor_indicator, "scale", Vector2(1.0, 1.0), 0.1)

# === PHYSICS PROCESS ===
func _physics_process(delta):
	super._physics_process(delta)
	
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
	
	# Vérifier si bloqué
	check_if_stuck(delta)
	
	# Comportement IA
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		
		match enemy_type:
			"Grunt":
				grunt_behavior(distance)
			"Shooter":
				shooter_behavior(delta, distance)
			"Elite":
				elite_behavior(delta, distance)

# === COMPORTEMENTS IA SIMPLIFIÉS ===
func grunt_behavior(distance: float):
	if distance <= melee_range and can_melee_attack():
		start_melee_attack()
		return
	
	if distance > detection_range:
		return
	
	var direction = (target.global_position - global_position).normalized()
	if stuck_timer > 1.0:
		direction = direction.rotated(randf_range(-PI/3, PI/3))
	
	velocity = direction * speed
	move_and_slide()

func shooter_behavior(delta: float, distance: float):
	if distance > optimal_distance + 50:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * 0.7
		move_and_slide()
	elif distance < optimal_distance - 30:
		var direction = (global_position - target.global_position).normalized()
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
		var direction = (target.global_position - global_position).normalized()
		var circle_direction = direction.rotated(PI/2 if randf() < 0.5 else -PI/2)
		velocity = (direction * 0.6 + circle_direction * 0.4) * speed * 0.8
		move_and_slide()
	
	if can_shoot and distance > 80 and distance < 300 and not is_melee_attacking:
		handle_shooting(delta)

# === ATTAQUE MÊLÉE ===
func can_melee_attack() -> bool:
	return melee_attack_cooldown <= 0 and not is_melee_attacking

func start_melee_attack():
	if not can_melee_attack():
		return
	
	is_melee_attacking = true
	melee_attack_duration = 0.5
	melee_attack_cooldown = melee_attack_rate
	velocity = Vector2.ZERO
	
	# Activation hitbox sécurisée
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

# === EFFETS VISUELS SIMPLES ===
func show_melee_attack_visual():
	if attack_visual and is_instance_valid(attack_visual):
		attack_visual.queue_free()
	
	attack_visual = Sprite2D.new()
	add_child(attack_visual)
	
	# Effet simple rouge
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

# === TIR SIMPLIFIÉ ===
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
	
	get_tree().current_scene.add_child(projectile)
	
	if projectile.has_method("set_owner_type"):
		projectile.set_owner_type("enemy")
	
	var projectile_damage = damage * 0.7
	if projectile.has_method("setup"):
		projectile.setup(projectile_damage, 280.0, 4.0)
	
	var direction = (target.global_position - global_position).normalized()
	var spawn_pos = global_position + direction * 30
	
	if projectile.has_method("launch"):
		projectile.launch(spawn_pos, target.global_position)

# === ATTAQUES SPÉCIALES SIMPLIFIÉES ===
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
	
	# Tir en éventail simple
	for i in range(3):
		var projectile_scene = load(projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		if projectile.has_method("set_owner_type"):
			projectile.set_owner_type("enemy")
		
		if projectile.has_method("setup"):
			projectile.setup(damage * 0.9, 320.0, 5.0)
		
		var base_direction = (target.global_position - global_position).normalized()
		var angle_offset = (i - 1) * 0.4
		var direction = base_direction.rotated(angle_offset)
		var spawn_pos = global_position + direction * 40
		var target_pos = global_position + direction * 350
		
		if projectile.has_method("launch"):
			projectile.launch(spawn_pos, target_pos)

# === UTILITAIRES ===
func check_if_stuck(delta: float):
	if global_position.distance_to(last_position) < 10.0:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	last_position = global_position

# === MORT ===
func die():
	var death_type = enemy_type
	var death_position = global_position
	
	print("💀 ", enemy_type, " died!")
	
	# Signal au système de drops
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(death_type, death_position)
	
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

# === EFFETS DE STATUT SIMPLIFIÉS ===
func apply_status_effect(effect_type: String, duration: float, power: float):
	match effect_type:
		"slow":
			apply_slow_effect(duration, power)
		"poison":
			apply_poison_effect(duration, power)
		"freeze":
			apply_freeze_effect(duration)

func apply_slow_effect(duration: float, power: float):
	var original_speed = speed
	speed *= power
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		timer.queue_free()
	)
	timer.start()

func apply_poison_effect(duration: float, power: float):
	var poison_timer = Timer.new()
	add_child(poison_timer)
	poison_timer.wait_time = 0.5
	poison_timer.timeout.connect(func(): take_damage(power))
	poison_timer.start()
	
	var end_timer = Timer.new()
	add_child(end_timer)
	end_timer.wait_time = duration
	end_timer.one_shot = true
	end_timer.timeout.connect(func():
		poison_timer.queue_free()
		end_timer.queue_free()
	)
	end_timer.start()

func apply_freeze_effect(duration: float):
	var original_speed = speed
	speed = 0
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		timer.queue_free()
	)
	timer.start()
