# Player.gd - Corrections pour Chakram et projectiles spéciaux
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
	
	collision_layer = 1
	collision_mask = 2
	
	character_data = GlobalData.get_character_data(GlobalData.selected_character_id)
	setup_character_weapons()
	setup_character_animations()
	
	print("=== PLAYER READY ===")

func setup_character_weapons():
	match GlobalData.selected_character_id:
		0: add_warrior_weapons()
		1: add_archer_weapons()
		2: add_mage_weapons()
		_: add_basic_weapon()

func add_warrior_weapons():
	var heavy_weapon = ProjectileData.new()
	heavy_weapon.projectile_name = "Marteau Lourd"
	heavy_weapon.damage = 25.0
	heavy_weapon.speed = 300.0
	heavy_weapon.fire_rate = 0.8
	heavy_weapon.lifetime = 4.0
	heavy_weapon.projectile_scene_path = "res://scenes/projectiles/HeavyProjectile.tscn"
	weapons.append(heavy_weapon)

func add_archer_weapons():
	var rapid_weapon = ProjectileData.new()
	rapid_weapon.projectile_name = "Flèche Rapide"
	rapid_weapon.damage = 15.0
	rapid_weapon.speed = 600.0
	rapid_weapon.fire_rate = 0.2
	rapid_weapon.lifetime = 3.0
	rapid_weapon.projectile_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
	weapons.append(rapid_weapon)

func add_mage_weapons():
	var magic_weapon = ProjectileData.new()
	magic_weapon.projectile_name = "Boule de Feu"
	magic_weapon.damage = 20.0
	magic_weapon.speed = 400.0
	magic_weapon.fire_rate = 0.5
	magic_weapon.lifetime = 5.0
	magic_weapon.projectile_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
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
	
	match GlobalData.selected_character_id:
		0: setup_warrior_animations()
		1: setup_archer_animations()
		2: setup_mage_animations()

func setup_warrior_animations():
	if animation_player.has_animation("walk"):
		animation_player.speed_scale = 0.8

func setup_archer_animations():
	if animation_player.has_animation("walk"):
		animation_player.speed_scale = 1.2

func setup_mage_animations():
	if animation_player.has_animation("walk"):
		animation_player.speed_scale = 1.0

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
	
	# CORRECTION : Gestion spéciale pour certains projectiles
	match weapon.projectile_name:
		"Chakram":
			fire_chakram_projectile(weapon, mouse_pos)
		"Tir Chercheur":
			fire_homing_projectile(weapon, mouse_pos)
		"Foudre":
			fire_lightning_projectile(weapon, mouse_pos)
		"Pluie de Météores":
			fire_meteor_projectile(weapon, mouse_pos)
		_:
			fire_normal_projectile(weapon, mouse_pos)

