# BuffSystem.gd - Système de buffs corrigé pour les pickups
extends Node
class_name BuffSystem

# Types de buffs disponibles
enum BuffType {
	DAMAGE_BOOST,      # +% dégâts
	HEALTH_REGEN,      # Régénération de vie
	SPEED_BOOST,       # +% vitesse
	FIRE_RATE_BOOST,   # +% cadence de tir
	ARMOR_BOOST,       # Réduction de dégâts
	LIFESTEAL,         # Vol de vie
	MULTISHOT,         # +1 projectile par tir
	CHAIN_LIGHTNING,   # Chaîne d'éclairs
	EXPLOSION_RADIUS,  # Rayon d'explosion
	PENETRATION,       # Perforation
	POISON_DAMAGE,     # Dégâts poison fixes
	FIRE_DAMAGE,       # Dégâts feu basés sur HP max
	ICE_SLOW,          # Ralentissement glacial
	LIGHTNING_STUN     # Étourdissement foudroyant
}

# Base de données des buffs avec icônes Unicode
var buff_database: Dictionary = {
	BuffType.DAMAGE_BOOST: {
		"name": "Rage de Combat",
		"description": "+25% de dégâts",
		"icon": "💪",
		"rarity": "common",
		"value": 0.25,
		"duration": 30.0
	},
	BuffType.HEALTH_REGEN: {
		"name": "Régénération",
		"description": "+3 HP par seconde",
		"icon": "❤️",
		"rarity": "common",
		"value": 3.0,
		"duration": 25.0
	},
	BuffType.SPEED_BOOST: {
		"name": "Vélocité",
		"description": "+35% de vitesse",
		"icon": "⚡",
		"rarity": "common",
		"value": 0.35,
		"duration": 20.0
	},
	BuffType.FIRE_RATE_BOOST: {
		"name": "Tir Rapide",
		"description": "+50% de cadence",
		"icon": "🔫",
		"rarity": "rare",
		"value": 0.5,
		"duration": 25.0
	},
	BuffType.ARMOR_BOOST: {
		"name": "Carapace",
		"description": "-30% de dégâts reçus",
		"icon": "🛡️",
		"rarity": "rare",
		"value": 0.3,
		"duration": 30.0
	},
	BuffType.LIFESTEAL: {
		"name": "Vampirisme",
		"description": "20% de vol de vie",
		"icon": "🧛",
		"rarity": "epic",
		"value": 0.2,
		"duration": 40.0
	},
	BuffType.MULTISHOT: {
		"name": "Tir Multiple",
		"description": "+1 projectile par tir",
		"icon": "🎯",
		"rarity": "epic",
		"value": 1,
		"duration": 35.0
	},
	BuffType.CHAIN_LIGHTNING: {
		"name": "Chaîne Foudroyante",
		"description": "30% chance éclairs",
		"icon": "⚡",
		"rarity": "legendary",
		"value": 0.3,
		"duration": 45.0
	},
	BuffType.EXPLOSION_RADIUS: {
		"name": "Explosions Massives",
		"description": "+60% rayon explosion",
		"icon": "💥",
		"rarity": "legendary",
		"value": 0.6,
		"duration": 40.0
	},
	BuffType.PENETRATION: {
		"name": "Perforant Ultime",
		"description": "Traverse 2 ennemis",
		"icon": "🏹",
		"rarity": "legendary",
		"value": 2,
		"duration": 30.0
	},
	BuffType.POISON_DAMAGE: {
		"name": "Toxines Mortelles",
		"description": "+5 DPS poison 8s",
		"icon": "☠️",
		"rarity": "rare",
		"value": 5.0,
		"duration": 30.0
	},
	BuffType.FIRE_DAMAGE: {
		"name": "Flammes Infernales",
		"description": "+3% HP max DPS feu 6s",
		"icon": "🔥",
		"rarity": "epic",
		"value": 0.03,
		"duration": 35.0
	},
	BuffType.ICE_SLOW: {
		"name": "Gel Arctique",
		"description": "Ralentit ennemis 4s",
		"icon": "❄️",
		"rarity": "rare",
		"value": 0.6,
		"duration": 25.0
	},
	BuffType.LIGHTNING_STUN: {
		"name": "Foudre Paralysante",
		"description": "Paralyse ennemis 2s",
		"icon": "⚡",
		"rarity": "epic",
		"value": 2.0,
		"duration": 30.0
	}
}

