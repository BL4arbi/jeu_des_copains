# WeaponPickup.gd - Version corrigée pour éviter les sprites qui traînent
extends Area2D
class_name WeaponPickup

@export var weapon_name: String = ""
@export var projectile_scene_path: String = ""
@export var damage: float = 10.0
@export var speed: float = 400.0
@export var fire_rate: float = 0.3
@export var weapon_description: String = ""
@export var weapon_rarity: String = "common"

var special_properties: Dictionary = {}
var despawn_timer: float = 15.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = get_node_or_null("Label")
@onready var rarity_glow: Sprite2D = get_node_or_null("RarityGlow")

# AJOUT : Stocker les effets créés pour les nettoyer
var created_effects: Array = []

func _ready():
	body_entered.connect(_on_pickup)
	
	print("=== WEAPON PICKUP CREATED ===")
	print("Name: ", weapon_name)
	print("Rarity: ", weapon_rarity)
	
	setup_weapon_appearance()
	create_floating_animation()
	start_despawn_timer()

func _process(delta):
	despawn_timer -= delta
	if despawn_timer <= 0:
		despawn_weapon()
	
	if despawn_timer <= 3.0:
		var flash_speed = (3.0 - despawn_timer) * 2
		sprite.modulate.a = 0.5 + 0.5 * sin(despawn_timer * 10.0)

func setup_weapon_appearance():
	if sprite:
		load_projectile_sprite()
		sprite.scale = Vector2(1.5, 1.5)  # Réduit la taille
	
	if label:
		label.text = weapon_name
		setup_rarity_colors()
	
	setup_rarity_glow()

func load_projectile_sprite():
	if projectile_scene_path != "" and ResourceLoader.exists(projectile_scene_path):
		var projectile_scene = load(projectile_scene_path)
		var temp_projectile = projectile_scene.instantiate()
		
		var projectile_sprite = temp_projectile.get_node_or_null("Sprite2D")
		if projectile_sprite and projectile_sprite.texture:
			sprite.texture = projectile_sprite.texture
			print("Loaded projectile sprite for: ", weapon_name)
		else:
			create_simple_sprite()
		
		temp_projectile.queue_free()
	else:
		create_simple_sprite()

# CORRECTION : Sprite plus simple et propre
func create_simple_sprite():
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	
	var color: Color
	match weapon_rarity:
		"common": color = Color.WHITE
		"rare": color = Color.CYAN
		"epic": color = Color.PURPLE
		"legendary": color = Color.GOLD
		"mythic": color = Color.RED
		_: color = Color.WHITE
	
	# Cercle simple au lieu de formes compliquées
	var center = Vector2(12, 12)
	for x in range(24):
		for y in range(24):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 8:
				var alpha = 1.0 - (distance / 8.0) * 0.3
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

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
		"mythic":
			label.add_theme_color_override("font_color", Color.RED)
		_:
			label.add_theme_color_override("font_color", Color.WHITE)

func setup_rarity_glow():
	if rarity_glow:
		rarity_glow.queue_free()
	
	rarity_glow = Sprite2D.new()
	add_child(rarity_glow)
	rarity_glow.z_index = -1
	
	var glow_color: Color
	var glow_intensity: float
	
	match weapon_rarity:
		"common":
			glow_color = Color.WHITE
			glow_intensity = 0.2
		"rare":
			glow_color = Color.CYAN
			glow_intensity = 0.4
		"epic":
			glow_color = Color.PURPLE
			glow_intensity = 0.6
		"legendary":
			glow_color = Color.GOLD
			glow_intensity = 0.8
		"mythic":
			glow_color = Color.RED
			glow_intensity = 1.0
		_:
			glow_color = Color.WHITE
			glow_intensity = 0.1
	
	var glow_size = 48
	var image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2, glow_size / 2)
	
	for x in range(glow_size):
		for y in range(glow_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= glow_size / 2:
				var alpha = (1.0 - distance / (glow_size / 2)) * glow_intensity * 0.3
				image.set_pixel(x, y, Color(glow_color.r, glow_color.g, glow_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	rarity_glow.texture = texture
	rarity_glow.position = Vector2(-glow_size / 2, -glow_size / 2)

func create_floating_animation():
	var start_y = position.y
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position:y", start_y - 5, 1.5)
	float_tween.tween_property(self, "position:y", start_y + 5, 1.5)

func start_despawn_timer():
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_color_override("font_color", Color.YELLOW)
	timer_label.add_theme_font_size_override("font_size", 10)
	timer_label.position = Vector2(-8, -35)
	add_child(timer_label)
	created_effects.append(timer_label)

func despawn_weapon():
	print("Weapon ", weapon_name, " despawned")
	cleanup_effects()
	queue_free()

# AJOUT : Nettoyer tous les effets créés
func cleanup_effects():
	for effect in created_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	created_effects.clear()

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
			print("✅ Player picked up ", weapon_rarity, " weapon: ", weapon_name)
			cleanup_effects()
			queue_free()
		else:
			print("❌ Player inventory full!")

func create_pickup_effect():
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	var effect_color: Color
	match weapon_rarity:
		"rare": effect_color = Color.CYAN
		"epic": effect_color = Color.PURPLE
		"legendary": effect_color = Color.GOLD
		"mythic": effect_color = Color.RED
		_: effect_color = Color.WHITE
	
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 12:
				var alpha = 1.0 - distance / 12.0
				image.set_pixel(x, y, Color(effect_color.r, effect_color.g, effect_color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = global_position
	
	# Effet qui se supprime automatiquement
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.4)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): 
		if is_instance_valid(effect):
			effect.queue_free()
	)

# AJOUT : S'assurer que tout est nettoyé quand le pickup est détruit
func _exit_tree():
	cleanup_effects()
