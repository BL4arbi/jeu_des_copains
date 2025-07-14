# BuffSystem.gd - Buffs permanents avec effets de statut (ÉTENDU)
extends Node
class_name BuffSystem

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

# Base de données des buffs PERMANENTS étendue
var buff_database: Dictionary = {
	# Buffs classiques
	BuffType.DAMAGE_BOOST: {
		"name": "Force Permanente",
		"description": "+10 dégâts permanents",
		"icon": "💪",
		"value": 10.0
	},
	BuffType.HEALTH_BOOST: {
		"name": "Vitalité Permanente", 
		"description": "+50 HP max permanents",
		"icon": "❤️",
		"value": 50.0
	},
	BuffType.SPEED_BOOST: {
		"name": "Vitesse Permanente",
		"description": "+30 vitesse permanente",
		"icon": "⚡",
		"value": 30.0
	},
	BuffType.FIRE_RATE_BOOST: {
		"name": "Cadence Permanente",
		"description": "+20% cadence permanente",
		"icon": "🔫",
		"value": 0.2
	},
	BuffType.ARMOR_BOOST: {
		"name": "Armure Permanente",
		"description": "+15% résistance permanente",
		"icon": "🛡️",
		"value": 0.15
	},
	BuffType.LIFESTEAL: {
		"name": "Vol de Vie Permanent",
		"description": "+10% vol de vie permanent",
		"icon": "🧛",
		"value": 0.1
	},
	BuffType.MULTISHOT: {
		"name": "Tir Multiple Permanent",
		"description": "+1 projectile permanent",
		"icon": "🎯",
		"value": 1
	},
	BuffType.PENETRATION: {
		"name": "Perforation Permanente",
		"description": "+1 perforation permanente",
		"icon": "🏹",
		"value": 1
	},
	
	# Nouveaux buffs d'effets de statut
	BuffType.POISON_BULLETS: {
		"name": "Balles Empoisonnées",
		"description": "Balles infligent poison (3 dmg/sec, +3 par stack)",
		"icon": "☠️",
		"value": 1.0,
		"effect_type": "poison",
		"effect_duration": 4.0,
		"effect_power": 3.0  # Réduit pour équilibrer les stacks
	},
	BuffType.FIRE_BULLETS: {
		"name": "Balles Incendiaires",
		"description": "Balles infligent brûlure (4 dmg/sec, +4 par stack)",
		"icon": "🔥",
		"value": 1.0,
		"effect_type": "fire",
		"effect_duration": 3.0,
		"effect_power": 4.0  # Réduit pour équilibrer les stacks
	},
	BuffType.FREEZE_BULLETS: {
		"name": "Balles Glaciales",
		"description": "Balles gèlent les ennemis (2s immobilisation)",
		"icon": "🧊",
		"value": 1.0,
		"effect_type": "freeze",
		"effect_duration": 2.0,
		"effect_power": 1.0
	},
	BuffType.SLOW_BULLETS: {
		"name": "Balles Ralentissantes",
		"description": "Balles ralentissent de 25% par stack (max 5)",
		"icon": "🐌",
		"value": 1.0,
		"effect_type": "slow",
		"effect_duration": 5.0,
		"effect_power": 0.25  # 25% par stack
	},
	BuffType.EXPLOSIVE_BULLETS: {
		"name": "Balles Explosives",
		"description": "Balles explosent et repoussent les ennemis",
		"icon": "💥",
		"value": 1.0,
		"effect_type": "explosive",
		"effect_duration": 0.5,
		"effect_power": 50.0
	},
	BuffType.ELECTRIC_BULLETS: {
		"name": "Balles Électriques",
		"description": "Balles électrocutent (6 dmg/sec, +6 par stack)",
		"icon": "⚡",
		"value": 1.0,
		"effect_type": "electric",
		"effect_duration": 2.5,
		"effect_power": 6.0
	},
	BuffType.BLEEDING_BULLETS: {
		"name": "Balles Hémorragiques",
		"description": "Balles causent saignement (2 dmg/sec, +2 par stack)",
		"icon": "🩸",
		"value": 1.0,
		"effect_type": "bleeding",
		"effect_duration": 6.0,
		"effect_power": 2.0
	},
	BuffType.CURSE_BULLETS: {
		"name": "Balles Maudites",
		"description": "Balles maudissent: +25% dégâts reçus par stack",
		"icon": "🌙",
		"value": 1.0,
		"effect_type": "curse",
		"effect_duration": 4.0,
		"effect_power": 0.25
	}is",
		"icon": "💥",
		"value": 1.0,
		"effect_type": "explosive",
		"effect_duration": 0.5,
		"effect_power": 50.0
	},
	BuffType.ELECTRIC_BULLETS: {
		"name": "Balles Électriques",
		"description": "Balles électrocutent (6 dmg/sec, +6 par stack)",
		"icon": "⚡",
		"value": 1.0,
		"effect_type": "electric",
		"effect_duration": 2.5,
		"effect_power": 6.0  # Réduit pour équilibrer les stacks
	},
	BuffType.BLEEDING_BULLETS: {
		"name": "Balles Hémorragiques",
		"description": "Balles causent saignement (2 dmg/sec, +2 par stack)",
		"icon": "🩸",
		"value": 1.0,
		"effect_type": "bleeding",
		"effect_duration": 6.0,
		"effect_power": 2.0  # Réduit pour équilibrer les stacks
	},
	BuffType.CURSE_BULLETS: {
		"name": "Balles Maudites",
		"description": "Balles maudissent: +25% dégâts reçus par stack",
		"icon": "🌙",
		"value": 1.0,
		"effect_type": "curse",
		"effect_duration": 4.0,
		"effect_power": 0.25  # 25% par stack
	}is",
		"icon": "💥",
		"value": 1.0,
		"effect_type": "explosive",
		"effect_duration": 0.5,
		"effect_power": 50.0  # Force de répulsion
	},
	BuffType.ELECTRIC_BULLETS: {
		"name": "Balles Électriques",
		"description": "Balles électrocutent et se propagent",
		"icon": "⚡",
		"value": 1.0,
		"effect_type": "electric",
		"effect_duration": 1.5,
		"effect_power": 15.0  # Dégâts électriques
	},
	BuffType.BLEEDING_BULLETS: {
		"name": "Balles Hémorragiques",
		"description": "Balles causent saignement (3 dmg/sec pendant 5s)",
		"icon": "🩸",
		"value": 1.0,
		"effect_type": "bleeding",
		"effect_duration": 5.0,
		"effect_power": 3.0
	},
	BuffType.CURSE_BULLETS: {
		"name": "Balles Maudites",
		"description": "Balles maudissent: +50% dégâts reçus pendant 3s",
		"icon": "🌙",
		"value": 1.0,
		"effect_type": "curse",
		"effect_duration": 3.0,
		"effect_power": 0.5  # +50% dégâts reçus
	}
}