# Tables de drops par type d'ennemi
var buff_drop_tables: Dictionary = {
	"Grunt": {
		"drop_chance": 0.12,
		"buffs": [
			{"type": BuffType.DAMAGE_BOOST, "weight": 35},
			{"type": BuffType.HEALTH_REGEN, "weight": 30},
			{"type": BuffType.SPEED_BOOST, "weight": 25},
			{"type": BuffType.POISON_DAMAGE, "weight": 10}
		]
	},
	"Shooter": {
		"drop_chance": 0.18,
		"buffs": [
			{"type": BuffType.FIRE_RATE_BOOST, "weight": 25},
			{"type": BuffType.ARMOR_BOOST, "weight": 20},
			{"type": BuffType.ICE_SLOW, "weight": 20},
			{"type": BuffType.FIRE_DAMAGE, "weight": 15},
			{"type": BuffType.LIFESTEAL, "weight": 15},
			{"type": BuffType.PENETRATION, "weight": 5}
		]
	},
	"Elite": {
		"drop_chance": 0.45,
		"buffs": [
			{"type": BuffType.MULTISHOT, "weight": 20},
			{"type": BuffType.CHAIN_LIGHTNING, "weight": 18},
			{"type": BuffType.EXPLOSION_RADIUS, "weight": 15},
			{"type": BuffType.LIGHTNING_STUN, "weight": 15},
			{"type": BuffType.PENETRATION, "weight": 12},
			{"type": BuffType.LIFESTEAL, "weight": 12},
			{"type": BuffType.FIRE_DAMAGE, "weight": 8}
		]
	}
}

# Variables du système
var player_ref: Player = null
var active_buffs: Array = []
var total_kills: int = 0
var buff_pickups: Array = []

func _ready():
	add_to_group("buff_system")
	
	# Trouver le joueur
	player_ref = get_tree().get_first_node_in_group("players")
	
	# Timer pour update des buffs
	var buff_timer = Timer.new()
	add_child(buff_timer)
	buff_timer.wait_time = 1.0
	buff_timer.timeout.connect(_update_buffs)
	buff_timer.start()
	
	print("⭐ Buff system initialized")

func _on_enemy_killed(enemy_type: String, enemy_position: Vector2):
	total_kills += 1
	try_drop_buff(enemy_type, enemy_position)

func try_drop_buff(enemy_type: String, position: Vector2):
	if not buff_drop_tables.has(enemy_type):
		return
	
	var drop_data = buff_drop_tables[enemy_type]
	var base_chance = drop_data.drop_chance
	
	# Bonus de chance selon la progression
	var chance_multiplier = 1.0 + (total_kills * 0.002)
	var final_chance = base_chance * chance_multiplier
	
	if randf() < final_chance:
		var buff_type = choose_buff_from_table(drop_data.buffs)
		if buff_type != -1:
			call_deferred("create_buff_pickup_deferred", buff_type, position)

func choose_buff_from_table(buffs: Array) -> int:
	var total_weight = 0
	for buff in buffs:
		total_weight += buff.weight
	
	if total_weight == 0:
		return -1
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for buff in buffs:
		current_weight += buff.weight
		if random_value <= current_weight:
			return buff.type
	
	return buffs[0].type if buffs.size() > 0 else -1

func create_buff_pickup_deferred(buff_type: int, position: Vector2):
	var pickup = Area2D.new()
	pickup.name = "BuffPickup_" + str(buff_type)
	
	# COLLISION CORRIGÉE
	pickup.collision_layer = 0  # N'appartient à aucune layer
	pickup.collision_mask = 1   # Détecte seulement les joueurs (layer 1)
	
	# Configuration des données
	var buff_data = buff_database[buff_type]
	pickup.set_meta("buff_type", buff_type)
	pickup.set_meta("buff_data", buff_data)
	pickup.set_meta("despawn_timer", 12.0)
	
	# Collision shape CORRECT
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0  # Plus gros pour plus facile à ramasser
	collision.shape = shape
	pickup.add_child(collision)
	
	# Sprite avec icône
	var sprite = create_buff_sprite(buff_data)
	pickup.add_child(sprite)
	
	# Labels
	var name_label = Label.new()
	name_label.text = buff_data.name
	name_label.position = Vector2(-50, -50)
	name_label.add_theme_color_override("font_color", get_rarity_color(buff_data.rarity))
	name_label.add_theme_font_size_override("font_size", 12)
	pickup.add_child(name_label)
	
	var timer_label = Label.new()
	timer_label.position = Vector2(-15, -70)
	timer_label.add_theme_color_override("font_color", Color.YELLOW)
	timer_label.add_theme_font_size_override("font_size", 10)
	pickup.add_child(timer_label)
	pickup.set_meta("timer_label", timer_label)
	
	# Position avec décalage aléatoire
	var random_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
	pickup.global_position = position + random_offset
	
	# SIGNAL CORRECTION - Connecter APRÈS avoir ajouté à la scène
	get_tree().current_scene.add_child(pickup)
	
	# Maintenant connecter le signal
	if pickup.body_entered.connect(_on_buff_pickup.bind(pickup)) != OK:
		print("❌ Failed to connect buff pickup signal")
	else:
		print("✅ Buff pickup signal connected")
	
	# Ajouter à la liste de tracking
	buff_pickups.append(pickup)
	
	# Animation flottante
	create_floating_animation(pickup)
	
	print("⭐ ", buff_data.name, " buff dropped at ", position)

