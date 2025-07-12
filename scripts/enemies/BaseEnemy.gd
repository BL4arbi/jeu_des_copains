# BaseEnemy.gd mis à jour
extends BaseCharacter
class_name BaseEnemy

# Stats spécifiques aux ennemis
var can_shoot: bool = false
var projectile_scene_path: String = ""
var fire_rate: float = 2.0
var detection_range: float = 300.0
var melee_range: float = 50.0
var is_elite: bool = false
var enemy_type: String = "Grunt"

# Variables pour les shooters
var optimal_distance: float = 200.0
var dodge_timer: float = 0.0
var dodge_cooldown: float = 2.0
var dodge_direction: Vector2 = Vector2.ZERO
# Variables pour les attaques spéciales
var is_casting_special: bool = false
var cast_time: float = 0.0
var cast_duration: float = 2.0  # 2 secondes de cast
var special_attack_indicators: Array = []
# Composants additionnels
@onready var area_detector: Area2D = get_node_or_null("Area2D")
@onready var area_collision: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")

# Variables d'état
var target: Player
var fire_timer: float = 0.0

func _ready():
	super._ready()
	add_to_group("enemies")
	
	# Configuration des collision layers pour les ennemis
	collision_layer = 2  # Layer 2 pour les ennemis
	collision_mask = 1   # Peut collider avec le joueur (layer 1)
	
	target = get_tree().get_first_node_in_group("players")
	
	if area_detector:
		area_detector.body_entered.connect(_on_hit_player)
	
	print("=== ENEMY READY ===")
	print("Enemy collision_layer: ", collision_layer)
	print("Enemy collision_mask: ", collision_mask) 
	print("Enemy groups: ", get_groups())
	print("Enemy type: ", enemy_type)

func _physics_process(delta):
	super._physics_process(delta)
	
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		
		# Comportement selon le type d'ennemi
		match enemy_type:
			"Grunt":
				basic_behavior(delta, distance)
			"Shooter":
				shooter_behavior(delta, distance)
			"Elite":
				elite_behavior(delta, distance)