# Tables de drops étendues
var buff_drop_tables: Dictionary = {
	"Grunt": {
		"drop_chance": 0.12,
		"buffs": [
			BuffType.DAMAGE_BOOST, BuffType.HEALTH_BOOST, BuffType.SPEED_BOOST,
			BuffType.POISON_BULLETS, BuffType.SLOW_BULLETS, BuffType.BLEEDING_BULLETS
		]
	},
	"Shooter": {
		"drop_chance": 0.18,
		"buffs": [
			BuffType.FIRE_RATE_BOOST, BuffType.ARMOR_BOOST, BuffType.LIFESTEAL,
			BuffType.FIRE_BULLETS, BuffType.FREEZE_BULLETS, BuffType.ELECTRIC_BULLETS
		]
	},
	"Elite": {
		"drop_chance": 0.3,
		"buffs": [
			BuffType.MULTISHOT, BuffType.PENETRATION, BuffType.LIFESTEAL, BuffType.ARMOR_BOOST,
			BuffType.EXPLOSIVE_BULLETS, BuffType.CURSE_BULLETS, BuffType.ELECTRIC_BULLETS
		]
	}
}

var player_ref: Player = null

func _ready():
	add_to_group("buff_system")
	player_ref = get_tree().get_first_node_in_group("players")
	print("⭐ Extended Buff system ready with status effects")

func _on_enemy_killed(enemy_type: String, enemy_position: Vector2):
	try_drop_buff(enemy_type, enemy_position)

