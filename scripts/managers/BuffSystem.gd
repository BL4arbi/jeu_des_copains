# BuffSystem.gd - Buffs permanents avec effets de statut (CORRIGE + OPTIMISE)
extends Node

# Types de buffs permanents (anciens + nouveaux)
enum BuffType {
	# Buffs classiques
	DAMAGE_BOOST,
	HEALTH_BOOST,
	SPEED_BOOST,
	FIRE_RATE_BOOST,
	ARMOR_BOOST,
	LIFESTEAL,
	MULTISHOT,
	PENETRATION,
	
	# Buffs critiques
	CRIT_CHANCE,
	CRIT_DAMAGE,
	
	# Nouveaux buffs d'effets de statut
	POISON_BULLETS,
	FIRE_BULLETS,
	FREEZE_BULLETS,
	SLOW_BULLETS,
	EXPLOSIVE_BULLETS,
	ELECTRIC_BULLETS,
	BLEEDING_BULLETS,
	CURSE_BULLETS
}

# OPTIMISATION: Cache de textures pour éviter les créations répétées
var texture_cache: Dictionary = {}

# Base de donnees des buffs PERMANENTS etendue
var buff_database: Dictionary = {
	# Buffs classiques
	BuffType.DAMAGE_BOOST: {
		"name": "Force Permanente",
		"description": "+10 degats permanents",
		"icon": "[DMG]",
		"value": 10.0
	},
	BuffType.HEALTH_BOOST: {
		"name": "Vitalite Permanente", 
		"description": "+50 HP max permanents",
		"icon": "[HP]",
		"value": 50.0
	},
	BuffType.SPEED_BOOST: {
		"name": "Vitesse Permanente",
		"description": "+30 vitesse permanente",
		"icon": "[SPEED]",
		"value": 30.0
	},
	BuffType.FIRE_RATE_BOOST: {
		"name": "Cadence Permanente",
		"description": "+20% cadence permanente",
		"icon": "[RATE]",
		"value": 0.2
	},
	BuffType.ARMOR_BOOST: {
		"name": "Armure Permanente",
		"description": "+15% resistance permanente",
		"icon": "[ARMOR]",
		"value": 0.15
	},
	BuffType.LIFESTEAL: {
		"name": "Vol de Vie Permanent",
		"description": "+10% vol de vie permanent",
		"icon": "[STEAL]",
		"value": 0.1
	},
	BuffType.MULTISHOT: {
		"name": "Tir Multiple Permanent",
		"description": "+1 projectile permanent",
		"icon": "[MULTI]",
		"value": 1
	},
	BuffType.PENETRATION: {
		"name": "Perforation Permanente",
		"description": "+1 perforation permanente",
		"icon": "[PEN]",
		"value": 1
	},
	
	# Buffs critiques
	BuffType.CRIT_CHANCE: {
		"name": "Chance Critique",
		"description": "+15% chance de critique permanente",
		"icon": "[CRIT%]",
		"value": 0.15
	},
	BuffType.CRIT_DAMAGE: {
		"name": "Degats Critiques",
		"description": "+50% degats critiques permanents",
		"icon": "[CRIT+]",
		"value": 0.5
	},
	
	# Nouveaux buffs d'effets de statut
	BuffType.POISON_BULLETS: {
		"name": "Balles Empoisonnees",
		"description": "Balles infligent poison (3 dmg/sec, +3 par stack)",
		"icon": "[POISON]",
		"value": 1.0,
		"effect_type": "poison",
		"effect_duration": 4.0,
		"effect_power": 3.0
	},
	BuffType.FIRE_BULLETS: {
		"name": "Balles Incendiaires",
		"description": "Balles infligent brulure (4 dmg/sec, +4 par stack)",
		"icon": "[FIRE]",
		"value": 1.0,
		"effect_type": "fire",
		"effect_duration": 3.0,
		"effect_power": 4.0
	},
	BuffType.FREEZE_BULLETS: {
		"name": "Balles Glaciales",
		"description": "Balles gelent les ennemis (2s immobilisation)",
		"icon": "[ICE]",
		"value": 1.0,
		"effect_type": "freeze",
		"effect_duration": 2.0,
		"effect_power": 1.0
	},
	BuffType.SLOW_BULLETS: {
		"name": "Balles Ralentissantes",
		"description": "Balles ralentissent de 25% par stack (max 5)",
		"icon": "[SLOW]",
		"value": 1.0,
		"effect_type": "slow",
		"effect_duration": 5.0,
		"effect_power": 0.25
	},
	BuffType.EXPLOSIVE_BULLETS: {
		"name": "Balles Explosives",
		"description": "Balles explosent et repoussent les ennemis",
		"icon": "[BOOM]",
		"value": 1.0,
		"effect_type": "explosive",
		"effect_duration": 0.5,
		"effect_power": 50.0
	},
	BuffType.ELECTRIC_BULLETS: {
		"name": "Balles Electriques",
		"description": "Balles electrocutent (6 dmg/sec, +6 par stack)",
		"icon": "[ZAP]",
		"value": 1.0,
		"effect_type": "electric",
		"effect_duration": 2.5,
		"effect_power": 6.0
	},
	BuffType.BLEEDING_BULLETS: {
		"name": "Balles Hemorragiques",
		"description": "Balles causent saignement (2 dmg/sec, +2 par stack)",
		"icon": "[BLEED]",
		"value": 1.0,
		"effect_type": "bleeding",
		"effect_duration": 6.0,
		"effect_power": 2.0
	},
	BuffType.CURSE_BULLETS: {
		"name": "Balles Maudites",
		"description": "Balles maudissent: +25% degats recus par stack",
		"icon": "[CURSE]",
		"value": 1.0,
		"effect_type": "curse",
		"effect_duration": 4.0,
		"effect_power": 0.25
	}
}

