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
	var damage_reduction = get_meta("damage_reduction", 0.0)
	var final_damage = amount * (1.0 - damage_reduction)
	
	# Appliquer les dégâts
	super.take_damage(final_damage)
	
	# Vol de vie
	var lifesteal = get_meta("lifesteal", 0.0)
	if lifesteal > 0:
		var heal_amount = final_damage * lifesteal
		heal(heal_amount)
		print("🧛 Lifesteal: +", heal_amount, " HP")

# === FONCTION POUR AFFICHER TES STATS ===
func get_player_stats_text() -> String:
	var crit_chance = get_meta("crit_chance", 0.0)
	var crit_multiplier = get_meta("crit_damage_multiplier", 1.5)
	var lifesteal = get_meta("lifesteal", 0.0)
	var fire_rate_boost = get_meta("fire_rate_boost", 0.0)
	var damage_reduction = get_meta("damage_reduction", 0.0)
	var extra_projectiles = get_meta("extra_projectiles", 0)
	var penetration = get_meta("penetration_bonus", 0)
	
	var stats = "=== STATS JOUEUR ===\n"
	stats += "Dégâts: " + str(int(damage)) + "\n"
	stats += "Vie: " + str(int(current_health)) + "/" + str(int(max_health)) + "\n"
	stats += "Vitesse: " + str(int(speed)) + "\n"
	
	if crit_chance > 0:
		stats += "Critique: " + str(int(crit_chance * 100)) + "% chance, x" + str(crit_multiplier) + " dégâts\n"
	if lifesteal > 0:
		stats += "Vol de vie: " + str(int(lifesteal * 100)) + "%\n"
	if fire_rate_boost > 0:
		stats += "Cadence: +" + str(int(fire_rate_boost * 100)) + "%\n"
	if damage_reduction > 0:
		stats += "Armure: " + str(int(damage_reduction * 100)) + "% résistance\n"
	if extra_projectiles > 0:
		stats += "Projectiles: +" + str(extra_projectiles) + "\n"
	if penetration > 0:
		stats += "Pénétration: +" + str(penetration) + "\n"
	
	return stats



# === APPLIQUER L'ARMURE ===
# Si tu veux que l'armure fonctionne, ajoute ça dans ta fonction take_damage:

	

# === MULTISHOT ET PÉNÉTRATION ===
# Pour utiliser ces buffs dans tes projectiles:
func get_multishot_count() -> int:
	return 1 + get_meta("extra_projectiles", 0)

func get_penetration_bonus() -> int:
	return get_meta("penetration_bonus", 0)