func try_drop_buff(enemy_type: String, position: Vector2):
	if not buff_drop_tables.has(enemy_type):
		return
	
	var drop_data = buff_drop_tables[enemy_type]
	
	if randf() < drop_data.drop_chance:
		var buff_type = drop_data.buffs[randi() % drop_data.buffs.size()]
		create_simple_buff_pickup(buff_type, position)

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
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var color = get_buff_color(buff_type)
		image.fill(color)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture
	
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
	var glow_image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var glow_color = get_buff_color(buff_type)
	glow_color.a = 0.5
	glow_image.fill(glow_color)
	var glow_texture = ImageTexture.new()
	glow_texture.set_image(glow_image)
	glow.texture = glow_texture
	glow.position = Vector2(-40, -40)
	
	pickup.set_meta("buff_type", buff_type)
	pickup.set_meta("buff_data", buff_data)
	
	pickup.global_position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	
	get_tree().current_scene.add_child(pickup)
	
	await get_tree().process_frame
	pickup.body_entered.connect(func(body): _on_pickup_touched(pickup, body))
	
	var timer = Timer.new()
	pickup.add_child(timer)
	timer.wait_time = 20.0
	timer.one_shot = true
	timer.timeout.connect(pickup.queue_free)
	timer.start()
	
	print("⭐ Created ", buff_data.name, " at ", position)

func _on_pickup_touched(pickup: Area2D, body):
	if not body.is_in_group("players"):
		return
	
	var buff_type = pickup.get_meta("buff_type")
	var buff_data = pickup.get_meta("buff_data")
	
	print("✅ Player got permanent buff: ", buff_data.name)
	
	apply_permanent_buff(buff_type, buff_data)
	
	show_buff_notification(buff_data.name, buff_data.icon)
	create_pickup_effect(pickup.global_position)
	
	pickup.queue_free()

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
			print("💪 +", value, " damage permanent! Total: ", player_ref.damage)
		
		BuffType.HEALTH_BOOST:
			player_ref.max_health += value
			player_ref.current_health += value
			if player_ref.has_method("update_health_bar"):
				player_ref.update_health_bar()
			print("❤️ +", value, " HP permanent! Total: ", player_ref.max_health)
		
		BuffType.SPEED_BOOST:
			player_ref.speed += value
			if player_ref.has_method("update_base_speed"):
				player_ref.update_base_speed(value)
			print("⚡ +", value, " speed permanent! Total: ", player_ref.speed)
		
		BuffType.FIRE_RATE_BOOST:
			var current_boost = player_ref.get_meta("fire_rate_boost", 0.0)
			player_ref.set_meta("fire_rate_boost", current_boost + value)
			print("🔫 +", int(value*100), "% fire rate permanent!")
		
		BuffType.ARMOR_BOOST:
			var current_armor = player_ref.get_meta("damage_reduction", 0.0)
			player_ref.set_meta("damage_reduction", current_armor + value)
			print("🛡️ +", int(value*100), "% armor permanent!")
		
		BuffType.LIFESTEAL:
			var current_lifesteal = player_ref.get_meta("lifesteal", 0.0)
			player_ref.set_meta("lifesteal", current_lifesteal + value)
			print("🧛 +", int(value*100), "% lifesteal permanent!")
		
		BuffType.MULTISHOT:
			var current_multishot = player_ref.get_meta("extra_projectiles", 0)
			player_ref.set_meta("extra_projectiles", current_multishot + int(value))
			print("🎯 +", int(value), " projectile permanent!")
		
		BuffType.PENETRATION:
			var current_penetration = player_ref.get_meta("penetration_bonus", 0)
			player_ref.set_meta("penetration_bonus", current_penetration + int(value))
			print("🏹 +", int(value), " penetration permanent!")
		
		# Nouveaux buffs d'effets de statut
		BuffType.POISON_BULLETS:
			add_bullet_effect("poison", buff_data)
			print("☠️ Bullets now poison enemies! (Level ", get_effect_level("poison"), ")")
		
		BuffType.FIRE_BULLETS:
			add_bullet_effect("fire", buff_data)
			print("🔥 Bullets now burn enemies! (Level ", get_effect_level("fire"), ")")
		
		BuffType.FREEZE_BULLETS:
			add_bullet_effect("freeze", buff_data)
			print("🧊 Bullets now freeze enemies!")
		
		BuffType.SLOW_BULLETS:
			add_bullet_effect("slow", buff_data)
			print("🐌 Bullets now slow enemies! (Level ", get_effect_level("slow"), ")")
		
		BuffType.EXPLOSIVE_BULLETS:
			add_bullet_effect("explosive", buff_data)
			print("💥 Bullets now explode!")
		
		BuffType.ELECTRIC_BULLETS:
			add_bullet_effect("electric", buff_data)
			print("⚡ Bullets now electrocute enemies! (Level ", get_effect_level("electric"), ")")
		
		BuffType.BLEEDING_BULLETS:
			add_bullet_effect("bleeding", buff_data)
			print("🩸 Bullets now cause bleeding! (Level ", get_effect_level("bleeding"), ")")
		
		BuffType.CURSE_BULLETS:
			add_bullet_effect("curse", buff_data)
			print("🌙 Bullets now curse enemies! (Level ", get_effect_level("curse"), ")")

