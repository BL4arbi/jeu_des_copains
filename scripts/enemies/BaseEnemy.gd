# BaseEnemy.gd - Version avec meilleure survie et comportement amélioré
extends BaseCharacter
class_name BaseEnemy
var armor: float = 0.0  # Pourcentage de réduction de dégâts (0.0 à 0.85)
var base_health: float = 25.0
var base_damage: float = 8.0
# Stats spécifiques aux ennemis (équilibrées)
var can_shoot: bool = false
var projectile_scene_path: String = ""
var fire_rate: float = 3.0
var detection_range: float = 400.0  # Augmenté
var melee_range: float = 50.0
var is_elite: bool = false
var enemy_type: String = "Grunt"

# Variables pour les shooters (améliorées)
var optimal_distance: float = 200.0
var dodge_timer: float = 0.0
var dodge_cooldown: float = 1.5  # Plus rapide
var dodge_direction: Vector2 = Vector2.ZERO
var last_known_player_pos: Vector2 = Vector2.ZERO

var target: Player
var fire_timer: float = 0.0
var stuck_timer: float = 0.0
var last_position: Vector2
var stuck_threshold: float = 3.0
var retreat_timer: float = 0.0

# Variables pour les attaques mêlée
var melee_attack_cooldown: float = 0.0
var melee_attack_rate: float = 1.5
var is_melee_attacking: bool = false
var melee_attack_duration: float = 0.5
var melee_hitbox: Area2D = null
var attack_visual: Sprite2D = null

# Variables pour les attaques spéciales
var special_attack_cooldown: float = 0.0
var special_attack_delay: float = 15.0  # Réduit

# Variables d'état améliorées
var armor_indicator: Sprite2D = null

func _ready():
	super._ready()
	add_to_group("enemies")
	
	# Configuration des collision layers
	collision_layer = 2
	collision_mask = 1
	
	target = get_tree().get_first_node_in_group("players")
	last_position = global_position
	
	setup_melee_hitbox()
	
	print("🐺 ", enemy_type, " enemy ready with ", max_health, " HP")

func configure_enemy_deferred(enemy_type_data: Dictionary):
	if not is_instance_valid(self):
		return
	# Configuration de base
	enemy_type = enemy_type_data.name
	base_health = enemy_type_data.health
	base_damage = enemy_type_data.damage
	speed = enemy_type_data.speed
	can_shoot = enemy_type_data.get("can_shoot", false)
	is_elite = (enemy_type == "Elite")
	
	# NOUVEAU : Appliquer la progression basée sur les kills
	apply_difficulty_scaling()
	
	# Configuration spéciale selon le type
	if can_shoot:
		projectile_scene_path = enemy_type_data.get("projectile_path", "")
		configure_shooting_stats()
	
	update_health_bar()
	setup_armor_visual()
	print("🐺 ", enemy_type, " configured: ", max_health, "HP, ", speed, " speed")
func configure_shooting_stats():
	match enemy_type:
		"Shooter":
			fire_rate = 2.8
			optimal_distance = 160.0
			dodge_cooldown = 1.2
		"Elite":
			fire_rate = 2.5
			special_attack_delay = 12.0

