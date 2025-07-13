# BaseEnemy.gd - Version complète sans erreurs
extends BaseCharacter
class_name BaseEnemy

# Stats spécifiques aux ennemis
var can_shoot: bool = false
var projectile_scene_path: String = ""
var fire_rate: float = 3.0
var detection_range: float = 300.0
var melee_range: float = 50.0
var is_elite: bool = false
var enemy_type: String = "Grunt"

# Variables pour les shooters
var optimal_distance: float = 200.0
var dodge_timer: float = 0.0
var dodge_cooldown: float = 2.0
var dodge_direction: Vector2 = Vector2.ZERO

# Variables pour les attaques mêlée
var melee_attack_cooldown: float = 0.0
var melee_attack_rate: float = 1.5
var is_melee_attacking: bool = false
var melee_attack_duration: float = 0.5
var melee_hitbox: Area2D = null
var attack_visual: Sprite2D = null

# Variables pour les attaques spéciales (Elite seulement)
var special_attack_cooldown: float = 0.0
var special_attack_delay: float = 20.0

# Variables d'état
var target: Player
var fire_timer: float = 0.0

func _ready():
	super._ready()
	add_to_group("enemies")
	
	# Configuration des collision layers
	collision_layer = 2
	collision_mask = 1
	
	target = get_tree().get_first_node_in_group("players")
	
	# Créer la hitbox mêlée
	setup_melee_hitbox()
	
	print("Enemy ready: ", enemy_type)

func setup_melee_hitbox():
	# Créer une hitbox mêlée temporaire
	melee_hitbox = Area2D.new()
	add_child(melee_hitbox)
	
	# Shape de la hitbox
	var hitbox_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 40.0
	hitbox_shape.shape = circle_shape
	melee_hitbox.add_child(hitbox_shape)
	
	# Configuration collision
	melee_hitbox.collision_layer = 0
	melee_hitbox.collision_mask = 1
	
	# Connecter le signal
	melee_hitbox.body_entered.connect(_on_melee_hit_player)
	
	# Désactiver par défaut
	melee_hitbox.monitoring = false
	melee_hitbox.visible = false

func _physics_process(delta):
	super._physics_process(delta)
	
	# Gérer le cooldown d'attaque mêlée
	if melee_attack_cooldown > 0:
		melee_attack_cooldown -= delta
	
	# Gérer la durée d'attaque mêlée
	if is_melee_attacking:
		melee_attack_duration -= delta
		if melee_attack_duration <= 0:
			end_melee_attack()
	
	# Gérer le cooldown des attaques spéciales
	if special_attack_cooldown > 0:
		special_attack_cooldown -= delta
	
	# Comportement selon le type
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		
		match enemy_type:
			"Grunt":
				grunt_behavior(delta, distance)
			"Shooter":
				shooter_behavior(delta, distance)
			"Elite":
				elite_behavior(delta, distance)

func grunt_behavior(_delta, distance):
	# Attaquer si assez proche
	if distance <= melee_range and can_melee_attack():
		start_melee_attack()
		return
	
	# Sinon se rapprocher
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func shooter_behavior(delta, distance):
	dodge_timer += delta
	
	if distance > optimal_distance:
		# Trop loin - se rapprocher
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * 0.8
		move_and_slide()
	elif distance < optimal_distance - 50:
		# Trop proche - reculer
		var direction = (global_position - target.global_position).normalized()
		velocity = direction * speed * 0.6
		move_and_slide()
	else:
		# À bonne distance - esquiver
		if dodge_timer >= dodge_cooldown:
			var random_angle = randf() * TAU
			dodge_direction = Vector2(cos(random_angle), sin(random_angle))
			dodge_timer = 0.0
		
		velocity = dodge_direction * speed * 0.4
		move_and_slide()
	
	# Tirer si à bonne distance
	if distance <= optimal_distance + 50 and can_shoot:
		handle_shooting(delta)

func elite_behavior(delta, distance):
	# Essayer une attaque spéciale (très rare)
	if try_special_attack():
		return
	
	# Attaque mêlée si proche
	if distance <= melee_range + 10 and can_melee_attack():
		start_melee_attack()
		return
	
	# Se rapprocher
	if distance > melee_range + 30:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * 0.7
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	
	# Tirer à distance moyenne
	if distance > 100 and distance < 250 and can_shoot and not is_melee_attacking:
		handle_shooting(delta)

func can_melee_attack() -> bool:
	return melee_attack_cooldown <= 0 and not is_melee_attacking

func start_melee_attack():
	if not can_melee_attack():
		return
	
	print(name, " attacks!")
	
	is_melee_attacking = true
	melee_attack_duration = 0.5
	melee_attack_cooldown = melee_attack_rate
	
	# Arrêter le mouvement
	velocity = Vector2.ZERO
	
	# Activer la hitbox
	melee_hitbox.monitoring = true
	
	# Effet visuel
	show_melee_attack_visual()

func end_melee_attack():
	if not is_melee_attacking:
		return
	
	is_melee_attacking = false
	
	call_deferred("disable_melee_hitbox")
	
	hide_melee_attack_visual()

