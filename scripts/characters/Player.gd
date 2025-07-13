# Player.gd - Version complète corrigée sans tweens
extends BaseCharacter
class_name Player

var weapons: Array[ProjectileData] = []
var current_weapon: int = 0
var fire_timer: float = 0.0 
signal weapon_replacement_requested(new_weapon: ProjectileData)

# Variables de respawn
var is_dead: bool = false
var respawn_time: float = 3.0
var is_invulnerable: bool = false

# Stats de base pour les buffs
var base_damage: float = 20.0
var base_speed: float = 200.0

func _ready():
	super._ready()
	add_to_group("players")
	
	collision_layer = 1
	collision_mask = 2
	
	# Sauvegarder les stats de base
	base_damage = damage
	base_speed = speed
	
	setup_character_weapons()
	setup_character_animations()
	
	print("=== PLAYER READY ===")

func setup_character_weapons():
	var basic_weapon = ProjectileData.new()
	basic_weapon.projectile_name = "Tir Basique"
	basic_weapon.damage = 15.0
	basic_weapon.speed = 500.0
	basic_weapon.fire_rate = 0.3
	basic_weapon.lifetime = 5.0
	basic_weapon.projectile_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
	weapons.append(basic_weapon)

func setup_character_animations():
	if animation_player and animation_player.has_animation("walk"):
		animation_player.speed_scale = 1.0

func _physics_process(delta):
	if is_dead:
		return
		
	handle_movement()
	handle_shooting(delta)
	handle_weapon_switch()

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
	for i in range(5):
		if Input.is_action_just_pressed("weapon_" + str(i + 1)) and weapons.size() > i:
			current_weapon = i
	
	input_direction = input_direction.normalized()
	velocity = input_direction * speed
	move_and_slide()

