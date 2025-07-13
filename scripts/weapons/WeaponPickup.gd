# WeaponPickup.gd - Correction de l'erreur queue_free
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

# BASE DE DONNÉES DES SPRITES D'ARMES
var weapon_sprites: Dictionary = {
	"Tir Basique": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Tir Rapide": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png", 
	"Canon Lourd": "res://assets/SPRITES/weapon/GRENADE_TOP_DOWN.png",
	"Tir Perçant": "res://assets/SPRITES/weapon/Pickaxe_TOP_DOWN.png",
	"Flèche Fork": "res://assets/SPRITES/projectiles/SplittingArrow.png",
	"Tir Chercheur": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Chakram": "res://assets/SPRITES/weapon/Collectibles_TOP_DOWN.png",
	"Foudre": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Pluie de Météores": "res://assets/SPRITES/weapon/GRENADE_TOP_DOWN.png",
	"Laser Rotatif": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Nova Stellaire": "res://assets/SPRITES/weapon/AttackSprite01.png",
	"Apocalypse": "res://assets/SPRITES/weapon/GRENADE_TOP_DOWN.png",
	"Singularité": "res://assets/SPRITES/weapon/AttackSprite01.png"
}

# Variables pour les effets
var created_effects: Array = []
var rarity_glow: Sprite2D = null
var timer_label: Label = null
var name_label: Label = null
var cleanup_timer: Timer = null
var is_being_destroyed: bool = false

# NOUVEAU : Variables pour le système de remplacement
var replacement_ui: Control = null
var is_showing_replacement_ui: bool = false

func _ready():
	body_entered.connect(_on_pickup)
	tree_exiting.connect(_on_tree_exiting)
	
	print("=== WEAPON PICKUP CREATED ===")
	print("🗡️ Weapon: ", weapon_name)
	print("✨ Rarity: ", weapon_rarity)
	
	setup_weapon_appearance()
	create_floating_animation()
	start_despawn_timer()
	setup_cleanup_timer()

func setup_cleanup_timer():
	cleanup_timer = Timer.new()
	add_child(cleanup_timer)
	cleanup_timer.wait_time = 20.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(_force_cleanup)
	cleanup_timer.start()

func _process(delta):
	if is_being_destroyed:
		return
		
	despawn_timer -= delta
	
	if timer_label and is_instance_valid(timer_label):
		timer_label.text = str(int(despawn_timer)) + "s"
	
	if despawn_timer <= 0:
		despawn_weapon()
		return
	
	if despawn_timer <= 3.0 and sprite and is_instance_valid(sprite):
		var flash_alpha = 0.5 + 0.5 * sin(despawn_timer * 10.0)
		sprite.modulate.a = flash_alpha

func setup_weapon_appearance():
	if sprite and is_instance_valid(sprite):
		load_real_weapon_sprite()
	
	call_deferred("setup_labels_deferred")

func setup_labels_deferred():
	if is_being_destroyed:
		return
		
	setup_weapon_label()
	setup_rarity_glow()

func load_real_weapon_sprite():
	var sprite_path = get_weapon_sprite_path(weapon_name)
	
	print("🗡️ Loading pickup sprite: ", weapon_name, " -> ", sprite_path)
	
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path)
		sprite.texture = texture
		sprite.scale = Vector2(3.0, 3.0)
		apply_rarity_tint()
		print("✅ Weapon sprite loaded successfully!")
	else:
		print("❌ Weapon sprite not found: ", sprite_path)
		create_fallback_sprite()

func get_weapon_sprite_path(weapon_name: String) -> String:
	if weapon_sprites.has(weapon_name):
		return weapon_sprites[weapon_name]
	else:
		return "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png"

func apply_rarity_tint():
	if not sprite or not is_instance_valid(sprite):
		return
		
	match weapon_rarity:
		"common":
			sprite.modulate = Color.WHITE
		"rare":
			sprite.modulate = Color(0.8, 1.2, 1.2, 1.0)
		"epic":
			sprite.modulate = Color(1.2, 0.8, 1.2, 1.0)
		"legendary":
			sprite.modulate = Color(1.2, 1.2, 0.8, 1.0)
		"mythic":
			sprite.modulate = Color(1.2, 0.8, 0.8, 1.0)
		_:
			sprite.modulate = Color.WHITE

func create_fallback_sprite():
	if is_being_destroyed:
		return
		
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	var color: Color
	match weapon_rarity:
		"rare": color = Color.CYAN
		"epic": color = Color.PURPLE
		"legendary": color = Color.GOLD
		"mythic": color = Color.RED
		_: color = Color.WHITE
	
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var distance = abs(x - 16) + abs(y - 16)
			if distance <= 12:
				var alpha = 1.0 - (distance / 12.0) * 0.3
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	if sprite and is_instance_valid(sprite):
		sprite.texture = texture
		sprite.scale = Vector2(2.0, 2.0)