func create_buff_sprite(buff_data: Dictionary) -> Sprite2D:
	var sprite = Sprite2D.new()
	
	# Créer texture avec icône et couleur de rareté
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	var base_color = get_rarity_color(buff_data.rarity)
	
	# Cercle avec gradient
	for x in range(64):
		for y in range(64):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 28:
				var intensity = 1.0 - (distance / 28.0) * 0.4
				var alpha = 1.0 - (distance / 28.0) * 0.3
				var color = Color(
					base_color.r * intensity,
					base_color.g * intensity,
					base_color.b * intensity,
					alpha
				)
				image.set_pixel(x, y, color)
			elif distance <= 30:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.8))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(1.2, 1.2)
	
	# Label pour l'icône (superposé)
	var icon_label = Label.new()
	icon_label.text = buff_data.icon
	icon_label.position = Vector2(-12, -12)
	icon_label.add_theme_font_size_override("font_size", 24)
	sprite.add_child(icon_label)
	
	return sprite

func create_floating_animation(pickup: Area2D):
	if not is_instance_valid(pickup):
		return
	
	# Animation simple avec timer au lieu de tween
	var float_timer = Timer.new()
	pickup.add_child(float_timer)
	float_timer.wait_time = 0.1
	var start_y = pickup.position.y
	var time_offset = 0.0
	
	float_timer.timeout.connect(func():
		if is_instance_valid(pickup):
			time_offset += 0.1
			pickup.position.y = start_y + sin(time_offset * 2.0) * 5.0
	)
	float_timer.start()

func _process(delta):
	# Update des timers de pickups
	for i in range(buff_pickups.size() - 1, -1, -1):
		var pickup = buff_pickups[i]
		
		if not is_instance_valid(pickup):
			buff_pickups.erase(pickup)
			continue
		
		# Timer de despawn
		if pickup.has_meta("despawn_timer"):
			var timer = pickup.get_meta("despawn_timer") - delta
			pickup.set_meta("despawn_timer", timer)
			
			# Mettre à jour le label du timer
			var timer_label = pickup.get_meta("timer_label")
			if timer_label and is_instance_valid(timer_label):
				timer_label.text = str(int(timer)) + "s"
			
			# Despawn si temps écoulé
			if timer <= 0:
				buff_pickups.erase(pickup)
				pickup.queue_free()

func _on_buff_pickup(pickup: Area2D, body):
	print("🎯 Buff pickup collision detected with: ", body.name)
	
	if not body.is_in_group("players"):
		print("❌ Not a player: ", body.name)
		return
	
	print("✅ Player touched buff pickup!")
	
	var buff_type = pickup.get_meta("buff_type")
	var buff_data = pickup.get_meta("buff_data")
	
	# Appliquer le buff
	apply_buff_to_player(buff_type)
	
	# Effet de pickup
	create_pickup_effect(pickup.global_position, buff_data)
	
	# Retirer de la liste et détruire
	buff_pickups.erase(pickup)
	pickup.queue_free()

func apply_buff_to_player(buff_type: int):
	if not player_ref:
		print("❌ No player reference for buff application")
		return
	
	var buff_data = buff_database[buff_type].duplicate()
	buff_data["type"] = buff_type
	buff_data["remaining_time"] = buff_data.duration
	
	# Vérifier si le buff existe déjà
	for i in range(active_buffs.size()):
		if active_buffs[i].type == buff_type:
			active_buffs[i].remaining_time = buff_data.duration
			print("🔄 Buff renewed: ", buff_data.name)
			return
	
	# Ajouter le nouveau buff
	active_buffs.append(buff_data)
	apply_buff_effect(buff_type, buff_data.value, true)
	
	print("⭐ Buff applied: ", buff_data.name)
	show_buff_notification(buff_data)

