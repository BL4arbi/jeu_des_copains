# EnemyDropSystem.gd - Système de drops d'armes
extends Node
class_name EnemyDropSystem

# Tables de drops par type d'ennemi
var drop_tables: Dictionary = {
	"Grunt": {
		"drop_chance": 0.15,  # 15% de chance
		"weapons": [
			{"name": "Tir Rapide", "weight": 40, "rarity": "common"},
			{"name": "Canon Lourd", "weight": 30, "rarity": "common"},
			{"name": "Tir Perçant", "weight": 20, "rarity": "common"},
			{"name": "Flèche Fork", "weight": 8, "rarity": "rare"},
			{"name": "Tir Chercheur", "weight": 2, "rarity": "rare"}
		]
	},
	"Shooter": {
		"drop_chance": 0.25,  # 25% de chance
		"weapons": [
			{"name": "Tir Rapide", "weight": 30, "rarity": "common"},
			{"name": "Tir Perçant", "weight": 25, "rarity": "common"},
			{"name": "Flèche Fork", "weight": 20, "rarity": "rare"},
			{"name": "Tir Chercheur", "weight": 15, "rarity": "rare"},
			{"name": "Chakram", "weight": 8, "rarity": "rare"},
			{"name": "Foudre", "weight": 2, "rarity": "epic"}
		]
	},
	"Elite": {
		"drop_chance": 0.75,  # 75% de chance - Elite sont précieux !
		"weapons": [
			{"name": "Tir Chercheur", "weight": 20, "rarity": "rare"},
			{"name": "Chakram", "weight": 20, "rarity": "rare"},
			{"name": "Flèche Fork", "weight": 15, "rarity": "rare"},
			{"name": "Foudre", "weight": 15, "rarity": "epic"},
			{"name": "Pluie de Météores", "weight": 12, "rarity": "epic"},
			{"name": "Laser Rotatif", "weight": 8, "rarity": "legendary"},
			{"name": "Nova Stellaire", "weight": 3, "rarity": "legendary"}
		]
	},
	"Boss": {
		"drop_chance": 1.0,  # 100% de chance - Boss garantissent un drop !
		"guaranteed_drops": 2,  # Nombre d'armes garanties
		"weapons": [
			{"name": "Foudre", "weight": 25, "rarity": "epic"},
			{"name": "Pluie de Météores", "weight": 25, "rarity": "epic"},
			{"name": "Laser Rotatif", "weight": 20, "rarity": "legendary"},
			{"name": "Nova Stellaire", "weight": 15, "rarity": "legendary"},
			{"name": "Apocalypse", "weight": 10, "rarity": "mythic"},
			{"name": "Singularité", "weight": 5, "rarity": "mythic"}
		]
	}
}

# Données complètes des armes
var weapon_database: Dictionary = {
	"Tir Rapide": {
		"damage": 8.0, "speed": 600.0, "fire_rate": 0.15,
		"scene_path": "res://scenes/projectiles/BasicProjectile.tscn",
		"description": "Projectiles rapides et fréquents"
	},
	"Canon Lourd": {
		"damage": 25.0, "speed": 300.0, "fire_rate": 0.8,
		"scene_path": "res://scenes/projectiles/BasicProjectile.tscn",
		"description": "Gros dégâts mais lent"
	},
	"Tir Perçant": {
		"damage": 12.0, "speed": 500.0, "fire_rate": 0.4,
		"scene_path": "res://scenes/projectiles/BasicProjectile.tscn",
		"description": "Traverse plusieurs ennemis",
		"special_properties": {"piercing": 2}
	},
	"Flèche Fork": {
		"damage": 15.0, "speed": 400.0, "fire_rate": 1.0,
		"scene_path": "res://scenes/projectiles/ForkArrowProjectile.tscn",
		"description": "Se divise en plusieurs projectiles à l'impact"
	},
	"Tir Chercheur": {
		"damage": 18.0, "speed": 350.0, "fire_rate": 0.7,
		"scene_path": "res://scenes/projectiles/BasicProjectile.tscn",
		"description": "Suit automatiquement les ennemis",
		"special_properties": {"homing": 3.0}
	},
	"Chakram": {
		"damage": 20.0, "speed": 300.0, "fire_rate": 2.0,
		"scene_path": "res://scenes/projectiles/ChakramProjectile.tscn",
		"description": "Rebondit entre ennemis et revient"
	},
	"Foudre": {
		"damage": 30.0, "speed": 0.0, "fire_rate": 3.0,
		"scene_path": "res://scenes/projectiles/LightningProjectile.tscn",
		"description": "Frappe plusieurs ennemis avec des éclairs"
	},
	"Pluie de Météores": {
		"damage": 35.0, "speed": 200.0, "fire_rate": 4.0,
		"scene_path": "res://scenes/projectiles/MeteorProjectile.tscn",
		"description": "Fait tomber des météores explosifs"
	},
	"Laser Rotatif": {
		"damage": 40.0, "speed": 800.0, "fire_rate": 5.0,
		"scene_path": "res://scenes/projectiles/LaserProjectile.tscn",
		"description": "Laser surpuissant à rotation automatique"
	},
	"Nova Stellaire": {
		"damage": 50.0, "speed": 0.0, "fire_rate": 8.0,
		"scene_path": "res://scenes/projectiles/NovaProjectile.tscn",
		"description": "Explosion stellaire qui détruit tout"
	},
	"Apocalypse": {
		"damage": 75.0, "speed": 400.0, "fire_rate": 10.0,
		"scene_path": "res://scenes/projectiles/ApocalypseProjectile.tscn",
		"description": "L'arme ultime de destruction massive"
	},
	"Singularité": {
		"damage": 100.0, "speed": 100.0, "fire_rate": 15.0,
		"scene_path": "res://scenes/projectiles/SingularityProjectile.tscn",
		"description": "Crée un trou noir qui aspire les ennemis"
	}
}

