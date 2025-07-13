# HUD.gd - Version avec VRAIES sprites d'armes
extends Control

@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var kill_counter: Label = get_node_or_null("KillCounter")
@onready var level_info: Label = get_node_or_null("LevelInfo")
@onready var inventory_container: HBoxContainer = get_node_or_null("InventoryContainer")

var player: Player
var slot_nodes: Array = []

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

func _ready():
	player = get_tree().get_first_node_in_group("players")
	GlobalData.kill_count_updated.connect(_on_kill_count_updated)
	
	setup_inventory_slots()
	print("HUD ready - ", slot_nodes.size(), " slots found")

func setup_inventory_slots():
	slot_nodes.clear()
	
	for i in range(1, 6):
		var slot_name = "Slot" + str(i)
		if i == 5:
			slot_name = "slot5"
		
		var slot = get_node_or_null("InventoryContainer/" + slot_name)
		if slot:
			slot_nodes.append(slot)
			print("✅ Found slot: ", slot_name)
		else:
			print("❌ Missing slot: ", slot_name)
			slot_nodes.append(null)

func _on_kill_count_updated(new_count: int):
	if kill_counter:
		kill_counter.text = "Kills: " + str(new_count)

func _process(_delta):
	update_health_bar()
	update_inventory_display()

func update_health_bar():
	if not player or not health_bar:
		return
	
	var health_percent = (player.current_health / player.max_health) * 100
	health_bar.value = health_percent

func update_inventory_display():
	if not player:
		return
	
	# Mettre à jour chaque slot
	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		if not slot:
			continue
		
		var weapon_icon = slot.get_node_or_null("WeaponIcon")
		if not weapon_icon:
			continue
		
		# Si il y a une arme dans ce slot
		if i < player.weapons.size():
			var weapon = player.weapons[i]
			load_real_weapon_sprite(weapon_icon, weapon, i == player.current_weapon)
		else:
			# Slot vide
			weapon_icon.texture = null
			weapon_icon.modulate = Color.GRAY

func load_real_weapon_sprite(icon: TextureRect, weapon: ProjectileData, is_selected: bool):
	# CHARGER LA VRAIE SPRITE DE L'ARME
	var sprite_path = get_weapon_sprite_path(weapon.projectile_name)
	
	
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path)
		icon.texture = texture
		
		# Ajuster la taille pour bien voir dans l'inventaire
		icon.custom_minimum_size = Vector2(50, 50)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
	else:
		# Fallback simple si sprite pas trouvée
		create_fallback_icon(icon, weapon)
	
	# Couleur selon la sélection
	if is_selected:
		icon.modulate = Color.WHITE
		# Effet de sélection
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(icon, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.5)
	else:
		icon.modulate = Color(0.8, 0.8, 0.8, 1.0)
		icon.scale = Vector2(1.0, 1.0)

func get_weapon_sprite_path(weapon_name: String) -> String:
	if weapon_sprites.has(weapon_name):
		return weapon_sprites[weapon_name]
	else:
		# Sprite par défaut
		return "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png"

func create_fallback_icon(icon: TextureRect, weapon: ProjectileData):
	# Créer une icône simple si pas de sprite
	var image = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	
	# Couleur selon l'arme
	var color: Color
	match weapon.projectile_name:
		"Tir Basique": color = Color.WHITE
		"Tir Rapide": color = Color.YELLOW
		"Canon Lourd": color = Color.RED
		"Foudre": color = Color.BLUE
		_: color = Color.GRAY
	
	# Dessiner un carré coloré simple
	for x in range(10, 40):
		for y in range(10, 40):
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	icon.texture = texture
