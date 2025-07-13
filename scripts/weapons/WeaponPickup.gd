# WeaponPickup.gd - Version avec vrais sprites et timer
extends Area2D
class_name WeaponPickup

@export var weapon_name: String = ""
@export var projectile_scene_path: String = ""
@export var damage: float = 10.0
@export var speed: float = 400.0
@export var fire_rate: float = 0.3
@export var weapon_description: String = ""
@export var weapon_rarity: String = "common"

# Variables normales (pas @export)
var special_properties: Dictionary = {}
var despawn_timer: float = 15.0  # 15 secondes avant disparition

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = get_node_or_null("Label")
@onready var rarity_glow: Sprite2D = get_node_or_null("RarityGlow")

func _ready():
	body_entered.connect(_on_pickup)
	
	print("=== WEAPON PICKUP CREATED ===")
	print("Name: ", weapon_name)
	print("Rarity: ", weapon_rarity)
	
	setup_weapon_appearance()
	create_floating_animation()
	start_despawn_timer()

func _process(delta):
	# Timer de disparition
	despawn_timer -= delta
	if despawn_timer <= 0:
		despawn_weapon()
	
	# Effet de clignotement quand proche de disparaître
	if despawn_timer <= 3.0:
		var flash_speed = (3.0 - despawn_timer) * 2  # Plus rapide quand proche
		sprite.modulate.a = 0.5 + 0.5 * sin(despawn_timer * 10.0)
func setup_weapon_appearance():
	if sprite:
		# Utiliser le sprite du projectile correspondant
		load_projectile_sprite()
		sprite.scale = Vector2(2.0, 2.0)  # Plus gros pour visibilité
	
	if label:
		label.text = weapon_name
		setup_rarity_colors()
	
	setup_rarity_glow()

func load_projectile_sprite():
	# Charger le sprite du projectile correspondant
	if projectile_scene_path != "" and ResourceLoader.exists(projectile_scene_path):
		var projectile_scene = load(projectile_scene_path)
		var temp_projectile = projectile_scene.instantiate()
		
		# Récupérer le sprite du projectile
		var projectile_sprite = temp_projectile.get_node_or_null("Sprite2D")
		if projectile_sprite and projectile_sprite.texture:
			sprite.texture = projectile_sprite.texture
			print("Loaded projectile sprite for: ", weapon_name)
		else:
			create_fallback_sprite()
		
		temp_projectile.queue_free()
	else:
		create_fallback_sprite()