# Variables de progression
var total_kills: int = 0
var elite_kills: int = 0
var boss_kills: int = 0

# Modificateurs de chance selon la progression
var luck_multiplier: float = 1.0
var elite_spawn_threshold: int = 25  # Elite commencent à apparaître après 25 kills

func _ready():
	# Connecter aux signaux de mort des ennemis
	if GlobalData.has_signal("enemy_killed"):
		GlobalData.enemy_killed.connect(_on_enemy_killed) 
	

func _on_enemy_killed(enemy_type: String, enemy_position: Vector2):
	total_kills += 1
	
	match enemy_type:
		"Elite":
			elite_kills += 1
		"Boss":
			boss_kills += 1
	
	# Calculer et exécuter le drop
	try_drop_weapon(enemy_type, enemy_position)
	
	# Progression de la chance
	update_luck_progression()

func try_drop_weapon(enemy_type: String, position: Vector2):
	if not drop_tables.has(enemy_type):
		print("No drop table for enemy type: ", enemy_type)
		return
	
	var drop_data = drop_tables[enemy_type]
	var base_chance = drop_data.drop_chance
	var final_chance = base_chance * luck_multiplier
	
	# Bonus de chance selon le type
	match enemy_type:
		"Elite":
			final_chance *= 1.2  # +20% pour Elite
		"Boss":
			final_chance = 1.0   # 100% pour Boss
	
	print("Drop chance for ", enemy_type, ": ", final_chance * 100, "%")
	
	# Boss ont des drops garantis multiples
	if enemy_type == "Boss":
		var guaranteed_count = drop_data.get("guaranteed_drops", 1)
		for i in range(guaranteed_count):
			drop_weapon_at_position(enemy_type, position, i * 0.3)  # Délai entre drops
	else:
		# Drop normal avec chance
		if randf() < final_chance:
			drop_weapon_at_position(enemy_type, position)

func drop_weapon_at_position(enemy_type: String, position: Vector2, delay: float = 0.0):
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	var drop_data = drop_tables[enemy_type]
	var weapon_name = choose_weapon_from_table(drop_data.weapons)
	
	if weapon_name == "":
		return
	
	var weapon_info = weapon_database[weapon_name]
	create_weapon_pickup(weapon_name, weapon_info, position)

func choose_weapon_from_table(weapons: Array) -> String:
	# Filtrer les armes selon les unlocks
	var available_weapons = []
	var total_weight = 0
	
	for weapon in weapons:
		if is_weapon_unlocked(weapon.name):
			available_weapons.append(weapon)
			total_weight += weapon.weight
	
	if available_weapons.is_empty():
		return ""
	
	# Sélection pondérée
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for weapon in available_weapons:
		current_weight += weapon.weight
		if random_value <= current_weight:
			return weapon.name
	
	return available_weapons[0].name

func is_weapon_unlocked(weapon_name: String) -> bool:
	# Conditions de déblocage selon la progression
	match weapon_name:
		"Laser Rotatif":
			return elite_kills >= 5  # 5 Elite tués
		"Nova Stellaire":
			return total_kills >= 100  # 100 kills total
		"Apocalypse":
			return boss_kills >= 1  # 1 Boss tué
		"Singularité":
			return boss_kills >= 3 and elite_kills >= 20  # 3 Boss + 20 Elite
		_:
			return true  # Autres armes toujours disponibles

