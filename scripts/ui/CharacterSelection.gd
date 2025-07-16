# CharacterSelection.gd
# À placer dans res://scripts/ui/CharacterSelection.gd

extends Control

# Références aux éléments UI - avec vérification
@onready var character_list: VBoxContainer = get_node_or_null("MarginContainer/HBoxContainer/LeftPanel/ScrollContainer/CharacterList")
@onready var character_sprite: TextureRect = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/CharacterPreview/CharacterSprite")
@onready var name_label: Label = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/CharacterInfo/NameLabel")
@onready var health_label: Label = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/CharacterInfo/StatsContainer/HealthLabel")
@onready var speed_label: Label = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/CharacterInfo/StatsContainer/SpeedLabel")
@onready var damage_label: Label = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/CharacterInfo/StatsContainer/DamageLabel")
@onready var description_label: Label = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/CharacterInfo/DescriptionLabel")
@onready var select_button: Button = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/ButtonContainer/SelectButton")
@onready var talents_button: Button = get_node_or_null("MarginContainer/HBoxContainer/RightPanel/ButtonContainer/TalentsButton")

# Variables
var selected_character_id: int = 0
var character_buttons: Array = []

func _ready():
	print("=== CharacterSelection Ready ===")
	check_ui_structure()
	setup_character_list()
	select_character(0)
	
	# Initialiser le gestionnaire de talents
	setup_talent_manager()
	
	# Connecter les boutons
	if select_button:
		select_button.pressed.connect(_on_select_button_pressed)
	else:
		print("ERROR: SelectButton not found!")
	
	if talents_button:
		talents_button.pressed.connect(_on_talents_button_pressed)
		print("✅ Talents button connected")
	else:
		print("❌ Talents button not found - you need to add it to the scene")

func check_ui_structure():
	print("UI Structure Check:")
	print("- character_list: ", character_list != null)
	print("- character_sprite: ", character_sprite != null)
	print("- name_label: ", name_label != null)
	print("- select_button: ", select_button != null)

func setup_character_list():
	if not character_list:
		print("ERROR: CharacterList not found! Cannot setup characters.")
		return
	
	# Nettoyer la liste existante
	for child in character_list.get_children():
		child.queue_free()
	
	character_buttons.clear()
	
	# Créer les boutons pour chaque personnage
	for i in range(GlobalData.characters_data.size()):
		var character_data = GlobalData.characters_data[i]
		var button = create_character_button(character_data, i)
		character_list.add_child(button)
		character_buttons.append(button)
	
	print("Created ", character_buttons.size(), " character buttons")

func create_character_button(character_data: Dictionary, index: int) -> Button:
	var button = Button.new()
	button.text = character_data.name
	button.custom_minimum_size = Vector2(200, 60)
	button.toggle_mode = true
	
	# Créer un groupe de boutons pour la sélection unique
	if character_buttons.is_empty():
		button.button_group = ButtonGroup.new()
	else:
		button.button_group = character_buttons[0].button_group
	
	# Connecter le signal
	button.pressed.connect(func(): select_character(index))
	
	return button

func select_character(character_id: int):
	selected_character_id = character_id
	var character_data = GlobalData.get_character_data(character_id)
	
	if character_data.is_empty():
		print("ERROR: Character data not found for ID: ", character_id)
		return
	
	print("Selected character: ", character_data.name)
	
	# Mettre à jour l'affichage
	update_character_preview(character_data)
	
	# Mettre à jour l'état des boutons
	for i in range(character_buttons.size()):
		character_buttons[i].button_pressed = (i == character_id)

func update_character_preview(character_data: Dictionary):
	# Nom du personnage
	if name_label:
		name_label.text = character_data.name
	
	# Stats
	if health_label:
		health_label.text = "Vie: " + str(character_data.health)
	if speed_label:
		speed_label.text = "Vitesse: " + str(character_data.speed)
	if damage_label:
		damage_label.text = "Dégâts: " + str(character_data.damage)
	
	# Description
	if description_label:
		description_label.text = character_data.description
	if name_label:
		name_label.text = character_data.name
	
	if health_label:
		health_label.text = "Vie: " + str(character_data.health)
	if speed_label:
		speed_label.text = "Vitesse: " + str(character_data.speed)
	if damage_label:
		damage_label.text = "Dégâts: " + str(character_data.damage)
	
	if description_label:
		description_label.text = character_data.description
	
	# NOUVEAU : Afficher les infos de talents
	if talent_manager:
		var talent_data = talent_manager.get_character_data(selected_character_id)
		if talent_data:
			var talent_info = "\n\n=== PROGRESSION ===\n"
			talent_info += "Niveau: " + str(talent_data.level) + "\n"
			talent_info += "Points de talents: " + str(talent_data.talent_points) + "\n"
			talent_info += "Expérience: " + str(talent_data.experience) + "/" + str(talent_data.experience_needed)
			
			if description_label:
				description_label.text += talent_info
	
	# Sprite du personnage (code existant)
	if character_sprite and character_data.has("sprite_path"):
		var sprite_path = character_data.sprite_path
		if ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			character_sprite.texture = texture
		else:
			character_sprite.texture = null
	

func _on_select_button_pressed():
	print("=== Select Button Pressed ===")
	
	# Sauvegarder la sélection
	GlobalData.select_character(selected_character_id)
	print("Character selected in GlobalData: ", GlobalData.player_stats)
	
	# Aller au TestLevel
	get_tree().change_scene_to_file("res://scenes/levels/TestLevel.tscn")
# CharacterSelection.gd - Ajout du bouton Talents

# === AJOUTER DANS LES VARIABLES ===
var talent_manager: Node

# === MODIFIER _ready() ===


func setup_talent_manager():
	# Créer le gestionnaire de talents s'il n'existe pas
	talent_manager = get_tree().get_first_node_in_group("talent_manager")
	if not talent_manager:
		var talent_manager_script = preload("res://scripts/managers/TalentManager.gd")
		talent_manager = talent_manager_script.new()
		talent_manager.name = "TalentManager"
		get_tree().current_scene.add_child(talent_manager)
		print("🌟 Talent Manager created")

# === NOUVELLE FONCTION POUR LE BOUTON TALENTS ===
func _on_talents_button_pressed():
	print("🌟 Talents button pressed for character: ", selected_character_id)
	
	# Sauvegarder le personnage sélectionné
	GlobalData.selected_character_id = selected_character_id
	
	# Aller à l'écran des talents
	get_tree().change_scene_to_file("res://scenes/ui/TalentTreeUI.tscn")


	





# === INSTRUCTIONS POUR MODIFIER LA SCÈNE (OPTIONNEL) ===
# Si vous voulez modifier la scène manuellement au lieu d'utiliser la création dynamique :
# 
# 1. Ouvrir CharacterSelection.tscn
# 2. Sélectionner RightPanel
# 3. Ajouter un HBoxContainer appelé "ButtonContainer"
# 4. Déplacer SelectButton dans ButtonContainer
# 5. Ajouter un nouveau Button appelé "TalentsButton" dans ButtonContainer
# 6. Configurer TalentsButton :
#    - Text: "Talents"
#    - Custom Minimum Size: 100x40
#    - Alignment: Center
