# Player.gd - Version complète et simple
extends BaseCharacter
class_name Player

var weapons: Array[ProjectileData] = []
var current_weapon: int = 0
var fire_timer: float = 0.0 

# Variables de respawn
var is_dead: bool = false
var respawn_time: float = 3.0
var is_invulnerable: bool = false

# Données du personnage
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
	if is_dead:
		return
		
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
	
	# Changement d'arme direct
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
	
	# SIMPLE : Selon le nom de l'arme
	if weapon.projectile_name == "Foudre":
		fire_lightning()
	else:
		fire_normal_projectile(weapon, mouse_pos)

func fire_lightning():
	print("⚡ FIRING LIGHTNING!")
	
	# Créer la foudre directement
	var lightning_scene = load("res://scenes/projectiles/Lightning_projectile.tscn")
	var lightning = lightning_scene.instantiate()
	
	get_tree().current_scene.add_child(lightning)
	
	# Configuration simple
	lightning.owner_type = "player"
	lightning.damage = weapons[current_weapon].damage
	lightning.global_position = global_position
	
	print("⚡ Lightning created at player position: ", global_position)

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

# OVERRIDE take_damage pour gérer l'invulnérabilité
func take_damage(amount: float):
	if is_dead or is_invulnerable:
		print("🛡️ Damage blocked (dead or invulnerable)")
		return
	
	super.take_damage(amount)

# OVERRIDE die pour le respawn
func die():
	if is_dead:
		return
	
	is_dead = true
	print("💀 Player died! Respawning in ", respawn_time, " seconds...")
	
	# Arrêter les mouvements
	velocity = Vector2.ZERO
	visible = false
	collision_layer = 0
	
	# Effet de mort simple
	create_death_effect()
	
	# Timer de respawn
	var respawn_timer = Timer.new()
	add_child(respawn_timer)
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)
	respawn_timer.start()
	
	# UI de respawn simple
	show_death_message()

func _on_respawn():
	print("✨ Player respawning!")
	
	# Réinitialiser
	is_dead = false
	visible = true
	collision_layer = 1
	
	# Vie complète
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	# Position sûre
	global_position = get_viewport().get_visible_rect().size / 2
	
	# Invulnérabilité temporaire
	is_invulnerable = true
	var invul_timer = Timer.new()
	add_child(invul_timer)
	invul_timer.wait_time = 2.0
	invul_timer.one_shot = true
	invul_timer.timeout.connect(func(): 
		is_invulnerable = false
		modulate = Color.WHITE
		invul_timer.queue_free()
	)
	invul_timer.start()
	
	# Clignotement
	var blink_tween = create_tween()
	blink_tween.set_loops()
	blink_tween.tween_property(self, "modulate:a", 0.5, 0.2)
	blink_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	invul_timer.timeout.connect(func(): blink_tween.kill())
	
	hide_death_message()

func create_death_effect():
	# Effet simple de mort
	for i in range(5):
		var particle = Sprite2D.new()
		get_tree().current_scene.add_child(particle)
		
		var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
		image.fill(Color.RED)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		particle.texture = texture
		particle.global_position = global_position
		
		var direction = Vector2(cos(i * PI * 2 / 5), sin(i * PI * 2 / 5))
		var end_pos = global_position + direction * 50
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "global_position", end_pos, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): particle.queue_free())

var death_message: Label = null

func show_death_message():
	death_message = Label.new()
	death_message.text = "💀 MORT! Respawn dans " + str(int(respawn_time)) + "s..."
	death_message.position = Vector2(400, 300)
	death_message.add_theme_font_size_override("font_size", 24)
	death_message.add_theme_color_override("font_color", Color.RED)
	get_tree().current_scene.add_child(death_message)

func hide_death_message():
	if death_message and is_instance_valid(death_message):
		death_message.queue_free()
		death_message = null

# Méthodes pour les effets de statut (garder existantes)
func apply_status_effect(effect_type: String, duration: float, power: float):
	if is_dead:
		return
		
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