func _on_melee_hit_player(body):
	if not is_melee_attacking:
		return
	
	if body.is_in_group("players") and body.has_method("take_damage"):
		# Dégâts selon le type
		var melee_damage: float
		match enemy_type:
			"Elite":
				melee_damage = damage * 1.2
			"Grunt":
				melee_damage = damage
			"Shooter":
				melee_damage = damage * 0.8
			_:
				melee_damage = damage
		
		body.take_damage(melee_damage)
		print("Melee hit for ", melee_damage, " damage!")
		
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
	
	# Dégâts équilibrés
	var projectile_damage: float
	match enemy_type:
		"Shooter":
			projectile_damage = damage * 0.6
		"Elite":
			projectile_damage = damage * 0.5
		_:
			projectile_damage = damage * 0.7
	
	projectile.setup(projectile_damage, 250.0, 4.0)
	
	var direction = (target.global_position - global_position).normalized()
	var spawn_pos = global_position + direction * 30
	
	projectile.launch(spawn_pos, target.global_position)

func try_special_attack():
	if enemy_type != "Elite":
		return false
	
	# Vérifier le cooldown
	if special_attack_cooldown > 0:
		return false
	
	# Chance très réduite : 0.2% par frame
	if randf() < 0.002:
		cast_simple_special_attack()
		special_attack_cooldown = special_attack_delay
		return true
	
	return false

func cast_simple_special_attack():
	print("Elite special attack!")
	
	# Attaque spéciale simple : 3 projectiles en éventail
	for i in range(3):
		if not ResourceLoader.exists(projectile_scene_path):
			continue
		
		var projectile_scene = load(projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		
		get_tree().current_scene.add_child(projectile)
		
		if projectile.has_method("set_owner_type"):
			projectile.set_owner_type("enemy")
		
		projectile.setup(damage * 0.8, 300.0, 5.0)
		
		# Direction en éventail
		var base_direction = (target.global_position - global_position).normalized()
		var angle_offset = (i - 1) * 0.3  # -0.3, 0, 0.3 radians
		var direction = base_direction.rotated(angle_offset)
		
		var spawn_pos = global_position + direction * 40
		var target_pos = global_position + direction * 300
		
		projectile.launch(spawn_pos, target_pos)
		
		await get_tree().create_timer(0.2).timeout

func show_melee_attack_visual():
	attack_visual = Sprite2D.new()
	add_child(attack_visual)
	
	# Cercle rouge
	var image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var center = Vector2(40, 40)
	
	for x in range(80):
		for y in range(80):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 35:
				var alpha = 0.5 * (1.0 - distance / 35.0)
				image.set_pixel(x, y, Color(1, 0.2, 0.2, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	attack_visual.texture = texture
	attack_visual.position = Vector2(-40, -40)
	
	# Animation
	var tween = create_tween()
	tween.tween_property(attack_visual, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(attack_visual, "modulate:a", 0.0, 0.3)

func hide_melee_attack_visual():
	if attack_visual and is_instance_valid(attack_visual):
		attack_visual.queue_free()
		attack_visual = null


# Méthode pour appliquer les effets de statut
func apply_status_effect(effect_type: String, duration: float, power: float):
	print("Enemy affected by: ", effect_type)
	
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

func update_animation():
	if not animation_player:
		return
	
	var anim_to_play = ""
	
	if is_moving:
		anim_to_play = "walk"
	else:
		anim_to_play = "idle"
	
	if animation_player.has_animation(anim_to_play):
		animation_player.play(anim_to_play)
	elif is_moving and animation_player.has_animation("walk"):
		animation_player.play("walk")
	elif not is_moving and animation_player.has_animation("idle"):
		animation_player.play("idle")
func die():
	print(name, " died!")
	
	# Stocker les infos AVANT queue_free()
	var death_type = enemy_type
	var death_position = global_position
	
	# Signal immédiat
	if GlobalData.has_signal("enemy_killed"):
		GlobalData.enemy_killed.emit(death_type, death_position)
	
	# Système direct
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(death_type, death_position)
	
	# Stats
	if is_elite:
		GlobalData.total_kills += 3
	else:
		GlobalData.add_kill()
	
	queue_free()
func signal_enemy_death_deferred():
	# Trouver le système de drops
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(enemy_type, global_position)
		print("Death signaled to drop system: ", enemy_type)
	else:
		print("Drop system not found!")
func configure_enemy_deferred(enemy_type_data: Dictionary):
	if not is_instance_valid(self):
		return
	
	max_health = enemy_type_data.health
	current_health = enemy_type_data.health
	speed = enemy_type_data.speed
	damage = enemy_type_data.damage
	can_shoot = enemy_type_data.get("can_shoot", false)
	is_elite = (enemy_type_data.name == "Elite")
	enemy_type = enemy_type_data.name
	
	if can_shoot:
		projectile_scene_path = enemy_type_data.get("projectile_path", "")
		
		match enemy_type:
			"Shooter":
				fire_rate = 3.5
				optimal_distance = 180.0
			"Elite":
				fire_rate = 4.0
	
	update_health_bar()
# NOUVELLE MÉTHODE : Signaler la mort pour drops
func signal_enemy_death():
	# Trouver le système de drops
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(enemy_type, global_position)
	
	# Ou utiliser un signal global si configuré
	if GlobalData.has_signal("enemy_killed"):
		GlobalData.enemy_killed.emit(enemy_type, global_position)
	
	print("Enemy death signaled: ", enemy_type, " at ", global_position)
