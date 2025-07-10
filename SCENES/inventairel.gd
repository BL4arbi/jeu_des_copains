extends Control

var weapon_slots: Array = []
var max_slots: int = 5

func _ready():
	add_to_group("inventory_ui")  # Ajouter au groupe pour être trouvé
	setup_inventory_ui()
	print("InventoryUI créé et ajouté au groupe")

func setup_inventory_ui():
	# Créer un container horizontal pour les slots
	var hbox = HBoxContainer.new()
	hbox.name = "WeaponSlots"
	add_child(hbox)
	
	# Créer 5 slots d'armes
	for i in range(max_slots):
		var slot = create_weapon_slot(i)
		weapon_slots.append(slot)
		hbox.add_child(slot)
	
	# Positionner l'UI en bas de l'écran
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	position = Vector2(20, -80)

func create_weapon_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.name = "Slot" + str(index)
	slot.custom_minimum_size = Vector2(60, 60)
	
	# Style du slot
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.GRAY
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	slot.add_theme_stylebox_override("panel", style)
	
	# Ajouter un cercle coloré pour représenter l'arme
	var weapon_circle = ColorRect.new()
	weapon_circle.name = "WeaponCircle"
	weapon_circle.color = Color.TRANSPARENT
	weapon_circle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	weapon_circle.size = Vector2(40, 40)
	weapon_circle.position = Vector2(10, 10)
	slot.add_child(weapon_circle)
	
	# Ajouter un label pour le numéro
	var number_label = Label.new()
	number_label.name = "Number"
	number_label.text = str(index + 1)
	number_label.add_theme_color_override("font_color", Color.WHITE)
	number_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	number_label.position = Vector2(4, 2)
	slot.add_child(number_label)
	
	return slot

func update_display(weapons: Array, current_index: int, weapon_database: Dictionary):
	print("=== MISE À JOUR INVENTAIRE ===")
	print("Armes: ", weapons)
	print("Index actuel: ", current_index)
	print("==============================")
	
	for i in range(max_slots):
		var slot = weapon_slots[i]
		var weapon_circle = slot.get_node("WeaponCircle")
		var style = slot.get_theme_stylebox("panel")
		
		if i < weapons.size():
			# Il y a une arme dans ce slot
			var weapon_type = weapons[i]
			
			# Couleur du cercle selon l'arme
			weapon_circle.color = get_weapon_color(weapon_type)
			
			# Style du slot selon la sélection
			if i == current_index:
				style.border_color = Color.YELLOW
				style.bg_color = Color(0.4, 0.4, 0.0, 0.8)
				print("Slot ", i, " sélectionné: ", weapon_type)
			else:
				style.border_color = Color.GRAY
				style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		else:
			# Slot vide
			weapon_circle.color = Color.TRANSPARENT
			style.border_color = Color.DARK_GRAY
			style.bg_color = Color(0.1, 0.1, 0.1, 0.5)

func get_weapon_color(weapon_type: String) -> Color:
	match weapon_type:
		"normal":
			return Color.WHITE
		"poison":
			return Color.GREEN
		"thunder":
			return Color.YELLOW
		"fireball":
			return Color.ORANGE
		_:
			return Color.GRAY