func create_fallback_sprite():
	# Sprite de secours si pas de projectile trouvé
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	
	# Formes selon le type d'arme
	match weapon_name:
		"Tir Rapide":
			create_bullet_sprite(image, Color.YELLOW)
		"Canon Lourd":
			create_heavy_sprite(image, Color.RED)
		"Tir Perçant":
			create_arrow_sprite(image, Color.GREEN)
		"Flèche Fork":
			create_fork_sprite(image, Color.PURPLE)
		"Tir Chercheur":
			create_seeking_sprite(image, Color.CYAN)
		"Chakram":
			create_chakram_sprite(image, Color.GOLD)
		"Foudre":
			create_lightning_sprite(image, Color.YELLOW)
		"Pluie de Météores":
			create_meteor_sprite(image, Color.ORANGE)
		_:
			image.fill(Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func create_bullet_sprite(image: Image, color: Color):
	# Petite balle ronde
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 6:
				image.set_pixel(x, y, color)

func create_heavy_sprite(image: Image, color: Color):
	# Gros projectile carré
	for x in range(10, 22):
		for y in range(10, 22):
			image.set_pixel(x, y, color)

func create_arrow_sprite(image: Image, color: Color):
	# Forme de flèche
	# Pointe
	for x in range(20, 28):
		for y in range(14, 18):
			if x < 24 or (y >= 15 and y <= 16):
				image.set_pixel(x, y, color)
	# Corps
	for x in range(8, 20):
		for y in range(15, 17):
			image.set_pixel(x, y, color)

func create_fork_sprite(image: Image, color: Color):
	# Flèche avec fourche
	create_arrow_sprite(image, color)
	# Branches
	for x in range(22, 26):
		for y in range(12, 14):
			image.set_pixel(x, y, color)
	for x in range(22, 26):
		for y in range(18, 20):
			image.set_pixel(x, y, color)

func create_seeking_sprite(image: Image, color: Color):
	# Projectile avec "ailes"
	create_bullet_sprite(image, color)
	# Ailes
	for x in range(8, 12):
		for y in range(12, 20):
			if (x + y) % 2 == 0:
				image.set_pixel(x, y, color)

func create_chakram_sprite(image: Image, color: Color):
	# Anneau
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 10 and distance >= 6:
				image.set_pixel(x, y, color)

func create_lightning_sprite(image: Image, color: Color):
	# Zigzag d'éclair
	var points = [Vector2(16, 4), Vector2(18, 8), Vector2(14, 12), Vector2(20, 16), Vector2(12, 20), Vector2(18, 24), Vector2(14, 28)]
	for i in range(points.size() - 1):
		draw_line_on_image(image, points[i], points[i + 1], color)

func create_meteor_sprite(image: Image, color: Color):
	# Météore avec traînée
	var center = Vector2(20, 12)
	# Corps
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 6:
				image.set_pixel(x, y, color)
	# Traînée
	for i in range(15):
		var trail_x = center.x - i * 2
		var trail_y = center.y + i
		if trail_x >= 0 and trail_x < 32 and trail_y >= 0 and trail_y < 32:
			image.set_pixel(trail_x, trail_y, Color(color.r * 0.7, color.g * 0.4, 0))

func draw_line_on_image(image: Image, from: Vector2, to: Vector2, color: Color):
	var steps = int(max(abs(to.x - from.x), abs(to.y - from.y)))
	if steps == 0:
		return
	
	var x_inc = (to.x - from.x) / steps
	var y_inc = (to.y - from.y) / steps
	
	for i in range(steps + 1):
		var x = int(from.x + x_inc * i)
		var y = int(from.y + y_inc * i)
		if x >= 0 and x < 32 and y >= 0 and y < 32:
			image.set_pixel(x, y, color)

func setup_rarity_colors():
	if not label:
		return
	
	match weapon_rarity:
		"common":
			label.add_theme_color_override("font_color", Color.WHITE)
		"rare":
			label.add_theme_color_override("font_color", Color.CYAN)
		"epic":
			label.add_theme_color_override("font_color", Color.PURPLE)
		"legendary":
			label.add_theme_color_override("font_color", Color.GOLD)
		_:
			label.add_theme_color_override("font_color", Color.WHITE)

func setup_rarity_glow():
	if not rarity_glow:
		rarity_glow = Sprite2D.new()
		add_child(rarity_glow)
		rarity_glow.z_index = -1
	
	var glow_color: Color
	var glow_intensity: float
	
	match weapon_rarity:
		"common":
			glow_color = Color.WHITE
			glow_intensity = 0.3
		"rare":
			glow_color = Color.CYAN
			glow_intensity = 0.5
		"epic":
			glow_color = Color.PURPLE
			glow_intensity = 0.7
		"legendary":
			glow_color = Color.GOLD
			glow_intensity = 1.0
		_:
			glow_color = Color.WHITE
			glow_intensity = 0.2
	
	var glow_size = 80
	var image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2, glow_size / 2)
	
	for x in range(glow_size):
		for y in range(glow_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= glow_size / 2:
				var alpha = (1.0 - distance / (glow_size / 2)) * glow_intensity * 0.4
				image.set_pixel(x, y, Color(glow_color.r, glow_color.g, glow_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	rarity_glow.texture = texture
	rarity_glow.position = Vector2(-glow_size / 2, -glow_size / 2)

func create_floating_animation():
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position:y", position.y - 8, 2.0)
	float_tween.tween_property(self, "position:y", position.y + 8, 2.0)
	
	if weapon_rarity in ["rare", "epic", "legendary"]:
		var rotation_tween = create_tween()
		rotation_tween.set_loops()
		rotation_tween.tween_property(sprite, "rotation", PI * 2, 5.0)

func start_despawn_timer():
	# Timer visuel qui montre le temps restant
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_color_override("font_color", Color.YELLOW)
	timer_label.add_theme_font_size_override("font_size", 12)
	timer_label.position = Vector2(-15, -50)
	add_child(timer_label)
	
	# Mettre à jour le timer
	var timer_update = func():
		if is_instance_valid(timer_label):
			timer_label.text = str(int(despawn_timer))

func despawn_weapon():
	print("Weapon ", weapon_name, " despawned")
	
	# Effet de disparition
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.5)
	tween.tween_callback(func(): queue_free())

func _on_pickup(body):
	if body.is_in_group("players") and body.has_method("pickup_weapon"):
		var weapon_data = ProjectileData.new()
		weapon_data.projectile_name = weapon_name
		weapon_data.damage = damage
		weapon_data.speed = speed
		weapon_data.fire_rate = fire_rate
		weapon_data.projectile_scene_path = projectile_scene_path
		weapon_data.description = weapon_description
		weapon_data.special_properties = special_properties
		
		create_pickup_effect()
		
		if body.pickup_weapon(weapon_data):
			print("Player picked up ", weapon_rarity, " weapon: ", weapon_name)
			queue_free()
		else:
			print("Player inventory full!")

func create_pickup_effect():
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var effect_color: Color
	match weapon_rarity:
		"rare":
			effect_color = Color.CYAN
		"epic":
			effect_color = Color.PURPLE
		"legendary":
			effect_color = Color.GOLD
		_:
			effect_color = Color.WHITE
	
	var image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(effect_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = global_position
	
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(3, 3), 0.5)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): effect.queue_free())
