# Player.gd mis à jour
extends BaseCharacter
class_name Player

var weapons: Array[ProjectileData] = []
var current_weapon: int = 0
var fire_timer: float = 0.0 

# Données du personnage pour les animations
var character_data: Dictionary = {}

func _ready():
	super._ready()
	add_to_group("players")
	
	# Configuration des collision layers pour le joueur
	collision_layer = 1  # Layer 1 pour le joueur
	collision_mask = 2   # Peut collider avec les ennemis (layer 2)
	
	# Récupérer les données du personnage sélectionné
	character_data = GlobalData.get_character_data(GlobalData.selected_character_id)
	
	# Ajouter les armes de base selon le personnage
	setup_character_weapons()
	
	# Configurer les animations spécifiques au personnage
	setup_character_animations()
	
	print("=== PLAYER READY ===")
	print("Player collision_layer: ", collision_layer)
	print("Player collision_mask: ", collision_mask)
	print("Player groups: ", get_groups())

func setup_character_weapons():
	# Armes de base selon le personnage sélectionné
	match GlobalData.selected_character_id:
		0: # Guerrier
			add_warrior_weapons()
		1: # Archer  
			add_archer_weapons()
		2: # Mage
			add_mage_weapons()
		_:
			add_basic_weapon()

func add_warrior_weapons():
	# Guerrier : Projectiles lourds et qui rebondissent
	var heavy_weapon = ProjectileData.new()
	heavy_weapon.projectile_name = "Marteau Lourd"
	heavy_weapon.damage = 25.0
	heavy_weapon.speed = 300.0
	heavy_weapon.fire_rate = 0.8
	heavy_weapon.lifetime = 4.0
	heavy_weapon.projectile_scene_path = "res://scenes/projectiles/HeavyProjectile.tscn"
	weapons.append(heavy_weapon)

func add_archer_weapons():
	# Archer : Projectiles rapides et perçants
	var rapid_weapon = ProjectileData.new()
	rapid_weapon.projectile_name = "Flèche Rapide"
	rapid_weapon.damage = 15.0
	rapid_weapon.speed = 600.0
	rapid_weapon.fire_rate = 0.2
	rapid_weapon.lifetime = 3.0
	rapid_weapon.projectile_scene_path = "res://scenes/projectiles/ArrowProjectile.tscn"
	weapons.append(rapid_weapon)

func add_mage_weapons():
	# Mage : Projectiles magiques avec effets
	var magic_weapon = ProjectileData.new()
	magic_weapon.projectile_name = "Boule de Feu"
	magic_weapon.damage = 20.0
	magic_weapon.speed = 400.0
	magic_weapon.fire_rate = 0.5
	magic_weapon.lifetime = 5.0
	magic_weapon.projectile_scene_path = "res://scenes/projectiles/MagicProjectile.tscn"
	weapons.append(magic_weapon)

func add_basic_weapon():
	var basic_weapon = ProjectileData.new()
	basic_weapon.projectile_name = "Tir Basique"
	basic_weapon.damage = 10.0
	basic_weapon.speed = 500.0
	basic_weapon.fire_rate = 0.3
	basic_weapon.lifetime = 5.0
	basic_weapon.projectile_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
	weapons.append(basic_weapon)

func setup_character_animations():
	if not animation_player:
		return
	
	# Selon le personnage sélectionné, configurer différentes animations
	match GlobalData.selected_character_id:
		0: # Guerrier
			setup_warrior_animations()
		1: # Archer  
			setup_archer_animations()
		2: # Mage
			setup_mage_animations()

func setup_warrior_animations():
	if animation_player.has_animation("walk"):
		animation_player.speed_scale = 0.8  # Plus lent
	print("Warrior animations configured")

func setup_archer_animations():
	if animation_player.has_animation("walk"):
		animation_player.speed_scale = 1.2  # Plus rapide
	print("Archer animations configured")

func setup_mage_animations():
	if animation_player.has_animation("walk"):
		animation_player.speed_scale = 1.0  # Normal
	print("Mage animations configured")

func _physics_process(delta):
	handle_movement()
	handle_shooting(delta)
	handle_weapon_switch()
	update_sprite_direction()