# Tables de drops etendues
var buff_drop_tables: Dictionary = {
	"Grunt": {
		"drop_chance": 0.12,
		"buffs": [
			BuffType.DAMAGE_BOOST, BuffType.HEALTH_BOOST, BuffType.SPEED_BOOST,
			BuffType.POISON_BULLETS, BuffType.SLOW_BULLETS, BuffType.BLEEDING_BULLETS,
			BuffType.CRIT_CHANCE
		]
	},
	"Shooter": {
		"drop_chance": 0.18,
		"buffs": [
			BuffType.FIRE_RATE_BOOST, BuffType.ARMOR_BOOST, BuffType.LIFESTEAL,
			BuffType.FIRE_BULLETS, BuffType.FREEZE_BULLETS, BuffType.ELECTRIC_BULLETS,
			BuffType.CRIT_DAMAGE
		]
	},
	"Elite": {
		"drop_chance": 0.3,
		"buffs": [
			BuffType.MULTISHOT, BuffType.PENETRATION, BuffType.LIFESTEAL, BuffType.ARMOR_BOOST,
			BuffType.EXPLOSIVE_BULLETS, BuffType.CURSE_BULLETS, BuffType.ELECTRIC_BULLETS,
			BuffType.CRIT_CHANCE, BuffType.CRIT_DAMAGE
		]
	}
}

var player_ref: Player = null

func _ready():
	add_to_group("buff_system")
	player_ref = get_tree().get_first_node_in_group("players")
	print(">>> Extended Buff system ready with status effects")

func _on_enemy_killed(enemy_type: String, enemy_position: Vector2):
	try_drop_buff(enemy_type, enemy_position)

func try_drop_buff(enemy_type: String, position: Vector2):
	if not buff_drop_tables.has(enemy_type):
		return
	
	var drop_data = buff_drop_tables[enemy_type]
	
	if randf() < drop_data.drop_chance:
		var buff_type = drop_data.buffs[randi() % drop_data.buffs.size()]
		create_simple_buff_pickup(buff_type, position)

# OPTIMISATION: Cache de textures pour éviter les créations répétées
func get_cached_texture(color: Color, size: int = 32) -> ImageTexture:
	var cache_key = str(color) + "_" + str(size)
	
	if not texture_cache.has(cache_key):
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(color)
		var texture = ImageTexture.new()
		texture.set_image(image)
		texture_cache[cache_key] = texture
	
	return texture_cache[cache_key]