func handle_shooting(delta):
	fire_timer += delta
	
	if weapons.size() == 0:
		return
	
	var weapon = weapons[current_weapon]
	var effective_fire_rate = get_effective_fire_rate(weapon.fire_rate)
	
	if (Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_timer >= effective_fire_rate:
		fire_weapon()
		fire_timer = 0.0

func get_effective_fire_rate(base_fire_rate: float) -> float:
	var fire_rate_boost = get_meta("fire_rate_boost", 0.0)
	return base_fire_rate * (1.0 - fire_rate_boost)

func get_effective_damage(base_weapon_damage: float) -> float:
	var damage_boost = get_meta("damage_boost", 0.0)
	var total_damage = (damage + base_weapon_damage) * (1.0 + damage_boost)
	return total_damage

func fire_weapon():
	var weapon = weapons[current_weapon]
	var mouse_pos = get_global_mouse_position()
	
	# Tir principal
	fire_projectile(weapon, mouse_pos)
	
	# === MULTISHOT : PROJECTILES SUPPLÉMENTAIRES ===
	var extra_projectiles = get_meta("extra_projectiles", 0)
	if extra_projectiles > 0:
		var base_direction = (mouse_pos - global_position).normalized()
		var spread_angle = PI / 8  # 22.5 degrés de chaque côté
		
		for i in range(extra_projectiles):
			var angle_offset = spread_angle * (i + 1)
			if i % 2 == 1:
				angle_offset *= -1  # Alterner les côtés
			
			var direction = base_direction.rotated(angle_offset)
			var target_pos = global_position + direction * 500
			
			fire_projectile(weapon, target_pos)
	
	# === EFFETS DE BUFFS SPÉCIAUX ===
	# Chain Lightning
	var chain_chance = get_meta("chain_lightning_chance", 0.0)
	if chain_chance > 0 and randf() < chain_chance:
		fire_chain_lightning()

func fire_projectile(weapon: ProjectileData, target_pos: Vector2):
	if weapon.projectile_name == "Foudre":
		fire_lightning_special()
		return
	
	if not ResourceLoader.exists(weapon.projectile_scene_path):
		print("ERROR: Projectile scene not found: ", weapon.projectile_scene_path)
		return
	
	var projectile_scene = load(weapon.projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	# Configuration de base
	projectile.set_owner_type("player")
	
	# === CORRECTION HOMING : Configuration spéciale pour "Tir Chercheur" ===
	if weapon.projectile_name == "Tir Chercheur":
		projectile.set_projectile_type("homing")
		print("🎯 Configured homing projectile!")
	
	# Configuration selon les propriétés spéciales
	if weapon.special_properties.has("homing"):
		projectile.set_projectile_type("homing")
		projectile.homing_strength = weapon.special_properties.homing
		print("🎯 Homing configured with strength: ", projectile.homing_strength)
	
	if weapon.special_properties.has("piercing"):
		projectile.pierces_remaining = weapon.special_properties.piercing
		projectile.max_pierces = weapon.special_properties.piercing
		print("🏹 Piercing configured: ", projectile.pierces_remaining)
	
	# === APPLIQUER LES BUFFS AU PROJECTILE ===
	var final_damage = get_effective_damage(weapon.damage)
	var final_speed = weapon.speed
	var final_lifetime = weapon.lifetime
	
	# Penetration
	var penetration = get_meta("penetration_bonus", 0)
	if penetration > 0:
		projectile.pierces_remaining = max(projectile.pierces_remaining, penetration)
		projectile.max_pierces = max(projectile.max_pierces, penetration)
		print("🏹 Projectile with penetration: ", penetration)
	
	# Effets de statut selon les buffs actifs
	apply_status_effects_to_projectile(projectile)
	
	projectile.setup(final_damage, final_speed, final_lifetime)
	
	var spawn_offset = (target_pos - global_position).normalized() * 30
	projectile.launch(global_position + spawn_offset, target_pos)

func apply_status_effects_to_projectile(projectile):
	# Poison damage
	var poison_damage = get_meta("poison_damage", 0.0)
	if poison_damage > 0:
		projectile.add_status_effect("poison", 8.0, poison_damage)
		print("☠️ Projectile with poison: ", poison_damage, " DPS")
	
	# Fire damage (basé sur HP max)
	var fire_percent = get_meta("fire_damage_percent", 0.0)
	if fire_percent > 0:
		var fire_damage = max_health * fire_percent
		projectile.add_status_effect("burn", 6.0, fire_damage)
		print("🔥 Projectile with fire: ", fire_damage, " DPS")
	
	# Ice slow
	var ice_slow = get_meta("ice_slow_power", 0.0)
	if ice_slow > 0:
		projectile.add_status_effect("slow", 4.0, ice_slow)
		print("❄️ Projectile with ice slow: ", ice_slow)
	
	# Lightning stun
	var lightning_stun = get_meta("lightning_stun_duration", 0.0)
	if lightning_stun > 0:
		projectile.add_status_effect("freeze", lightning_stun, 1.0)
		print("⚡ Projectile with lightning stun: ", lightning_stun, "s")

func fire_chain_lightning():
	print("⚡ CHAIN LIGHTNING triggered!")
	
	var lightning_scene = load("res://scenes/projectiles/Lightning_projectile.tscn")
	if not lightning_scene:
		return
	
	var lightning = lightning_scene.instantiate()
	get_tree().current_scene.add_child(lightning)
	
	lightning.owner_type = "player"
	lightning.damage = damage * 0.6
	lightning.max_targets = 4
	lightning.global_position = global_position

func fire_lightning_special():
	print("⚡ FIRING SPECIAL LIGHTNING!")
	
	var lightning_scene = load("res://scenes/projectiles/Lightning_projectile.tscn")
	if not lightning_scene:
		return
	
	var lightning = lightning_scene.instantiate()
	get_tree().current_scene.add_child(lightning)
	
	lightning.owner_type = "player"
	lightning.damage = weapons[current_weapon].damage
	lightning.max_targets = 5
	lightning.global_position = global_position

func handle_weapon_switch():
	# Changement d'arme avec les touches 1-5
	for i in range(5):
		if Input.is_action_just_pressed("weapon_" + str(i + 1)) and weapons.size() > i:
			current_weapon = i
			print("Switched to: ", weapons[current_weapon].projectile_name)
	
	# Changement d'arme avec flèches
	if Input.is_action_just_pressed("drop"):
		drop_current_weapon()
	


# === FONCTION : Drop de l'arme actuelle ===
func drop_current_weapon():
	if weapons.size() <= 1:
		print("❌ Cannot drop weapon - need at least one weapon!")
		return
	
	if current_weapon < 0 or current_weapon >= weapons.size():
		print("❌ Invalid weapon index!")
		return
	
	var weapon_to_drop = weapons[current_weapon]
	print("🗑️ Dropping weapon: ", weapon_to_drop.projectile_name)
	
	# Créer le pickup de l'arme
	create_weapon_pickup_from_data(weapon_to_drop)
	
	# Supprimer l'arme de l'inventaire
	weapons.remove_at(current_weapon)
	
	# Ajuster l'index de l'arme actuelle
	if current_weapon >= weapons.size():
		current_weapon = weapons.size() - 1
	
	# Effet visuel de drop simple (sans tween)
	create_weapon_drop_effect()
	
	print("✅ Weapon dropped! Current weapon: ", weapons[current_weapon].projectile_name)

func create_weapon_pickup_from_data(weapon_data: ProjectileData):
	# Créer un pickup de l'arme droppée
	var pickup_scene = preload("res://scenes/ui/weapon_pickup.tscn")
	var pickup = pickup_scene.instantiate()
	
	# Configuration du pickup avec les données de l'arme
	pickup.weapon_name = weapon_data.projectile_name
	pickup.damage = weapon_data.damage
	pickup.speed = weapon_data.speed
	pickup.fire_rate = weapon_data.fire_rate
	pickup.projectile_scene_path = weapon_data.projectile_scene_path
	pickup.weapon_description = weapon_data.description
	
	# Déterminer la rareté
	pickup.weapon_rarity = determine_weapon_rarity(weapon_data.projectile_name)
	
	# Copier les propriétés spéciales si elles existent
	if weapon_data.special_properties:
		pickup.special_properties = weapon_data.special_properties.duplicate()
	
	# Position de drop (devant le joueur)
	var drop_direction = last_direction if last_direction != Vector2.ZERO else Vector2.RIGHT
	var drop_position = global_position + drop_direction * 80
	pickup.global_position = drop_position
	
	# Ajouter à la scène
	get_tree().current_scene.add_child(pickup)
	
	print("💎 Weapon pickup created at: ", drop_position)

func determine_weapon_rarity(weapon_name: String) -> String:
	match weapon_name:
		"Tir Basique", "Tir Rapide", "Canon Lourd":
			return "common"
		"Tir Perçant", "Flèche Fork", "Tir Chercheur":
			return "rare"
		"Chakram", "Foudre", "Pluie de Météores":
			return "epic"
		"Laser Rotatif", "Nova Stellaire":
			return "legendary"
		"Apocalypse", "Singularité":
			return "mythic"
		_:
			return "common"

func create_weapon_drop_effect():
	# Effet visuel simple sans tween
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var effect_size = 32
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.8, 1.0, 0.7))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = global_position
	
	# Timer simple pour supprimer l'effet
	var timer = Timer.new()
	effect.add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): effect.queue_free())
	timer.start()

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