func basic_behavior(_delta, _distance):
	# Fonce droit vers le joueur pour attaque au corps à corps
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func shooter_behavior(delta, distance):
	dodge_timer += delta
	
	if distance > optimal_distance:
		# Trop loin - se rapprocher
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	elif distance < optimal_distance - 50:
		# Trop proche - reculer
		var direction = (global_position - target.global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		# À bonne distance - bouger aléatoirement pour esquiver
		if dodge_timer >= dodge_cooldown:
			var random_angle = randf() * TAU
			dodge_direction = Vector2(cos(random_angle), sin(random_angle))
			dodge_timer = 0.0
		
		velocity = dodge_direction * speed * 0.6
		move_and_slide()
	
	# Tirer si à bonne distance
	if distance <= optimal_distance + 50 and can_shoot:
		handle_shooting(delta)


func handle_shooting(delta):
	if not target or projectile_scene_path == "":
		return
		
	fire_timer += delta
	
	if fire_timer >= fire_rate:
		shoot_at_player()
		fire_timer = 0.0

func shoot_at_player():
	if not ResourceLoader.exists(projectile_scene_path):
		print("ERROR: Enemy projectile scene not found: ", projectile_scene_path)
		return
	
	var projectile_scene = load(projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	# Configurer le projectile comme projectile ennemi
	projectile.set_owner_type("enemy")
	
	# Configuration selon le type d'ennemi
	var projectile_damage = damage * 0.8 if enemy_type == "Shooter" else damage * 0.6
	projectile.setup(projectile_damage, 250.0, 4.0)
	
	# Types de projectiles spéciaux selon l'ennemi
	match enemy_type:
		"Elite":
			configure_elite_projectile(projectile)
		"Shooter":
			configure_shooter_projectile(projectile)
		"Grunt":
			configure_grunt_projectile(projectile)
	
	var direction = (target.global_position - global_position).normalized()
	var spawn_pos = global_position + direction * 30
	
	projectile.launch(spawn_pos, target.global_position)

func configure_elite_projectile(projectile):
	# Elite tire des projectiles spéciaux selon un pattern
	var special_attack = randi() % 3
	
	match special_attack:
		0:  # Lightning
			projectile.set_projectile_type("lightning")
			projectile.add_status_effect("slow", 2.0, 0.3)
		1:  # Homing
			projectile.set_projectile_type("homing") 
			projectile.homing_strength = 3.0
		2:  # Fork
			projectile.set_projectile_type("fork")

func configure_shooter_projectile(projectile):
	# Shooter tire des projectiles rapides avec poison
	projectile.set_projectile_type("basic")
	if randf() < 0.3:  # 30% de chance d'avoir du poison
		projectile.add_status_effect("poison", 4.0, 3.0)

func configure_grunt_projectile(projectile):
	# Grunt tire des projectiles basiques
	projectile.set_projectile_type("basic")

# Méthodes pour attaques spéciales des Elite
func cast_meteor_rain():
	if enemy_type != "Elite" or is_casting_special:
		return
	
	print("Elite preparing meteor rain...")
	start_casting("meteor_rain")
	
	# Montrer les zones d'impact AVANT que les météores tombent
	show_meteor_warnings()
	
	# Attendre la fin du cast
	await get_tree().create_timer(cast_duration).timeout
	
	if not is_casting_special:  # Cast interrompu
		return
	
	print("Elite casting meteor rain!")
	
	# Maintenant lancer les vrais météores
	for i in range(3):
		var meteor_scene = load("res://scenes/projectiles/BasicProjectile.tscn")
		var meteor = meteor_scene.instantiate()
		
		get_tree().current_scene.add_child(meteor)
		
		# Configuration météorite
		meteor.set_owner_type("enemy")
		meteor.set_projectile_type("meteor")
		meteor.setup(damage * 1.0, 200.0, 8.0)
		
		# Utiliser les positions pré-calculées
		if i < special_attack_indicators.size():
			var indicator = special_attack_indicators[i]
			var sky_position = indicator.global_position + Vector2(0, -400)
			meteor.launch(sky_position, indicator.global_position)
		
		await get_tree().create_timer(0.5).timeout
	
	finish_casting() 
func show_meteor_warnings():
	# Nettoyer les anciens indicateurs
	clear_attack_indicators()
	
	# Créer 3 zones d'avertissement
	for i in range(3):
		var warning = create_warning_indicator("meteor")
		
		# Position aléatoire autour du joueur
		var target_pos = target.global_position
		var random_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
		warning.global_position = target_pos + random_offset
		
		special_attack_indicators.append(warning)
		get_tree().current_scene.add_child(warning)
		
		print("Meteor warning at: ", warning.global_position)
func cast_lightning_storm():
	if enemy_type != "Elite":
		return
	
	print("Elite casting lightning storm!")
	
	# Créer des éclairs qui frappent autour du joueur
	for i in range(8):
		var lightning_scene = load("res://scenes/projectiles/BasicProjectile.tscn")
		var lightning = lightning_scene.instantiate()
		
		get_tree().current_scene.add_child(lightning)
		
		# Configuration éclair
		lightning.set_owner_type("enemy")
		lightning.set_projectile_type("lightning")
		lightning.setup(damage, 800.0, 1.0)
		lightning.add_status_effect("freeze", 1.5, 1.0)
		
		# Position en cercle autour du joueur
		var angle = (i * PI * 2) / 8
		var circle_pos = target.global_position + Vector2(cos(angle), sin(angle)) * 200
		
		lightning.launch(circle_pos, target.global_position)
		
		await get_tree().create_timer(0.1).timeout

# Appeler les attaques spéciales avec une chance
func try_special_attack():
	if enemy_type != "Elite":
		return false
	
	if randf() < 0.1:  # 10% de chance par frame de physics
		var special_type = randi() % 2
		match special_type:
			0:
				cast_meteor_rain()
			1:
				cast_lightning_storm()
		return true
	
	return false

# Modifier le comportement Elite pour inclure les attaques spéciales
func elite_behavior(delta, distance):
	# Essayer une attaque spéciale
	if try_special_attack():
		return  # Pas de mouvement pendant l'attaque spéciale
	
	if distance > melee_range + 20:
		# Se rapprocher pour attaque au corps à corps
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		# À portée - arrêter de bouger
		velocity = Vector2.ZERO
	
	# Tirer aussi si pas trop proche
	if distance > 80 and distance < 300 and can_shoot:
		handle_shooting(delta)

func die():
	print(name, " died!")
	
	if is_elite:
		GlobalData.total_kills += 3
	else:
		GlobalData.add_kill()
	
	# Animation de mort selon le type d'ennemi
	if animation_player:
		var death_anim = get_death_animation()
		if animation_player.has_animation(death_anim):
			animation_player.play(death_anim)
			await animation_player.animation_finished
	
	queue_free()

func get_death_animation() -> String:
	match enemy_type:
		"Elite":
			return "elite_death" if animation_player.has_animation("elite_death") else "death"
		"Shooter": 
			return "shooter_death" if animation_player.has_animation("shooter_death") else "death"
		_:
			return "death"

# Override pour animations spécifiques aux ennemis
func update_animation():
	if not animation_player:
		return
	
	var anim_to_play = ""
	
	if is_moving:
		# Animation de marche selon le type d'ennemi
		match enemy_type:
			"Elite":
				anim_to_play = "elite_walk" if animation_player.has_animation("elite_walk") else "walk"
			"Shooter":
				anim_to_play = "shooter_walk" if animation_player.has_animation("shooter_walk") else "walk"
			"Grunt":
				anim_to_play = "grunt_walk" if animation_player.has_animation("grunt_walk") else "walk"
			_:
				anim_to_play = "walk"
	else:
		# Animation idle selon le type d'ennemi
		match enemy_type:
			"Elite":
				anim_to_play = "elite_idle" if animation_player.has_animation("elite_idle") else "idle"
			"Shooter":
				anim_to_play = "shooter_idle" if animation_player.has_animation("shooter_idle") else "idle"
			"Grunt":
				anim_to_play = "grunt_idle" if animation_player.has_animation("grunt_idle") else "idle"
			_:
				anim_to_play = "idle"
	
	if animation_player.has_animation(anim_to_play):
		animation_player.play(anim_to_play)
	elif is_moving and animation_player.has_animation("walk"):
		animation_player.play("walk")
	elif not is_moving and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _on_hit_player(body):
	if body.is_in_group("players") and body.has_method("take_damage"):
		# Dégâts de mêlée plus élevés pour l'élite
		var melee_damage = damage * 1.5 if is_elite else damage
		body.take_damage(melee_damage)
		print(name, " hit player for ", melee_damage, " melee damage!")
		
		# Appliquer des effets de statut en mêlée
		if body.has_method("apply_status_effect"):
			match enemy_type:
				"Elite":
					# Elite applique poison en mêlée
					body.apply_status_effect("poison", 3.0, 2.0)
				"Shooter":
					# Shooter applique ralentissement
					body.apply_status_effect("slow", 1.5, 0.7)

# Méthode pour appliquer les effets de statut aux ennemis
func apply_status_effect(effect_type: String, duration: float, power: float):
	print("Enemy affected by: ", effect_type, " for ", duration, "s")
	
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
	speed *= power  # power < 1.0 pour ralentir
	
	# Effect visuel (optionnel)
	if sprite:
		sprite.modulate = Color.BLUE * 1.3
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		if sprite:
			sprite.modulate = Color.WHITE
		timer.queue_free()
	)
	timer.start()

func apply_poison_effect(duration: float, power: float):
	# Effet visuel poison
	if sprite:
		sprite.modulate = Color.GREEN * 1.3
	
	var poison_timer = Timer.new()
	add_child(poison_timer)
	poison_timer.wait_time = 0.5  # Dégâts toutes les 0.5s
	poison_timer.timeout.connect(func(): 
		take_damage(power)
	)
	poison_timer.start()
	
	# Timer pour arrêter le poison
	var end_timer = Timer.new()
	add_child(end_timer)
	end_timer.wait_time = duration
	end_timer.one_shot = true
	end_timer.timeout.connect(func():
		if sprite:
			sprite.modulate = Color.WHITE
		poison_timer.queue_free()
		end_timer.queue_free()
	)
	end_timer.start()

func apply_burn_effect(duration: float, power: float):
	# Effet visuel brûlure
	if sprite:
		sprite.modulate = Color.RED * 1.5
	
	apply_poison_effect(duration, power)

func apply_freeze_effect(duration: float):
	var original_speed = speed
	speed = 0
	
	# Effet visuel gel
	if sprite:
		sprite.modulate = Color.LIGHT_BLUE * 1.5
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		if sprite:
			sprite.modulate = Color.WHITE
		timer.queue_free()
	)
	timer.start()