func apply_buff_effect(buff_type: int, value: float, is_applying: bool):
	if not player_ref:
		return
	
	var multiplier = 1.0 if is_applying else -1.0
	
	match buff_type:
		BuffType.DAMAGE_BOOST:
			if is_applying:
				player_ref.set_meta("damage_boost", value)
			else:
				player_ref.remove_meta("damage_boost")
			
		BuffType.SPEED_BOOST:
			var boost = player_ref.base_speed * value * multiplier
			player_ref.speed += boost
			
		BuffType.ARMOR_BOOST:
			player_ref.set_meta("damage_reduction", value if is_applying else 0.0)
		
		BuffType.FIRE_RATE_BOOST:
			player_ref.set_meta("fire_rate_boost", value if is_applying else 0.0)
		
		BuffType.LIFESTEAL:
			player_ref.set_meta("lifesteal", value if is_applying else 0.0)
		
		BuffType.MULTISHOT:
			player_ref.set_meta("extra_projectiles", int(value) if is_applying else 0)
		
		BuffType.CHAIN_LIGHTNING:
			player_ref.set_meta("chain_lightning_chance", value if is_applying else 0.0)
		
		BuffType.EXPLOSION_RADIUS:
			player_ref.set_meta("explosion_radius_bonus", value if is_applying else 0.0)
		
		BuffType.PENETRATION:
			player_ref.set_meta("penetration_bonus", int(value) if is_applying else 0)
		
		BuffType.POISON_DAMAGE:
			player_ref.set_meta("poison_damage", value if is_applying else 0.0)
		
		BuffType.FIRE_DAMAGE:
			player_ref.set_meta("fire_damage_percent", value if is_applying else 0.0)
		
		BuffType.ICE_SLOW:
			player_ref.set_meta("ice_slow_power", value if is_applying else 0.0)
		
		BuffType.LIGHTNING_STUN:
			player_ref.set_meta("lightning_stun_duration", value if is_applying else 0.0)

func _update_buffs():
	if not player_ref:
		return
	
	# Update des buffs actifs
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		buff.remaining_time -= 1.0
		
		# Buffs qui s'activent en continu
		match buff.type:
			BuffType.HEALTH_REGEN:
				player_ref.heal(buff.value)
		
		# Supprimer les buffs expirés
		if buff.remaining_time <= 0:
			apply_buff_effect(buff.type, buff.value, false)
			active_buffs.remove_at(i)
			print("⏰ Buff expired: ", buff.name)

func show_buff_notification(buff_data: Dictionary):
	var notification = Label.new()
	notification.text = buff_data.icon + " " + buff_data.name + " activé!"
	notification.position = Vector2(400, 120)
	notification.add_theme_font_size_override("font_size", 18)
	notification.add_theme_color_override("font_color", get_rarity_color(buff_data.rarity))
	
	get_tree().current_scene.add_child(notification)
	
	# Animation avec timer
	var move_timer = Timer.new()
	notification.add_child(move_timer)
	move_timer.wait_time = 0.05
	var start_time = Time.get_ticks_msec()
	var start_pos = notification.position
	
	move_timer.timeout.connect(func():
		if not is_instance_valid(notification):
			return
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		if elapsed >= 2.5:
			notification.queue_free()
			return
		
		var progress = elapsed / 2.5
		notification.position.y = start_pos.y - (40 * progress)
		notification.modulate.a = 1.0 - progress
	)
	move_timer.start()

func create_pickup_effect(position: Vector2, buff_data: Dictionary):
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var effect_size = 32
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	var color = get_rarity_color(buff_data.rarity)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position
	
	# Animation avec timer
	var effect_timer = Timer.new()
	effect.add_child(effect_timer)
	effect_timer.wait_time = 0.05
	var start_time = Time.get_ticks_msec()
	
	effect_timer.timeout.connect(func():
		if not is_instance_valid(effect):
			return
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		if elapsed >= 0.6:
			effect.queue_free()
			return
		
		var progress = elapsed / 0.6
		var scale_value = 1.0 + (progress * 2.0)  # Scale de 1 à 3
		effect.scale = Vector2(scale_value, scale_value)
		effect.modulate.a = 1.0 - progress
	)
	effect_timer.start()

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"rare": return Color.CYAN
		"epic": return Color.PURPLE
		"legendary": return Color.GOLD
		_: return Color.WHITE

# Méthodes utilitaires
func get_active_buffs() -> Array:
	return active_buffs

func has_buff(buff_type: int) -> bool:
	for buff in active_buffs:
		if buff.type == buff_type:
			return true
	return false

# Debug
func force_drop_buff(position: Vector2):
	# Pour tester - forcer un drop de buff
	var buff_type = randi() % BuffType.size()
	create_buff_pickup_deferred(buff_type, position)
	print("🧪 Force dropped buff at: ", position)