# === OVERRIDE take_damage POUR LES BUFFS DÉFENSIFS ===
func take_damage(amount: float):
	if is_dead or is_invulnerable:
		print("🛡️ Damage blocked (dead or invulnerable)")
		return
	
	# Appliquer la réduction de dégâts (armor buff)
	var damage_reduction = get_meta("damage_reduction", 0.0)
	var final_damage = amount * (1.0 - damage_reduction)
	
	if damage_reduction > 0:
		print("🛡️ Damage reduced from ", amount, " to ", final_damage, " (", int(damage_reduction*100), "% reduction)")
	
	super.take_damage(final_damage)

# === MÉTHODE POUR APPLIQUER LE LIFESTEAL ===
func apply_lifesteal_on_damage(damage_dealt: float):
	var lifesteal = get_meta("lifesteal", 0.0)
	if lifesteal > 0:
		var heal_amount = damage_dealt * lifesteal
		heal(heal_amount)
		show_lifesteal_effect(heal_amount)

func show_lifesteal_effect(heal_amount: float):
	var heal_label = Label.new()
	heal_label.text = "+" + str(int(heal_amount))
	heal_label.add_theme_color_override("font_color", Color.GREEN)
	heal_label.add_theme_font_size_override("font_size", 16)
	heal_label.position = global_position + Vector2(randf_range(-30, 30), -40)
	
	get_tree().current_scene.add_child(heal_label)
	
	# Timer simple pour supprimer le label
	var timer = Timer.new()
	heal_label.add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): heal_label.queue_free())
	timer.start()

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
	
	create_death_effect()
	
	# Timer de respawn
	var respawn_timer = Timer.new()
	add_child(respawn_timer)
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)
	respawn_timer.start()
	
	show_death_message()

func _on_respawn():
	print("✨ Player respawning!")
	
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
	
	hide_death_message()

func create_death_effect():
	for i in range(5):
		var particle = Sprite2D.new()
		get_tree().current_scene.add_child(particle)
		
		var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
		image.fill(Color.RED)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		particle.texture = texture
		particle.global_position = global_position
		
		# Timer simple pour supprimer les particules
		var timer = Timer.new()
		particle.add_child(timer)
		timer.wait_time = 1.0
		timer.one_shot = true
		timer.timeout.connect(func(): particle.queue_free())
		timer.start()

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

# Méthodes pour les effets de statut existantes
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