func setup_armor_visual():
	if armor <= 0.1:
		return  # Pas d'indicateur pour peu d'armure
	
	# Créer un indicateur visuel d'armure
	armor_indicator = Sprite2D.new()
	add_child(armor_indicator)
	armor_indicator.z_index = 1
	
	# Couleur selon le niveau d'armure
	var armor_color: Color
	if armor >= 0.7:
		armor_color = Color.GOLD  # Armure ultime
	elif armor >= 0.5:
		armor_color = Color.PURPLE  # Armure lourde
	elif armor >= 0.3:
		armor_color = Color.BLUE  # Armure moyenne
	else:
		armor_color = Color.GRAY  # Armure légère
	
	# Créer l'effet d'armure (contour brillant)
	var armor_size = 40
	var image = Image.create(armor_size, armor_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(armor_size / 2, armor_size / 2)
	
	for x in range(armor_size):
		for y in range(armor_size):
			var distance = Vector2(x, y).distance_to(center)
			# Créer un contour
			if distance >= 15 and distance <= 18:
				var alpha = 0.6 * armor  # Plus d'armure = plus visible
				image.set_pixel(x, y, Color(armor_color.r, armor_color.g, armor_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	armor_indicator.texture = texture
	armor_indicator.position = Vector2(-armor_size / 2, -armor_size / 2)
	
	# Animation de brillance
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(armor_indicator, "modulate:a", 0.3, 1.0)
	tween.tween_property(armor_indicator, "modulate:a", 0.8, 1.0)

# OVERRIDE take_damage pour gérer l'armure
func take_damage(amount: float):
	# Calculer les dégâts après armure
	var damage_reduction = amount * armor
	var final_damage = amount - damage_reduction
	
	# Effet visuel de réduction de dégâts
	if damage_reduction > 0:
		show_armor_effect(damage_reduction)
	
	# Appliquer les dégâts réduits
	super.take_damage(final_damage)
	
	print("🛡️ ", enemy_type, " took ", final_damage, "/", amount, " damage (", int(damage_reduction), " blocked by armor)")

func show_armor_effect(blocked_damage: float):
	# Effet visuel quand l'armure bloque des dégâts
	if armor_indicator and is_instance_valid(armor_indicator):
		# Flash de l'armure
		var original_scale = armor_indicator.scale
		var tween = create_tween()
		tween.tween_property(armor_indicator, "scale", original_scale * 1.3, 0.1)
		tween.tween_property(armor_indicator, "scale", original_scale, 0.1)
	
	# Texte flottant des dégâts bloqués
	create_damage_text("-" + str(int(blocked_damage)), Color.YELLOW)

func create_damage_text(text: String, color: Color):
	var damage_label = Label.new()
	damage_label.text = text
	damage_label.add_theme_color_override("font_color", color)
	damage_label.add_theme_font_size_override("font_size", 14)
	damage_label.position = global_position + Vector2(randf_range(-20, 20), -30)
	
	get_tree().current_scene.add_child(damage_label)
	
	# Animation du texte
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.5)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func(): damage_label.queue_free())
func apply_difficulty_scaling():
	# Obtenir les stats mises à l'échelle
	var difficulty_manager = get_node_or_null("/root/DifficultyManager")
	var scaled_stats: Dictionary
	
	if difficulty_manager:
		scaled_stats = difficulty_manager.get_enemy_stats(enemy_type)
	else:
		# Fallback si pas de DifficultyManager
		scaled_stats = {
			"health": base_health,
			"damage": base_damage,
			"armor": 0.0
		}
	
	# Appliquer les stats
	max_health = scaled_stats.health
	current_health = max_health
	damage = scaled_stats.damage
	armor = scaled_stats.armor
	
func setup_melee_hitbox():
	melee_hitbox = Area2D.new()
	add_child(melee_hitbox)
	
	var hitbox_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 45.0  # Légèrement plus grand
	hitbox_shape.shape = circle_shape
	melee_hitbox.add_child(hitbox_shape)
	
	melee_hitbox.collision_layer = 0
	melee_hitbox.collision_mask = 1
	melee_hitbox.body_entered.connect(_on_melee_hit_player)
	melee_hitbox.monitoring = false
	melee_hitbox.visible = false

func _physics_process(delta):
	super._physics_process(delta)
	
	# Gestion des cooldowns
	if melee_attack_cooldown > 0:
		melee_attack_cooldown -= delta
	if special_attack_cooldown > 0:
		special_attack_cooldown -= delta
	if retreat_timer > 0:
		retreat_timer -= delta
	
	# Gestion de l'attaque mêlée
	if is_melee_attacking:
		melee_attack_duration -= delta
		if melee_attack_duration <= 0:
			end_melee_attack()
	
	# Détection de blocage
	check_if_stuck(delta)
	
	# Comportement selon le type
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		last_known_player_pos = target.global_position
		
		# Comportement selon le type avec améliorations
		match enemy_type:
			"Grunt":
				improved_grunt_behavior(delta, distance)
			"Shooter":
				improved_shooter_behavior(delta, distance)
			"Elite":
				improved_elite_behavior(delta, distance)
	else:
		# Chercher vers la dernière position connue
		seek_last_known_position(delta)

func improved_grunt_behavior(delta, distance):
	# Grunt amélioré - plus intelligent
	
	if distance <= melee_range and can_melee_attack():
		start_melee_attack()
		return
	
	# Mouvement plus intelligent
	if distance > detection_range:
		# Patrouille aléatoire si trop loin
		random_movement(delta)
	else:
		# Charge vers le joueur avec esquive
		var direction = (target.global_position - global_position).normalized()
		
		# Esquive occasionnelle
		if stuck_timer > 1.0 or (randf() < 0.1 and dodge_timer <= 0):
			direction = direction.rotated(randf_range(-PI/3, PI/3))
			dodge_timer = dodge_cooldown
		
		velocity = direction * speed
		move_and_slide()

func improved_shooter_behavior(delta, distance):
	dodge_timer += delta
	
	# Logique de distance optimale améliorée
	if distance > optimal_distance + 50:
		# Trop loin - approche avec prudence
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * 0.7
		move_and_slide()
		
	elif distance < optimal_distance - 30:
		# Trop proche - retraite tactique
		if retreat_timer <= 0:
			var direction = (global_position - target.global_position).normalized()
			# Esquive latérale pendant la retraite
			direction = direction.rotated(randf_range(-PI/4, PI/4))
			velocity = direction * speed * 0.8
			retreat_timer = 2.0
		else:
			velocity = velocity * 0.5  # Ralentir pendant la retraite
		move_and_slide()
		
	else:
		# À bonne distance - mouvement d'esquive
		if dodge_timer >= dodge_cooldown or stuck_timer > 0.5:
			var random_angle = randf() * TAU
			dodge_direction = Vector2(cos(random_angle), sin(random_angle))
			dodge_timer = 0.0
			stuck_timer = 0.0
		
		velocity = dodge_direction * speed * 0.5
		move_and_slide()
	
	# Tir amélioré
	if distance <= optimal_distance + 80 and can_shoot:
		handle_shooting(delta)

func improved_elite_behavior(delta, distance):
	# Elite avec IA avancée
	
	# Attaque spéciale plus fréquente
	if try_special_attack():
		return
	
	# Combat hybride intelligent
	if distance <= melee_range + 15 and can_melee_attack():
		# Attaque mêlée si très proche
		start_melee_attack()
		return
	elif distance > melee_range + 30 and distance <= 200:
		# Distance moyenne - mouvement tactique
		var direction = (target.global_position - global_position).normalized()
		
		# Mouvement en cercle autour du joueur
		var circle_direction = direction.rotated(PI/2)
		if randf() < 0.5:
			circle_direction = direction.rotated(-PI/2)
		
		velocity = (direction * 0.6 + circle_direction * 0.4) * speed * 0.8
		move_and_slide()
	else:
		# Mouvement d'approche
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * 0.6
		move_and_slide()
	
	# Tir à distance optimale
	if distance > 80 and distance < 300 and can_shoot and not is_melee_attacking:
		handle_shooting(delta)

func check_if_stuck(delta):
	# Vérifier si l'ennemi est bloqué
	var movement_threshold = 10.0
	
	if global_position.distance_to(last_position) < movement_threshold:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func seek_last_known_position(delta):
	# Aller vers la dernière position connue du joueur
	if last_known_player_pos != Vector2.ZERO:
		var direction = (last_known_player_pos - global_position).normalized()
		velocity = direction * speed * 0.5
		move_and_slide()

func random_movement(delta):
	# Mouvement aléatoire pour patrouille
	if randf() < 0.02:  # 2% de chance de changer de direction
		dodge_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	velocity = dodge_direction * speed * 0.3
	move_and_slide()

func can_melee_attack() -> bool:
	return melee_attack_cooldown <= 0 and not is_melee_attacking

func start_melee_attack():
	if not can_melee_attack():
		return
	
	is_melee_attacking = true
	melee_attack_duration = 0.5
	melee_attack_cooldown = melee_attack_rate
	
	# Arrêter le mouvement
	velocity = Vector2.ZERO
	
	# Activer la hitbox
	if melee_hitbox:
		melee_hitbox.monitoring = true
	
	# Effet visuel
	show_melee_attack_visual()
	
	print("👊 ", enemy_type, " starts melee attack!")

func end_melee_attack():
	if not is_melee_attacking:
		return
	
	is_melee_attacking = false
	
	# Désactiver la hitbox
	if melee_hitbox and is_instance_valid(melee_hitbox):
		melee_hitbox.monitoring = false
	
	hide_melee_attack_visual()
	
	print("👊 ", enemy_type, " ends melee attack")

func _on_melee_hit_player(body):
	if not is_melee_attacking:
		return
	
	if body.is_in_group("players") and body.has_method("take_damage"):
		# Dégâts selon le type
		var melee_damage: float
		match enemy_type:
			"Elite":
				melee_damage = damage * 1.3
			"Grunt":
				melee_damage = damage * 1.1
			"Shooter":
				melee_damage = damage * 0.9
			_:
				melee_damage = damage
		
		body.take_damage(melee_damage)
		print("👊 ", enemy_type, " melee hit for ", melee_damage, " damage!")
		
		# Finir l'attaque après avoir touché
		end_melee_attack()

func handle_shooting(delta):
	if not target or projectile_scene_path == "" or is_melee_attacking:
		return
	
	fire_timer += delta
	
	if fire_timer >= fire_rate:
		shoot_at_player()
		fire_timer = 0.0

func shoot_at_player():
	if not ResourceLoader.exists(projectile_scene_path):
		print("ERROR: Projectile scene not found: ", projectile_scene_path)
		return
	
	var projectile_scene = load(projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	# Configuration du projectile
	if projectile.has_method("set_owner_type"):
		projectile.set_owner_type("enemy")
	
	# Dégâts selon le type
	var projectile_damage: float
	match enemy_type:
		"Shooter":
			projectile_damage = damage * 0.7
		"Elite":
			projectile_damage = damage * 0.6
		_:
			projectile_damage = damage * 0.8
	
	projectile.setup(projectile_damage, 280.0, 4.0)
	
	# Direction avec légère prédiction
	var target_velocity = Vector2.ZERO
	if target.has_method("get_velocity"):
		target_velocity = target.velocity
	
	var prediction_time = 0.5
	var predicted_pos = target.global_position + target_velocity * prediction_time
	var direction = (predicted_pos - global_position).normalized()
	
	var spawn_pos = global_position + direction * 30
	projectile.launch(spawn_pos, predicted_pos)
	
	print("🔫 ", enemy_type, " shoots!")

func try_special_attack():
	if enemy_type != "Elite":
		return false
	
	# Vérifier le cooldown
	if special_attack_cooldown > 0:
		return false
	
	# Chance réduite mais pas trop rare
	if randf() < 0.008:  # 0.8% par frame
		cast_special_attack()
		special_attack_cooldown = special_attack_delay
		return true
	
	return false

func cast_special_attack():
	print("⚡ ", enemy_type, " uses special attack!")
	
	# Attaque spéciale : 3 projectiles en éventail
	for i in range(3):
		if not ResourceLoader.exists(projectile_scene_path):
			continue
		
		var projectile_scene = load(projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		
		get_tree().current_scene.add_child(projectile)
		
		if projectile.has_method("set_owner_type"):
			projectile.set_owner_type("enemy")
		
		projectile.setup(damage * 0.9, 320.0, 5.0)
		
		# Direction en éventail
		var base_direction = (target.global_position - global_position).normalized()
		var angle_offset = (i - 1) * 0.4  # -0.4, 0, 0.4 radians
		var direction = base_direction.rotated(angle_offset)
		
		var spawn_pos = global_position + direction * 40
		var target_pos = global_position + direction * 350
		
		projectile.launch(spawn_pos, target_pos)
		
		await get_tree().create_timer(0.15).timeout

func show_melee_attack_visual():
	if attack_visual and is_instance_valid(attack_visual):
		attack_visual.queue_free()
	
	attack_visual = Sprite2D.new()
	add_child(attack_visual)
	
	# Cercle rouge d'attaque
	var image = Image.create(90, 90, false, Image.FORMAT_RGBA8)
	var center = Vector2(45, 45)
	
	for x in range(90):
		for y in range(90):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 40:
				var alpha = 0.6 * (1.0 - distance / 40.0)
				var color = Color.RED if enemy_type == "Elite" else Color.ORANGE
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	attack_visual.texture = texture
	attack_visual.position = Vector2(-45, -45)
	
	# Animation d'expansion
	var tween = create_tween()
	tween.tween_property(attack_visual, "scale", Vector2(1.8, 1.8), 0.3)
	tween.parallel().tween_property(attack_visual, "modulate:a", 0.0, 0.3)

func hide_melee_attack_visual():
	if attack_visual and is_instance_valid(attack_visual):
		attack_visual.queue_free()
		attack_visual = null

# Méthodes existantes pour effets de statut
func apply_status_effect(effect_type: String, duration: float, power: float):
	print(enemy_type, " affected by: ", effect_type)
	
	match effect_type:
		"slow":
			apply_slow_effect(duration, power)
		"poison":
			apply_poison_effect(duration, power)
		"burn":
			apply_burn_effect(duration, power)
		"freeze":
			apply_freeze_effect(duration)

func apply_slow_effect(duration: float, power: float):
	var original_speed = speed
	speed *= power
	
	if sprite:
		sprite.modulate = Color.BLUE * 1.2
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		if sprite and is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
		timer.queue_free()
	)
	timer.start()

func apply_poison_effect(duration: float, power: float):
	if sprite:
		sprite.modulate = Color.GREEN * 1.2
	
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
		if sprite and is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
		poison_timer.queue_free()
		end_timer.queue_free()
	)
	end_timer.start()

func apply_burn_effect(duration: float, power: float):
	if sprite:
		sprite.modulate = Color.RED * 1.3
	apply_poison_effect(duration, power)

func apply_freeze_effect(duration: float):
	var original_speed = speed
	speed = 0
	
	if sprite:
		sprite.modulate = Color.LIGHT_BLUE * 1.3
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		if sprite and is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
		timer.queue_free()
	)
	timer.start()

func die():
	# Stocker les infos AVANT queue_free()
	var death_type = enemy_type
	var death_position = global_position
	var enemy_armor = armor
	
	print("💀 ", enemy_type, " died (had ", int(armor*100), "% armor)")
	
	# Signal au système de drops
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(death_type, death_position)
	
	# Stats selon le type et l'armure
	var kill_value = 1
	if is_elite:
		kill_value = 3
	elif armor >= 0.5:  # Ennemis blindés valent plus
		kill_value = 2
	
	for i in range(kill_value):
		GlobalData.add_kill()
	
	queue_free()