func handle_movement():
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1
	
	# Gestion directe du changement d'arme
	if Input.is_action_pressed("weapon_1") and weapons.size() > 0:
		current_weapon = 0
	if Input.is_action_pressed("weapon_2") and weapons.size() > 1:
		current_weapon = 1
	if Input.is_action_pressed("weapon_3") and weapons.size() > 2:
		current_weapon = 2
	if Input.is_action_pressed("weapon_4") and weapons.size() > 3:
		current_weapon = 3
	if Input.is_action_pressed("weapon_5") and weapons.size() > 4:
		current_weapon = 4
	
	input_direction = input_direction.normalized()
	velocity = input_direction * speed
	move_and_slide()

func handle_shooting(delta):
	fire_timer += delta
	
	if weapons.size() == 0:
		return
	
	var current_fire_rate = weapons[current_weapon].fire_rate
	
	if (Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_timer >= current_fire_rate:
		fire_projectile()
		fire_timer = 0.0

func fire_projectile():
	var weapon = weapons[current_weapon]
	var mouse_pos = get_global_mouse_position()
	
	# Charger la scène du projectile
	if not ResourceLoader.exists(weapon.projectile_scene_path):
		print("ERROR: Projectile scene not found: ", weapon.projectile_scene_path)
		return
	
	var projectile_scene = load(weapon.projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	# Configurer le projectile
	projectile.set_owner_type("player")
	projectile.setup(weapon.damage, weapon.speed, weapon.lifetime)
	
	# Type de projectile selon l'arme et le personnage
	match GlobalData.selected_character_id:
		0: # Guerrier
			configure_warrior_projectile(projectile, weapon)
		1: # Archer
			configure_archer_projectile(projectile, weapon)
		2: # Mage
			configure_mage_projectile(projectile, weapon)
	
	# Lancer le projectile
	var spawn_offset = (mouse_pos - global_position).normalized() * 30
	projectile.launch(global_position + spawn_offset, mouse_pos)

func configure_warrior_projectile(projectile, weapon):
	match weapon.projectile_name:
		"Marteau Lourd":
			projectile.set_projectile_type("bounce")
			# Ajouter effet de ralentissement
			projectile.add_status_effect("slow", 2.0, 0.5)

func configure_archer_projectile(projectile, weapon):
	match weapon.projectile_name:
		"Flèche Rapide":
			projectile.set_projectile_type("basic")
			# Projectile perçant
			projectile.max_pierces = 2
			projectile.pierces_remaining = 2

func configure_mage_projectile(projectile, weapon):
	match weapon.projectile_name:
		"Boule de Feu":
			projectile.set_projectile_type("basic")
			# Ajouter effet de brûlure
			projectile.add_status_effect("burn", 3.0, 5.0)

func handle_weapon_switch():
	# Flèche haut pour cycler
	if Input.is_action_just_pressed("ui_up") and weapons.size() > 1:
		current_weapon = (current_weapon + 1) % weapons.size()
		print("Switched to: ", weapons[current_weapon].projectile_name)

func pickup_weapon(weapon_data: ProjectileData):
	for weapon in weapons:
		if weapon.projectile_name == weapon_data.projectile_name:
			return false
	
	weapons.append(weapon_data)
	print("Added weapon: ", weapon_data.projectile_name)
	return true

# Méthode pour appliquer les effets de statut
func apply_status_effect(effect_type: String, duration: float, power: float):
	print("Player affected by: ", effect_type, " for ", duration, "s")
	
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
	
	# Timer pour restaurer la vitesse
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		timer.queue_free()
		print("Slow effect ended")
	)
	timer.start()

func apply_poison_effect(duration: float, power: float):
	var poison_timer = Timer.new()
	add_child(poison_timer)
	poison_timer.wait_time = 0.5  # Dégâts toutes les 0.5s
	poison_timer.timeout.connect(func(): 
		take_damage(power)
		print("Poison damage: ", power)
	)
	poison_timer.start()
	
	# Timer pour arrêter le poison
	var end_timer = Timer.new()
	add_child(end_timer)
	end_timer.wait_time = duration
	end_timer.one_shot = true
	end_timer.timeout.connect(func():
		poison_timer.queue_free()
		end_timer.queue_free()
		print("Poison effect ended")
	)
	end_timer.start()

func apply_burn_effect(duration: float, power: float):
	# Similaire au poison mais avec effet visuel différent
	apply_poison_effect(duration, power)
	# TODO: Ajouter effet visuel de feu

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
		print("Freeze effect ended")
	)
	timer.start()