func create_weapon_pickup(weapon_name: String, weapon_info: Dictionary, position: Vector2):
	# Créer le pickup d'arme
	var pickup_scene = preload("res://scenes/ui/weapon_pickup.tscn")
	var pickup = pickup_scene.instantiate()
	
	# Configuration du pickup
	pickup.weapon_name = weapon_name
	pickup.damage = weapon_info.damage
	pickup.speed = weapon_info.speed
	pickup.fire_rate = weapon_info.fire_rate
	pickup.projectile_scene_path = weapon_info.scene_path
	pickup.weapon_description = weapon_info.description
	pickup.weapon_rarity = determine_rarity(weapon_name)
	
	if weapon_info.has("special_properties"):
		pickup.special_properties = weapon_info.special_properties
	
	# Position avec léger décalage aléatoire
	var random_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
	pickup.global_position = position + random_offset
	
	get_tree().current_scene.add_child(pickup)
	
	# Effet visuel de drop
	create_drop_effect(position, determine_rarity(weapon_name))
	
	print("💎 ", weapon_name, " dropped by enemy at ", position)

func determine_rarity(weapon_name: String) -> String:
	# Déterminer la rareté selon l'arme
	match weapon_name:
		"Tir Rapide", "Canon Lourd", "Tir Perçant":
			return "common"
		"Flèche Fork", "Tir Chercheur", "Chakram":
			return "rare"
		"Foudre", "Pluie de Météores":
			return "epic"
		"Laser Rotatif", "Nova Stellaire":
			return "legendary"
		"Apocalypse", "Singularité":
			return "mythic"
		_:
			return "common"

func create_drop_effect(position: Vector2, rarity: String):
	# Effet visuel selon la rareté
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var effect_color: Color
	match rarity:
		"common": effect_color = Color.WHITE
		"rare": effect_color = Color.CYAN
		"epic": effect_color = Color.PURPLE
		"legendary": effect_color = Color.GOLD
		"mythic": effect_color = Color.RED
		_: effect_color = Color.WHITE
	
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(effect_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position
	
	# Animation d'explosion vers le haut
	var tween = create_tween()
	tween.parallel().tween_property(effect, "position:y", position.y - 50, 1.0)
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.5)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): 
		if is_instance_valid(effect):
			effect.call_deferred("queue_free")  
	)

func update_luck_progression():
	# Augmenter la chance selon la progression
	var base_luck = 1.0
	
	# Bonus selon les kills totaux
	base_luck += total_kills * 0.002  # +0.2% par kill
	
	# Bonus selon les Elite tués
	base_luck += elite_kills * 0.05   # +5% par Elite
	
	# Bonus selon les Boss tués
	base_luck += boss_kills * 0.2     # +20% par Boss
	
	luck_multiplier = min(base_luck, 3.0)  # Max 300%
	
	print("Luck multiplier updated: ", luck_multiplier, "x (", int((luck_multiplier - 1.0) * 100), "% bonus)")

# Méthodes pour événements spéciaux
func trigger_elite_kill_bonus():
	# Bonus temporaire après avoir tué un Elite
	var original_luck = luck_multiplier
	luck_multiplier *= 2.0  # Double chance pendant 30s
	
	print("🌟 Elite kill bonus! Double drop chance for 30s")
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 30.0
	timer.one_shot = true
	timer.timeout.connect(func():
		luck_multiplier = original_luck
		timer.queue_free()
		print("Elite bonus ended")
	)
	timer.start()

func force_rare_drop(enemy_type: String, position: Vector2):
	# Forcer un drop rare (pour événements spéciaux)
	var rare_weapons = ["Foudre", "Pluie de Météores", "Chakram"]
	var weapon_name = rare_weapons[randi() % rare_weapons.size()]
	var weapon_info = weapon_database[weapon_name]
	
	create_weapon_pickup(weapon_name, weapon_info, position)
	print("🎉 Forced rare drop: ", weapon_name)

# Statistiques pour le joueur
func get_drop_statistics() -> Dictionary:
	return {
		"total_kills": total_kills,
		"elite_kills": elite_kills,
		"boss_kills": boss_kills,
		"luck_multiplier": luck_multiplier,
		"unlocked_weapons": get_unlocked_weapons_count()
	}

func get_unlocked_weapons_count() -> int:
	var count = 0
	for weapon_name in weapon_database.keys():
		if is_weapon_unlocked(weapon_name):
			count += 1
	return count