func fire_normal_projectile(weapon: ProjectileData, target_pos: Vector2):
	if not ResourceLoader.exists(weapon.projectile_scene_path):
		print("ERROR: Projectile scene not found: ", weapon.projectile_scene_path)
		return
	
	var projectile_scene = load(weapon.projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.set_owner_type("player")
	projectile.setup(weapon.damage, weapon.speed, weapon.lifetime)
	
	var spawn_offset = (target_pos - global_position).normalized() * 30
	projectile.launch(global_position + spawn_offset, target_pos)

func fire_chakram_projectile(weapon: ProjectileData, target_pos: Vector2):
	# CORRECTION : Utiliser ChakramProjectile si disponible, sinon BasicProjectile
	var projectile_path = "res://scenes/projectiles/ChakramProjectile.tscn"
	if not ResourceLoader.exists(projectile_path):
		projectile_path = "res://scenes/projectiles/BasicProjectile.tscn"
	
	var projectile_scene = load(projectile_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.set_owner_type("player")
	projectile.setup(weapon.damage, weapon.speed, weapon.lifetime)
	
	# Propriétés spéciales du Chakram
	if projectile.has_method("set_projectile_type"):
		projectile.set_projectile_type("bounce")
		projectile.max_bounces = 3
		projectile.bounces_remaining = 3
	
	var spawn_offset = (target_pos - global_position).normalized() * 30
	projectile.launch(global_position + spawn_offset, target_pos)
	
	print("🪃 Chakram fired!")

func fire_homing_projectile(weapon: ProjectileData, target_pos: Vector2):
	var projectile_scene = load("res://scenes/projectiles/BasicProjectile.tscn")
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.set_owner_type("player")
	projectile.setup(weapon.damage, weapon.speed, weapon.lifetime)
	
	# CORRECTION : Configurer le homing
	if projectile.has_method("set_projectile_type"):
		projectile.set_projectile_type("homing")
		projectile.homing_strength = 3.0
	
	var spawn_offset = (target_pos - global_position).normalized() * 30
	projectile.launch(global_position + spawn_offset, target_pos)
	
	print("🎯 Homing projectile fired!")

func fire_lightning_projectile(weapon: ProjectileData, target_pos: Vector2):
	var projectile_path = "res://scenes/projectiles/Lightning_projectile.tscn"
	if not ResourceLoader.exists(projectile_path):
		fire_normal_projectile(weapon, target_pos)
		return
	
	var projectile_scene = load(projectile_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	# CORRECTION : Gestion sécurisée
	if projectile.has_method("set_owner_type"):
		projectile.set_owner_type("player")
	else:
		projectile.owner_type = "player"
	
	if projectile.has_method("setup"):
		projectile.setup(weapon.damage, weapon.speed, weapon.lifetime)
	
	# CORRECTION : Position du joueur au lieu de la souris
	# Le Lightning cherchera automatiquement les ennemis autour du joueur
	projectile.global_position = global_position
	
	# OPTIONNEL : Configurer le nombre de cibles selon l'arme
	if projectile.has_method("set_target_count"):
		var target_count = 3  # Par défaut
		# Tu peux varier selon l'arme ou les upgrades
		if weapon.projectile_name == "Foudre":
			target_count = 3
		elif weapon.projectile_name == "Foudre Améliorée":
			target_count = 5
		
		projectile.set_target_count(target_count)
	
	

func fire_meteor_projectile(weapon: ProjectileData, target_pos: Vector2):
	var projectile_path = "res://scenes/projectiles/Meteor_projectile.tscn"
	if not ResourceLoader.exists(projectile_path):
		fire_normal_projectile(weapon, target_pos)
		return
	
	var projectile_scene = load(projectile_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.set_owner_type("player")
	projectile.setup(weapon.damage, weapon.speed, weapon.lifetime)
	projectile.global_position = target_pos
	
	print("☄️ Meteor projectile fired!")

func handle_weapon_switch():
	if Input.is_action_just_pressed("ui_up") and weapons.size() > 1:
		current_weapon = (current_weapon + 1) % weapons.size()
		print("Switched to: ", weapons[current_weapon].projectile_name)

func pickup_weapon(weapon_data: ProjectileData) -> bool:
	# Vérifier si on a déjà cette arme
	for weapon in weapons:
		if weapon.projectile_name == weapon_data.projectile_name:
			print("❌ Already have: ", weapon_data.projectile_name)
			return false
	
	# Vérifier si l'inventaire est plein (max 5 armes)
	if weapons.size() >= 5:
		print("❌ Inventory full!")
		return false
	
	weapons.append(weapon_data)
	print("✅ Added weapon: ", weapon_data.projectile_name)
	return true

# Méthodes pour les effets de statut (garder existantes)
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
	speed *= power
	
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
	poison_timer.wait_time = 0.5
	poison_timer.timeout.connect(func(): 
		take_damage(power)
		print("Poison damage: ", power)
	)
	poison_timer.start()
	
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
	apply_poison_effect(duration, power)

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
