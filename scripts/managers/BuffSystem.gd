# BuffSystem.gd - Buffs permanents ultra simple (CORRIGÉ)
extends Node
class_name BuffSystem

# Types de buffs permanents
enum BuffType {
	DAMAGE_BOOST,
	HEALTH_BOOST,
	SPEED_BOOST,
	FIRE_RATE_BOOST,
	ARMOR_BOOST,
	LIFESTEAL,
	MULTISHOT,
	PENETRATION
}

# Base de données des buffs PERMANENTS
var buff_database: Dictionary = {
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
	}
}

# Tables de drops simplifiées
var buff_drop_tables: Dictionary = {
	"Grunt": {
		"drop_chance": 0.1,
		"buffs": [BuffType.DAMAGE_BOOST, BuffType.HEALTH_BOOST, BuffType.SPEED_BOOST]
	},
	"Shooter": {
		"drop_chance": 0.15,
		"buffs": [BuffType.FIRE_RATE_BOOST, BuffType.ARMOR_BOOST, BuffType.LIFESTEAL]
	},
	"Elite": {
		"drop_chance": 0.25,
		"buffs": [BuffType.MULTISHOT, BuffType.PENETRATION, BuffType.LIFESTEAL, BuffType.ARMOR_BOOST]
	}
}

var player_ref: Player = null

func _ready():
	add_to_group("buff_system")
	player_ref = get_tree().get_first_node_in_group("players")
	print("⭐ Permanent Buff system ready")

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
	# Créer un Area2D ultra simple
	var pickup = Area2D.new()
	pickup.name = "BuffPickup"
	
	# COLLISION CORRIGÉE - Si player est layer 1, le pickup doit être layer 2
	pickup.collision_layer = 2     # Pickup sur layer 2
	pickup.collision_mask = 1      # Détecte layer 1 (player)
	pickup.monitoring = true       # IMPORTANT!
	pickup.monitorable = true      # Pour que le player puisse le détecter
	
	# Collision shape ÉNORME pour être sûr
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60.0  # ÉNORME
	collision.shape = shape
	pickup.add_child(collision)
	
	# VRAIE ICÔNE avec texture sprite existante
	var sprite = Sprite2D.new()
	pickup.add_child(sprite)
	
	# Utiliser une vraie texture du jeu selon le buff
	var sprite_path = get_buff_sprite_path(buff_type)
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# Fallback - carré coloré
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var color = get_buff_color(buff_type)
		image.fill(color)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture
	
	sprite.scale = Vector2(3, 3)  # GROS pour bien voir
	sprite.modulate = get_buff_color(buff_type)  # Couleur selon le buff
	
	# Label avec nom PLUS GROS
	var label = Label.new()
	var buff_data = buff_database[buff_type]
	label.text = buff_data.icon + " " + buff_data.name
	label.position = Vector2(-80, -60)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.YELLOW)
	pickup.add_child(label)
	
	# Indicateur visuel supplémentaire
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
	
	# Métadonnées
	pickup.set_meta("buff_type", buff_type)
	pickup.set_meta("buff_data", buff_data)
	
	# Position
	pickup.global_position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	
	# Ajouter à la scène AVANT de connecter
	get_tree().current_scene.add_child(pickup)
	
	# Attendre puis connecter le signal SANS bind()
	await get_tree().process_frame
	pickup.body_entered.connect(func(body): _on_pickup_touched(pickup, body))
	
	# Timer de despawn
	var timer = Timer.new()
	pickup.add_child(timer)
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(pickup.queue_free)
	timer.start()
	
	print("⭐ Created ", buff_data.name, " at ", position, " | Collision layer: ", pickup.collision_layer, " mask: ", pickup.collision_mask)

func _on_pickup_touched(pickup: Area2D, body):
	if not body.is_in_group("players"):
		return
	
	var buff_type = pickup.get_meta("buff_type")
	var buff_data = pickup.get_meta("buff_data")
	
	print("✅ Player got permanent buff: ", buff_data.name)
	
	# Appliquer le buff PERMANENT au joueur
	apply_permanent_buff(buff_type, buff_data.value)
	
	# Notification
	show_buff_notification(buff_data.name, buff_data.icon)
	
	# Effet visuel
	create_pickup_effect(pickup.global_position)
	
	# Détruire le pickup
	pickup.queue_free()

func apply_permanent_buff(buff_type: int, value: float):
	if not player_ref:
		return
	
	match buff_type:
		BuffType.DAMAGE_BOOST:
			player_ref.damage += value
			player_ref.base_damage += value
			print("💪 +", value, " damage permanent! Total: ", player_ref.damage)
		
		BuffType.HEALTH_BOOST:
			player_ref.max_health += value
			player_ref.current_health += value  # Heal aussi
			print("❤️ +", value, " HP permanent! Total: ", player_ref.max_health)
		
		BuffType.SPEED_BOOST:
			player_ref.speed += value
			player_ref.base_speed += value
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

# FONCTION MANQUANTE - Ajouter cette fonction pour corriger l'erreur
func get_buff_sprite_path(buff_type: int) -> String:
	# Retourne le chemin vers les sprites selon le type de buff
	match buff_type:
		BuffType.DAMAGE_BOOST:
			return "res://assets/ui/damage_icon.png"
		BuffType.HEALTH_BOOST:
			return "res://assets/ui/health_icon.png"
		BuffType.SPEED_BOOST:
			return "res://assets/ui/speed_icon.png"
		BuffType.FIRE_RATE_BOOST:
			return "res://assets/ui/fire_rate_icon.png"
		BuffType.ARMOR_BOOST:
			return "res://assets/ui/armor_icon.png"
		BuffType.LIFESTEAL:
			return "res://assets/ui/lifesteal_icon.png"
		BuffType.MULTISHOT:
			return "res://assets/ui/multishot_icon.png"
		BuffType.PENETRATION:
			return "res://assets/ui/penetration_icon.png"
		_:
			return "res://assets/ui/default_buff_icon.png"

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
		_: return Color.WHITE

func show_buff_notification(buff_name: String, icon: String):
	var notification = Label.new()
	notification.text = icon + " " + buff_name + " PERMANENT!"
	notification.position = Vector2(400, 100)
	notification.add_theme_font_size_override("font_size", 20)
	notification.add_theme_color_override("font_color", Color.GOLD)
	
	get_tree().current_scene.add_child(notification)
	
	# Timer pour faire disparaître
	var timer = Timer.new()
	notification.add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(notification.queue_free)
	timer.start()

func create_pickup_effect(position: Vector2):
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color.GOLD)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position
	
	# Timer pour faire disparaître
	var timer = Timer.new()
	effect.add_child(timer)
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(effect.queue_free)
	timer.start()

# Force drop pour test
func force_drop_buff(position: Vector2):
	var buff_type = randi() % BuffType.size()
	create_simple_buff_pickup(buff_type, position)
	print("🧪 Force dropped buff at: ", position)
