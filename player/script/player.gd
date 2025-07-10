class_name Player
extends CharacterBody2D

var movespeed: float = 150

# === INVENTAIRE SIMPLE ===
var weapons_inventory: Array = ["normal"]  # Commencer avec une arme
var current_weapon_index: int = 0

# Base de données des armes
var weapon_database = {
	"normal": {
		"name": "Basic Shot",
		"scene_path": "res://projectile.tscn",
		"count": 1
	},
	"poison": {
		"name": "Poison Bolt", 
		"scene_path": "res://SCENES/projectile/poison_proj.tscn",
		"count": 2
	},
	"thunder": {
		"name": "Thunder Bolt",
		"scene_path": "res://SCENES/projectile/poison_bolt.tscn",
		"count": 1
	}
}

# UI simple intégrée
var inventory_label: Label

func _ready():
	add_to_group("player")
	
	# Créer l'UI avec un délai
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(create_inventory_display)
	add_child(timer)
	timer.start()
	
	print("Joueur créé avec : ", weapons_inventory)

func create_inventory_display():
	# Créer le label d'inventaire en position fixe
	inventory_label = Label.new()
	inventory_label.position = Vector2(20, 20)  # Position fixe sur l'écran
	inventory_label.size = Vector2(200, 120)
	inventory_label.add_theme_color_override("font_color", Color.YELLOW)
	inventory_label.add_theme_color_override("font_outline_color", Color.BLACK)
	inventory_label.add_theme_constant_override("outline_size", 3)
	inventory_label.z_index = 1000
	
	# Ajouter à un CanvasLayer pour qu'il reste fixe - AVEC DEFER
	var canvas = CanvasLayer.new()
	canvas.name = "InventoryUI"
	get_tree().current_scene.call_deferred("add_child", canvas)
	
	# Attendre que le canvas soit ajouté puis ajouter le label
	await get_tree().process_frame
	canvas.call_deferred("add_child", inventory_label)
	
	# Attendre encore puis mettre à jour
	await get_tree().create_timer(0.1).timeout
	update_inventory_display()
	print("Inventaire créé en position fixe")

func update_inventory_display():
	if not inventory_label:
		return
	
	var text = "ARMES:\n"
	
	for i in range(weapons_inventory.size()):
		var weapon_type = weapons_inventory[i]
		var weapon_name = weapon_database[weapon_type].name
		
		# Version compacte
		if i == current_weapon_index:
			text += "► " + str(i + 1) + ". " + weapon_name + "\n"
		else:
			text += "  " + str(i + 1) + ". " + weapon_name + "\n"
	
	inventory_label.text = text
	print("Inventaire mis à jour: ", weapons_inventory)

func _process(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * movespeed
	move_and_slide()

func _physics_process(_delta: float) -> void:
	# Rotation du sprite
	handle_sprite_rotation()
	
	# Sélection d'arme
	if Input.is_action_just_pressed("weapon_1"):
		select_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		select_weapon(1)
	elif Input.is_action_just_pressed("weapon_3"):
		select_weapon(2)
	elif Input.is_action_just_pressed("weapon_4"):
		select_weapon(3)
	elif Input.is_action_just_pressed("weapon_5"):
		select_weapon(4)
	
	# Tir
	if Input.is_action_just_pressed("click"):
		fire_current_weapon()

func handle_sprite_rotation():
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var angle = direction.angle()
	var angle_degrees = rad_to_deg(angle)
	
	if angle_degrees > 180:
		angle_degrees -= 360
	elif angle_degrees < -180:
		angle_degrees += 360
	
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		
		if angle_degrees >= -90 and angle_degrees <= 90:
			sprite.flip_h = false
			sprite.rotation = angle
		else:
			sprite.flip_h = true
			if angle_degrees > 90:
				sprite.rotation = angle - PI
			else:
				sprite.rotation = angle + PI

func fire_current_weapon():
	if weapons_inventory.is_empty():
		print("Aucune arme !")
		return
	
	var weapon_type = weapons_inventory[current_weapon_index]
	var weapon_data = weapon_database[weapon_type]
	
	if not ResourceLoader.exists(weapon_data.scene_path):
		print("ERREUR : Scene non trouvée : ", weapon_data.scene_path)
		return
	
	var projectile_scene = load(weapon_data.scene_path)
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	print("🔫 Tir avec : ", weapon_data.name)
	
	for i in range(weapon_data.count):
		var projectile = projectile_scene.instantiate()
		setup_projectile(projectile, direction, i, weapon_data.count)
		get_parent().add_child(projectile)

func setup_projectile(projectile, base_direction, index, total_count):
	if has_node("Node2D"):
		projectile.pos = $Node2D.global_position
	else:
		projectile.pos = global_position
	
	var angle_offset = 0.0
	if total_count > 1:
		angle_offset = (index - (total_count - 1) / 2.0) * 0.2
	
	var final_direction = base_direction.rotated(angle_offset)
	projectile.dir = final_direction.angle()
	projectile.rota = final_direction.angle()

func add_weapon(weapon_type: String) -> bool:
	if not weapon_database.has(weapon_type):
		print("❌ Arme inconnue : ", weapon_type)
		return false
	
	if weapon_type in weapons_inventory:
		print("⚠️ Arme déjà possédée : ", weapon_database[weapon_type].name)
		return false
	
	if weapons_inventory.size() >= 5:
		print("📦 Inventaire plein !")
		return false
	
	weapons_inventory.append(weapon_type)
	var weapon_name = weapon_database[weapon_type].name
	print("✅ Nouvelle arme : ", weapon_name)
	
	update_inventory_display()
	return true

func select_weapon(index: int):
	if index < weapons_inventory.size():
		current_weapon_index = index
		var weapon_type = weapons_inventory[current_weapon_index]
		var weapon_name = weapon_database[weapon_type].name
		print("🎯 Arme sélectionnée : ", weapon_name)
		update_inventory_display()
	else:
		print("❌ Pas d'arme au slot ", index + 1)