func create_simple_buff_pickup(buff_type: int, position: Vector2):
	var pickup = Area2D.new()
	pickup.name = "BuffPickup"
	
	pickup.collision_layer = 2
	pickup.collision_mask = 1
	pickup.monitoring = true
	pickup.monitorable = true
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60.0
	collision.shape = shape
	pickup.add_child(collision)
	
	var sprite = Sprite2D.new()
	pickup.add_child(sprite)
	
	var sprite_path = get_buff_sprite_path(buff_type)
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# OPTIMISATION: Utiliser le cache de textures au lieu de créer à chaque fois
		var color = get_buff_color(buff_type)
		sprite.texture = get_cached_texture(color, 32)
	
	sprite.scale = Vector2(3, 3)
	sprite.modulate = get_buff_color(buff_type)
	
	var label = Label.new()
	var buff_data = buff_database[buff_type]
	label.text = buff_data.icon + " " + buff_data.name
	label.position = Vector2(-100, -60)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.YELLOW)
	pickup.add_child(label)
	
	var glow = Sprite2D.new()
	pickup.add_child(glow)
	glow.z_index = -1
	
	# OPTIMISATION: Utiliser le cache pour le glow aussi
	var glow_color = get_buff_color(buff_type)
	glow_color.a = 0.5
	glow.texture = get_cached_texture(glow_color, 80)
	glow.position = Vector2(-40, -40)
	
	pickup.set_meta("buff_type", buff_type)
	pickup.set_meta("buff_data", buff_data)
	
	pickup.global_position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	
	# CORRECTION: Utiliser call_deferred pour éviter les conflits
	get_tree().current_scene.add_child.call_deferred(pickup)
	
	# CORRECTION: Attendre avant de connecter les signaux
	call_deferred("setup_pickup_signals", pickup)
	
	print(">>> Created ", buff_data.name, " at ", position)

# NOUVELLE FONCTION: Setup des signaux en différé
func setup_pickup_signals(pickup: Area2D):
	if is_instance_valid(pickup) and not pickup.body_entered.is_connected(_on_pickup_touched):
		pickup.body_entered.connect(func(body): _on_pickup_touched(pickup, body))
	
	# Timer de despawn
	var timer = Timer.new()
	pickup.add_child(timer)
	timer.wait_time = 20.0
	timer.one_shot = true
	timer.timeout.connect(pickup.queue_free)
	timer.start()

func _on_pickup_touched(pickup: Area2D, body):
	if not body.is_in_group("players"):
		return
	
	var buff_type = pickup.get_meta("buff_type")
	var buff_data = pickup.get_meta("buff_data")
	
	print(">>> Player got permanent buff: ", buff_data.name)
	
	apply_permanent_buff(buff_type, buff_data)
	
	show_buff_notification(buff_data.name, buff_data.icon)
	create_pickup_effect(pickup.global_position)
	
	pickup.queue_free()

# Systeme d'effets de balles CUMULABLES
func add_bullet_effect(effect_type: String, buff_data: Dictionary):
	var bullet_effects = player_ref.get_meta("bullet_effects", {})
	
	# Si l'effet existe deja, on cumule les degats
	if bullet_effects.has(effect_type):
		var existing = bullet_effects[effect_type]
		existing.power += buff_data.effect_power
		existing.stacks += 1
		# Augmenter legerement la duree avec chaque stack
		existing.duration = max(existing.duration, buff_data.effect_duration + (existing.stacks * 0.5))
		print(">>> Upgraded ", effect_type, " to level ", existing.stacks, " (", existing.power, " power)")
	else:
		# Nouvel effet
		bullet_effects[effect_type] = {
			"duration": buff_data.effect_duration,
			"power": buff_data.effect_power,
			"stacks": 1,
			"max_stacks": get_max_stacks_for_effect(effect_type)
		}
		print(">>> Added new bullet effect: ", effect_type, " (", buff_data.effect_power, " power)")
	
	player_ref.set_meta("bullet_effects", bullet_effects)