func setup_weapon_label():
	if is_being_destroyed:
		return
		
	if name_label and is_instance_valid(name_label):
		name_label.queue_free()
	
	name_label = Label.new()
	name_label.text = weapon_name
	name_label.position = Vector2(-50, -60)
	
	var label_color: Color
	match weapon_rarity:
		"common": label_color = Color.WHITE
		"rare": label_color = Color.CYAN
		"epic": label_color = Color.PURPLE
		"legendary": label_color = Color.GOLD
		"mythic": label_color = Color.RED
		_: label_color = Color.WHITE
	
	name_label.add_theme_color_override("font_color", label_color)
	name_label.add_theme_font_size_override("font_size", 12)
	
	add_child(name_label)
	created_effects.append(name_label)

func setup_rarity_glow():
	if is_being_destroyed:
		return
		
	if rarity_glow and is_instance_valid(rarity_glow):
		rarity_glow.queue_free()
	
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
			glow_intensity = 0.9
		"mythic":
			glow_color = Color.RED
			glow_intensity = 1.0
		_:
			glow_color = Color.WHITE
			glow_intensity = 0.2
	
	create_glow_effect(glow_color, glow_intensity)
	created_effects.append(rarity_glow)

func create_glow_effect(color: Color, intensity: float):
	if not rarity_glow or not is_instance_valid(rarity_glow) or is_being_destroyed:
		return
		
	var glow_size = 80
	var image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2, glow_size / 2)
	
	for x in range(glow_size):
		for y in range(glow_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= glow_size / 2:
				var alpha = (1.0 - distance / (glow_size / 2)) * intensity * 0.4
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	rarity_glow.texture = texture
	rarity_glow.position = Vector2(-glow_size / 2, -glow_size / 2)

func create_floating_animation():
	if not is_inside_tree() or is_being_destroyed:
		return
		
	var start_y = position.y
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position:y", start_y - 8, 1.5)
	float_tween.tween_property(self, "position:y", start_y + 8, 1.5)

func start_despawn_timer():
	if is_being_destroyed:
		return
		
	timer_label = Label.new()
	timer_label.text = str(int(despawn_timer)) + "s"
	timer_label.position = Vector2(-15, -80)
	timer_label.add_theme_color_override("font_color", Color.YELLOW)
	timer_label.add_theme_font_size_override("font_size", 10)
	
	add_child(timer_label)
	created_effects.append(timer_label)

func despawn_weapon():
	if is_being_destroyed:
		return
		
	print("💀 Weapon ", weapon_name, " despawned")
	is_being_destroyed = true
	cleanup_effects()
	
	# CORRECTION : Vérifier avant queue_free
	if is_inside_tree():
		queue_free()

func cleanup_effects():
	for effect in created_effects:
		if is_instance_valid(effect):
			# CORRECTION : Utiliser call_deferred pour éviter l'erreur
			effect.call_deferred("queue_free")
	created_effects.clear()
	
	rarity_glow = null
	timer_label = null
	name_label = null

func _force_cleanup():
	print("🧹 Force cleanup for weapon pickup: ", weapon_name)
	despawn_weapon()

func _on_tree_exiting():
	is_being_destroyed = true
	cleanup_effects()



func show_replacement_ui(player: Player, new_weapon: ProjectileData):
	is_showing_replacement_ui = true
	
	# Créer l'UI de remplacement
	replacement_ui = create_replacement_ui(player, new_weapon)
	get_tree().current_scene.add_child(replacement_ui)
	
	print("🔄 Showing weapon replacement UI for: ", new_weapon.projectile_name)

func create_replacement_ui(player: Player, new_weapon: ProjectileData) -> Control:
	var ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Fond semi-transparent
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)
	
	# Panel principal
	var panel = Panel.new()
	panel.position = Vector2(400, 200)
	panel.size = Vector2(400, 300)
	ui.add_child(panel)
	
	# Titre
	var title = Label.new()
	title.text = "Inventaire plein ! Remplacer une arme ?"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)
	
	# Nouvelle arme
	var new_weapon_label = Label.new()
	new_weapon_label.text = "Nouvelle arme: " + new_weapon.projectile_name + " (" + weapon_rarity + ")"
	new_weapon_label.position = Vector2(20, 50)
	new_weapon_label.add_theme_color_override("font_color", get_rarity_color(weapon_rarity))
	panel.add_child(new_weapon_label)
	
	# Liste des armes actuelles
	var weapons_label = Label.new()
	weapons_label.text = "Remplacer quelle arme ? (Clic pour choisir)"
	weapons_label.position = Vector2(20, 80)
	panel.add_child(weapons_label)
	
	# Boutons pour chaque arme
	for i in range(player.weapons.size()):
		var weapon = player.weapons[i]
		var button = Button.new()
		button.text = str(i + 1) + ". " + weapon.projectile_name
		button.position = Vector2(20, 110 + i * 30)
		button.size = Vector2(200, 25)
		
		# Connexion du signal avec capture des variables
		var weapon_index = i
		button.pressed.connect(func(): replace_weapon(player, new_weapon, weapon_index))
		
		panel.add_child(button)
	
	# Bouton Annuler
	var cancel_button = Button.new()
	cancel_button.text = "Annuler"
	cancel_button.position = Vector2(250, 250)
	cancel_button.size = Vector2(100, 30)
	cancel_button.pressed.connect(cancel_replacement)
	panel.add_child(cancel_button)
	
	return ui

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"rare": return Color.CYAN
		"epic": return Color.PURPLE
		"legendary": return Color.GOLD
		"mythic": return Color.RED
		_: return Color.WHITE