# Fonction utilitaire pour obtenir le niveau d'un effet
func get_effect_level(effect_type: String) -> int:
	if not player_ref.has_meta("bullet_effects"):
		return 0
	
	var bullet_effects = player_ref.get_meta("bullet_effects", {})
	if bullet_effects.has(effect_type):
		return bullet_effects[effect_type].stacks
	return 0

# Système d'effets de balles CUMULABLES
func add_bullet_effect(effect_type: String, buff_data: Dictionary):
	var bullet_effects = player_ref.get_meta("bullet_effects", {})
	
	# Si l'effet existe déjà, on cumule les dégâts
	if bullet_effects.has(effect_type):
		var existing = bullet_effects[effect_type]
		existing.power += buff_data.effect_power
		existing.stacks += 1
		# Augmenter légèrement la durée avec chaque stack
		existing.duration = max(existing.duration, buff_data.effect_duration + (existing.stacks * 0.5))
		print("🎯 Upgraded ", effect_type, " to level ", existing.stacks, " (", existing.power, " power)")
	else:
		# Nouvel effet
		bullet_effects[effect_type] = {
			"duration": buff_data.effect_duration,
			"power": buff_data.effect_power,
			"stacks": 1,
			"max_stacks": get_max_stacks_for_effect(effect_type)
		}
		print("🎯 Added new bullet effect: ", effect_type, " (", buff_data.effect_power, " power)")
	
	player_ref.set_meta("bullet_effects", bullet_effects)

# Fonction à appeler depuis le projectile quand il touche un ennemi
func apply_bullet_effects_to_enemy(enemy: BaseEnemy, projectile_owner: Player):
	if not projectile_owner.has_meta("bullet_effects"):
		return
	
	var bullet_effects = projectile_owner.get_meta("bullet_effects", {})
	
	for effect_type in bullet_effects.keys():
		var effect = bullet_effects[effect_type]
		
		# Limiter les stacks au maximum autorisé
		var current_stacks = min(effect.stacks, effect.max_stacks)
		var scaled_power = effect.power * (current_stacks / float(effect.max_stacks))
		
		match effect_type:
			"poison":
				enemy.apply_cumulative_status_effect("poison", effect.duration, scaled_power, current_stacks)
			"fire":
				enemy.apply_cumulative_status_effect("fire", effect.duration, scaled_power, current_stacks)
			"freeze":
				enemy.apply_status_effect("freeze", effect.duration)
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

# Effets spéciaux personnalisés
func apply_explosive_effect(enemy: BaseEnemy, force: float):
	# Répulsion
	var direction = (enemy.global_position - player_ref.global_position).normalized()
	enemy.velocity += direction * force
	
	# Dégâts de zone
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for nearby in nearby_enemies:
		if nearby != enemy and nearby.global_position.distance_to(enemy.global_position) < 100:
			nearby.take_damage(player_ref.damage * 0.5)

func apply_electric_effect(enemy: BaseEnemy, duration: float, power: float):
	enemy.apply_status_effect("electric", duration, power)
	
	# Propagation électrique
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for nearby in nearby_enemies:
		if nearby != enemy and nearby.global_position.distance_to(enemy.global_position) < 80:
			nearby.apply_status_effect("electric", duration * 0.5, power * 0.7)

func apply_curse_effect(enemy: BaseEnemy, duration: float, power: float):
	# Malédiction = augmente les dégâts reçus
	var current_curse = enemy.get_meta("curse_multiplier", 1.0)
	enemy.set_meta("curse_multiplier", current_curse + power)
	
	# Timer pour retirer la malédiction
	var timer = Timer.new()
	enemy.add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		enemy.set_meta("curse_multiplier", current_curse)
		timer.queue_free()
	)
	timer.start()

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
	
	var image = Image.create(60, 60, false, Image.FORMAT_RGBA8)
	image.fill(Color.GOLD)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position
	
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(effect.queue_free)

func force_drop_buff(position: Vector2):
	var buff_type = randi() % BuffType.size()
	create_simple_buff_pickup(buff_type, position)
	print("🧪 Force dropped buff at: ", position)