# Fonction a appeler depuis le projectile quand il touche un ennemi
func apply_bullet_effects_to_enemy(enemy: Node, projectile_owner: Player):
	if not projectile_owner.has_meta("bullet_effects"):
		return
	
	var bullet_effects = projectile_owner.get_meta("bullet_effects", {})
	
	for effect_type in bullet_effects.keys():
		var effect = bullet_effects[effect_type]
		
		# Limiter les stacks au maximum autorise
		var current_stacks = min(effect.stacks, effect.max_stacks)
		var scaled_power = effect.power * (current_stacks / float(effect.max_stacks))
		
		match effect_type:
			"poison":
				enemy.apply_cumulative_status_effect("poison", effect.duration, scaled_power, current_stacks)
			"fire":
				enemy.apply_cumulative_status_effect("fire", effect.duration, scaled_power, current_stacks)
			"freeze":
				enemy.apply_status_effect("freeze", effect.duration, 1.0)
			"slow":
				enemy.apply_cumulative_status_effect("slow", effect.duration, scaled_power, current_stacks)
			"explosive":
				apply_explosive_effect(enemy, scaled_power)
			"electric":
				enemy.apply_cumulative_status_effect("electric", effect.duration, scaled_power, current_stacks)
			"bleeding":
				enemy.apply_cumulative_status_effect("bleeding", effect.duration, scaled_power, current_stacks)
			"curse":
				apply_curse_effect(enemy, effect.duration, scaled_power)

# Definir le nombre maximum de stacks par effet
func get_max_stacks_for_effect(effect_type: String) -> int:
	match effect_type:
		"poison": return 10
		"fire": return 8
		"bleeding": return 12
		"electric": return 6
		"slow": return 5
		"curse": return 3
		_: return 5

# Effets speciaux personnalises
func apply_explosive_effect(enemy: Node, force: float):
	# Repulsion
	var direction = (enemy.global_position - player_ref.global_position).normalized()
	enemy.velocity += direction * force
	
	# Degats de zone
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for nearby in nearby_enemies:
		if nearby != enemy and nearby.global_position.distance_to(enemy.global_position) < 100:
			nearby.take_damage(player_ref.damage * 0.5)

func apply_electric_effect(enemy: Node, duration: float, power: float):
	enemy.apply_status_effect("electric", duration, power)
	
	# Propagation electrique
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for nearby in nearby_enemies:
		if nearby != enemy and nearby.global_position.distance_to(enemy.global_position) < 80:
			nearby.apply_status_effect("electric", duration * 0.5, power * 0.7)

func apply_curse_effect(enemy: Node, duration: float, power: float):
	# Malediction = augmente les degats recus
	var current_curse = enemy.get_meta("curse_multiplier", 1.0)
	enemy.set_meta("curse_multiplier", current_curse + power)
	
	# Timer pour retirer la malediction
	var timer = Timer.new()
	enemy.add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		enemy.set_meta("curse_multiplier", current_curse)
		timer.queue_free()
	)
	timer.start()

