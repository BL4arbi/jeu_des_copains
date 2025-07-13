# WeaponReplacementUI.gd - Script pour l'interface de remplacement
extends Control
class_name WeaponReplacementUI

# Signaux
signal weapon_replaced(weapon_index: int)
signal replacement_cancelled()

# Variables
var player_ref: Player
var new_weapon_data: ProjectileData
var weapon_buttons: Array = []

# Références UI
@onready var background: ColorRect = $Background
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var new_weapon_label: Label = $Panel/NewWeaponLabel
@onready var instruction_label: Label = $Panel/InstructionLabel
@onready var weapons_container: VBoxContainer = $Panel/WeaponsContainer
@onready var cancel_button: Button = $Panel/CancelButton

func _ready():
	# Connecter les signaux
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Masquer au début
	visible = false

func show_replacement_choice(player: Player, new_weapon: ProjectileData):
	player_ref = player
	new_weapon_data = new_weapon
	
	# Mettre à jour les textes
	update_ui_content()
	
	# Créer les boutons pour chaque arme
	create_weapon_buttons()
	
	# Afficher l'interface
	visible = true
	
	# Pause le jeu (optionnel)
	get_tree().paused = true

func update_ui_content():
	title_label.text = "Inventaire plein !"
	new_weapon_label.text = "Nouvelle arme: " + new_weapon_data.projectile_name
	instruction_label.text = "Cliquez sur l'arme à remplacer:"
	
	# Couleur selon la rareté
	var rarity_color = get_rarity_color(get_weapon_rarity(new_weapon_data))
	new_weapon_label.add_theme_color_override("font_color", rarity_color)

func create_weapon_buttons():
	# Nettoyer les anciens boutons
	for button in weapon_buttons:
		if is_instance_valid(button):
			button.queue_free()
	weapon_buttons.clear()
	
	# Créer un bouton pour chaque arme du joueur
	for i in range(player_ref.weapons.size()):
		var weapon = player_ref.weapons[i]
		var button = create_weapon_button(weapon, i)
		weapons_container.add_child(button)
		weapon_buttons.append(button)

func create_weapon_button(weapon: ProjectileData, index: int) -> Button:
	var button = Button.new()
	
	# Texte du bouton
	var button_text = str(index + 1) + ". " + weapon.projectile_name
	button_text += " (Dégâts: " + str(weapon.damage) + ")"
	button.text = button_text
	
	# Style du bouton
	button.custom_minimum_size = Vector2(300, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Couleur selon la rareté de l'arme actuelle
	var rarity = get_weapon_rarity(weapon)
	var rarity_color = get_rarity_color(rarity)
	button.add_theme_color_override("font_color", rarity_color)
	
	# Connexion du signal
	button.pressed.connect(_on_weapon_button_pressed.bind(index))
	
	return button

func get_weapon_rarity(weapon: ProjectileData) -> String:
	# Déterminer la rareté selon le nom de l'arme
	match weapon.projectile_name:
		"Tir Basique", "Tir Rapide", "Canon Lourd":
			return "common"
		"Tir Perçant", "Flèche Fork", "Tir Chercheur":
			return "rare"
		"Chakram", "Foudre", "Pluie de Météores":
			return "epic"
		"Laser Rotatif", "Nova Stellaire":
			return "legendary"
		"Apocalypse", "Singularité":
			return "mythic"
		_:
			return "common"

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"rare": return Color.CYAN
		"epic": return Color.PURPLE
		"legendary": return Color.GOLD
		"mythic": return Color.RED
		_: return Color.WHITE

func _on_weapon_button_pressed(weapon_index: int):
	print("🔄 Player chose to replace weapon ", weapon_index)
	
	# Émettre le signal avec l'index choisi
	weapon_replaced.emit(weapon_index)
	
	# Fermer l'interface
	close_ui()

func _on_cancel_pressed():
	print("❌ Player cancelled weapon replacement")
	
	# Émettre le signal d'annulation
	replacement_cancelled.emit()
	
	# Fermer l'interface
	close_ui()

func close_ui():
	# Masquer l'interface
	visible = false
	
	# Reprendre le jeu
	get_tree().paused = false
	
	# Se détruire
	queue_free()

# Gestion des entrées pour fermer avec Echap
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