func replace_weapon(player: Player, new_weapon: ProjectileData, weapon_index: int):
	var old_weapon = player.weapons[weapon_index]
	print("🔄 Replacing ", old_weapon.projectile_name, " with ", new_weapon.projectile_name)
	
	# Remplacer l'arme
	player.weapons[weapon_index] = new_weapon
	
	# Ajuster l'arme actuelle si nécessaire
	if player.current_weapon >= player.weapons.size():
		player.current_weapon = player.weapons.size() - 1
	
	create_pickup_effect()
	close_replacement_ui()
	safe_destroy()
	
	print("✅ Weapon replacement complete!")

func cancel_replacement():
	print("❌ Weapon replacement cancelled")
	close_replacement_ui()

func close_replacement_ui():
	if replacement_ui and is_instance_valid(replacement_ui):
		replacement_ui.queue_free()
		replacement_ui = null
	
	is_showing_replacement_ui = false

func create_pickup_effect():
	if not sprite or not is_instance_valid(sprite) or is_being_destroyed:
		return
		
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	effect.texture = sprite.texture
	effect.global_position = global_position
	effect.scale = sprite.scale
	
	var effect_color: Color
	match weapon_rarity:
		"rare": effect_color = Color.CYAN
		"epic": effect_color = Color.PURPLE
		"legendary": effect_color = Color.GOLD
		"mythic": effect_color = Color.RED
		_: effect_color = Color.WHITE
	
	effect.modulate = effect_color
	
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", sprite.scale * 2, 0.5)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): 
		if is_instance_valid(effect):
			effect.queue_free()
	)

func safe_destroy():
	is_being_destroyed = true
	cleanup_effects()
	
	if is_inside_tree():
		call_deferred("queue_free")

func _exit_tree():
	cleanup_effects()
	close_replacement_ui()
	
func _on_pickup(body):
	if is_being_destroyed:
		return
		
	if body.is_in_group("players") and body.has_method("pickup_weapon"):
		var weapon_data = ProjectileData.new()
		weapon_data.projectile_name = weapon_name
		weapon_data.damage = damage
		weapon_data.speed = speed
		weapon_data.fire_rate = fire_rate
		weapon_data.projectile_scene_path = projectile_scene_path
		weapon_data.description = weapon_description
		weapon_data.special_properties = special_properties
		
		# NOUVEAU : Vérifier si l'inventaire est plein
		if body.weapons.size() >= 5:
			pass #show_replacement_ui_simple(body, weapon_data)
		else:
			# Inventaire pas plein, ajouter directement
			create_pickup_effect()
			if body.pickup_weapon(weapon_data):
				print("✅ Player picked up ", weapon_rarity, " weapon: ", weapon_name)
				safe_destroy()
			else:
				print("❌ Player already has this weapon!")

func show_replacement_ui_simple(player: Player, new_weapon: ProjectileData):
	# Charger la scène UI de remplacement
	var ui_scene = preload("res://scenes/ui/weapon_replacement_ui.tscn")
	var ui_instance = ui_scene.instantiate()
	
	# Ajouter à la scène
	get_tree().current_scene.add_child(ui_instance)
	
	# Connecter les signaux
	ui_instance.weapon_replaced.connect(_on_weapon_replaced.bind(player, new_weapon))
	ui_instance.replacement_cancelled.connect(_on_replacement_cancelled)
	
	# Afficher l'interface avec les données
	ui_instance.show_replacement_choice(player, new_weapon)
	
	print("🔄 Showing weapon replacement UI for: ", new_weapon.projectile_name)

func _on_weapon_replaced(player: Player, new_weapon: ProjectileData, weapon_index: int):
	var old_weapon = player.weapons[weapon_index]
	print("🔄 Replacing ", old_weapon.projectile_name, " with ", new_weapon.projectile_name)
	
	# Remplacer l'arme
	player.weapons[weapon_index] = new_weapon
	
	# Ajuster l'arme actuelle si nécessaire
	if player.current_weapon >= player.weapons.size():
		player.current_weapon = player.weapons.size() - 1
	
	create_pickup_effect()
	safe_destroy()
	
	print("✅ Weapon replacement complete!")

func _on_replacement_cancelled():
	print("❌ Weapon replacement cancelled - pickup remains")
	# Le pickup reste sur le terrain, le joueur peut réessayer plus tard