func apply_permanent_buff(buff_type: int, buff_data: Dictionary):
	if not player_ref:
		return
	
	var value = buff_data.value
	
	match buff_type:
		# Buffs classiques
		BuffType.DAMAGE_BOOST:
			player_ref.damage += value
			if player_ref.has_method("update_base_damage"):
				player_ref.update_base_damage(value)
			print("[DMG] +", value, " damage permanent! Total: ", player_ref.damage)
		
		BuffType.HEALTH_BOOST:
			player_ref.max_health += value
			player_ref.current_health += value
			if player_ref.has_method("update_health_bar"):
				player_ref.update_health_bar()
			print("[HP] +", value, " HP permanent! Total: ", player_ref.max_health)
		
		BuffType.SPEED_BOOST:
			player_ref.speed += value
			if player_ref.has_method("update_base_speed"):
				player_ref.update_base_speed(value)
			print("[SPEED] +", value, " speed permanent! Total: ", player_ref.speed)
		
		BuffType.FIRE_RATE_BOOST:
			var current_boost = player_ref.get_meta("fire_rate_boost", 0.0)
			player_ref.set_meta("fire_rate_boost", current_boost + value)
			print("[RATE] +", int(value*100), "% fire rate permanent!")
		
		BuffType.ARMOR_BOOST:
			var current_armor = player_ref.get_meta("damage_reduction", 0.0)
			player_ref.set_meta("damage_reduction", current_armor + value)
			print("[ARMOR] +", int(value*100), "% armor permanent!")
		
		BuffType.LIFESTEAL:
			var current_lifesteal = player_ref.get_meta("lifesteal", 0.0)
			player_ref.set_meta("lifesteal", current_lifesteal + value)
			print("[STEAL] +", int(value*100), "% lifesteal permanent!")
		
		BuffType.MULTISHOT:
			var current_multishot = player_ref.get_meta("extra_projectiles", 0)
			player_ref.set_meta("extra_projectiles", current_multishot + int(value))
			print("[MULTI] +", int(value), " projectile permanent!")
		
		BuffType.PENETRATION:
			var current_penetration = player_ref.get_meta("penetration_bonus", 0)
			player_ref.set_meta("penetration_bonus", current_penetration + int(value))
			print("[PEN] +", int(value), " penetration permanent!")
		
		# Buffs critiques
		BuffType.CRIT_CHANCE:
			var current_crit_chance = player_ref.get_meta("crit_chance", 0.0)
			player_ref.set_meta("crit_chance", current_crit_chance + value)
			print("[CRIT%] +", int(value*100), "% crit chance permanent! Total: ", int((current_crit_chance + value)*100), "%")
		
		BuffType.CRIT_DAMAGE:
			var current_crit_damage = player_ref.get_meta("crit_damage_multiplier", 1.5)
			player_ref.set_meta("crit_damage_multiplier", current_crit_damage + value)
			print("[CRIT+] +", int(value*100), "% crit damage permanent! Total: x", current_crit_damage + value)
		
		# Nouveaux buffs d'effets de statut
		BuffType.POISON_BULLETS:
			add_bullet_effect("poison", buff_data)
			print("[POISON] Bullets now poison enemies! (Level ", get_effect_level("poison"), ")")
		
		BuffType.FIRE_BULLETS:
			add_bullet_effect("fire", buff_data)
			print("[FIRE] Bullets now burn enemies! (Level ", get_effect_level("fire"), ")")
		
		BuffType.FREEZE_BULLETS:
			add_bullet_effect("freeze", buff_data)
			print("[ICE] Bullets now freeze enemies!")
		
		BuffType.SLOW_BULLETS:
			add_bullet_effect("slow", buff_data)
			print("[SLOW] Bullets now slow enemies! (Level ", get_effect_level("slow"), ")")
		
		BuffType.EXPLOSIVE_BULLETS:
			add_bullet_effect("explosive", buff_data)
			print("[BOOM] Bullets now explode!")
		
		BuffType.ELECTRIC_BULLETS:
			add_bullet_effect("electric", buff_data)
			print("[ZAP] Bullets now electrocute enemies! (Level ", get_effect_level("electric"), ")")
		
		BuffType.BLEEDING_BULLETS:
			add_bullet_effect("bleeding", buff_data)
			print("[BLEED] Bullets now cause bleeding! (Level ", get_effect_level("bleeding"), ")")
		
		BuffType.CURSE_BULLETS:
			add_bullet_effect("curse", buff_data)
			print("[CURSE] Bullets now curse enemies! (Level ", get_effect_level("curse"), ")")

# Fonction utilitaire pour obtenir le niveau d'un effet
func get_effect_level(effect_type: String) -> int:
	if not player_ref.has_meta("bullet_effects"):
		return 0
	
	var bullet_effects = player_ref.get_meta("bullet_effects", {})
	if bullet_effects.has(effect_type):
		return bullet_effects[effect_type].stacks
	return 0

func get_buff_sprite_path(buff_type: int) -> String:
	match buff_type:
		BuffType.DAMAGE_BOOST: return "res://assets/ui/damage_icon.png"
		BuffType.HEALTH_BOOST: return "res://assets/ui/health_icon.png"
		BuffType.SPEED_BOOST: return "res://assets/ui/speed_icon.png"
		BuffType.FIRE_RATE_BOOST: return "res://assets/ui/fire_rate_icon.png"
		BuffType.ARMOR_BOOST: return "res://assets/ui/armor_icon.png"
		BuffType.LIFESTEAL: return "res://assets/ui/lifesteal_icon.png"
		BuffType.MULTISHOT: return "res://assets/ui/multishot_icon.png"
		BuffType.PENETRATION: return "res://assets/ui/penetration_icon.png"
		BuffType.CRIT_CHANCE: return "res://assets/ui/crit_chance_icon.png"
		BuffType.CRIT_DAMAGE: return "res://assets/ui/crit_damage_icon.png"
		BuffType.POISON_BULLETS: return "res://assets/ui/poison_icon.png"
		BuffType.FIRE_BULLETS: return "res://assets/ui/fire_icon.png"
		BuffType.FREEZE_BULLETS: return "res://assets/ui/freeze_icon.png"
		BuffType.SLOW_BULLETS: return "res://assets/ui/slow_icon.png"
		BuffType.EXPLOSIVE_BULLETS: return "res://assets/ui/explosive_icon.png"
		BuffType.ELECTRIC_BULLETS: return "res://assets/ui/electric_icon.png"
		BuffType.BLEEDING_BULLETS: return "res://assets/ui/bleeding_icon.png"
		BuffType.CURSE_BULLETS: return "res://assets/ui/curse_icon.png"
		_: return "res://assets/ui/default_buff_icon.png"

func get_buff_color(buff_type: int) -> Color:
	match buff_type:
		BuffType.DAMAGE_BOOST: return Color.RED
		BuffType.HEALTH_BOOST: return Color.GREEN
		BuffType.SPEED_BOOST: return Color.YELLOW
		BuffType.FIRE_RATE_BOOST: return Color.ORANGE
		BuffType.ARMOR_BOOST: return Color.BLUE
		BuffType.LIFESTEAL: return Color.PURPLE
		BuffType.MULTISHOT: return Color.CYAN
		BuffType.PENETRATION: return Color.MAGENTA
		BuffType.CRIT_CHANCE: return Color.GOLD
		BuffType.CRIT_DAMAGE: return Color.CRIMSON
		BuffType.POISON_BULLETS: return Color.LIME_GREEN
		BuffType.FIRE_BULLETS: return Color.ORANGE_RED
		BuffType.FREEZE_BULLETS: return Color.LIGHT_BLUE
		BuffType.SLOW_BULLETS: return Color.GRAY
		BuffType.EXPLOSIVE_BULLETS: return Color.YELLOW
		BuffType.ELECTRIC_BULLETS: return Color.CYAN
		BuffType.BLEEDING_BULLETS: return Color.DARK_RED
		BuffType.CURSE_BULLETS: return Color.DARK_MAGENTA
		_: return Color.WHITE

func show_buff_notification(buff_name: String, icon: String):
	var notification = Label.new()
	notification.text = icon + " " + buff_name + " PERMANENT!"
	notification.position = Vector2(400, 100)
	notification.add_theme_font_size_override("font_size", 18)
	notification.add_theme_color_override("font_color", Color.GOLD)
	
	get_tree().current_scene.add_child(notification)
	
	var timer = Timer.new()
	notification.add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(notification.queue_free)
	timer.start()

func create_pickup_effect(position: Vector2):
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	# OPTIMISATION: Utiliser le cache pour l'effet aussi
	effect.texture = get_cached_texture(Color.GOLD, 60)
	effect.global_position = position
	
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(effect.queue_free)

func force_drop_buff(position: Vector2):
	var buff_type = randi() % BuffType.size()
	create_simple_buff_pickup(buff_type, position)
	print(">>> Force dropped buff at: ", position)
