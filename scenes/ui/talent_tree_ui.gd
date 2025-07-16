# TalentTreeUI.gd - Système simple avec boutons individuels pour chaque stat
extends Control

# Références UI
@onready var background: ColorRect = $Background
@onready var main_panel: Panel = $Background/MainPanel
@onready var character_name_label: Label = $Background/MainPanel/Header/CharacterName
@onready var level_label: Label = $Background/MainPanel/Header/LevelLabel
@onready var experience_bar: ProgressBar = $Background/MainPanel/Header/ExperienceBar
@onready var talent_points_label: Label = $Background/MainPanel/Header/TalentPointsLabel
@onready var talent_grid: GridContainer = $Background/MainPanel/ScrollContainer/TalentGrid
@onready var back_button: Button = $Background/MainPanel/Footer/BackButton
@onready var reset_button: Button = $Background/MainPanel/Footer/ResetButton
@onready var play_button: Button = $Background/MainPanel/Footer/PlayButton

# Récupération des boutons individuels depuis la scène
@onready var force_button: Button = $Background/MainPanel/ScrollContainer/TalentGrid/Force
@onready var dmg_button: Button = $Background/MainPanel/ScrollContainer/TalentGrid/dmg
@onready var crit_button: Button = $Background/MainPanel/ScrollContainer/TalentGrid/crit
@onready var speed_button: Button = $Background/MainPanel/ScrollContainer/TalentGrid/speed
@onready var hp_button: Button = $Background/MainPanel/ScrollContainer/TalentGrid/hp
@onready var hp2_button: Button = $Background/MainPanel/ScrollContainer/TalentGrid/hp2

# Variables du système
var current_character_id: int = 0
var talent_points: int = 10  # Points de départ
var level: int = 1
var experience: int = 0
var experience_needed: int = 100

# Stats du personnage (niveaux des talents)
var character_stats: Dictionary = {
	"force": 0,        # Force (dégâts)
	"damage": 0,       # Dégâts supplémentaires
	"crit": 0,         # Chance critique
	"speed": 0,        # Vitesse
	"hp": 0,           # Vie
	"hp2": 0,          # Vie supplémentaire
	"multishot": 0,    # Tir multiple
	"pierce": 0,       # Pénétration
	"fire_rate": 0,    # Cadence
	"armor": 0         # Armure
}

# Coûts des talents (peut varier selon le niveau)
var talent_costs: Dictionary = {
	"force": 1,
	"damage": 2,
	"crit": 3,
	"speed": 1,
	"hp": 1,
	"hp2": 2,
	"multishot": 4,
	"pierce": 3,
	"fire_rate": 2,
	"armor": 2
}

# Valeurs par niveau des talents
var talent_values: Dictionary = {
	"force": 8,          # +8 dégâts par niveau
	"damage": 12,        # +12 dégâts par niveau
	"crit": 10,          # +10% critique par niveau
	"speed": 15,         # +15 vitesse par niveau
	"hp": 25,            # +25 HP par niveau
	"hp2": 40,           # +40 HP par niveau
	"multishot": 1,      # +1 projectile par niveau
	"pierce": 1,         # +1 pénétration par niveau
	"fire_rate": 15,     # +15% cadence par niveau
	"armor": 8           # +8% armure par niveau
}

# Limites maximales
var talent_max_levels: Dictionary = {
	"force": 10,
	"damage": 5,
	"crit": 5,
	"speed": 8,
	"hp": 10,
	"hp2": 5,
	"multishot": 3,
	"pierce": 5,
	"fire_rate": 6,
	"armor": 5
}

func _ready():
	print("🌟 Simple Talent Tree ready")
	
	# Récupérer le personnage sélectionné
	current_character_id = GlobalData.selected_character_id
	
	# Charger les données sauvegardées
	load_character_data()
	
	# Connecter les signaux
	connect_signals()
	
	# Configurer l'interface
	setup_ui()
	
	# Mettre à jour l'affichage
	update_ui()

func connect_signals():
	# Boutons principaux
	back_button.pressed.connect(_on_back_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	play_button.pressed.connect(_on_play_button_pressed)
	
	# Boutons de talents individuels
	force_button.pressed.connect(_on_talent_upgrade.bind("force"))
	dmg_button.pressed.connect(_on_talent_upgrade.bind("damage"))
	crit_button.pressed.connect(_on_talent_upgrade.bind("crit"))
	speed_button.pressed.connect(_on_talent_upgrade.bind("speed"))
	hp_button.pressed.connect(_on_talent_upgrade.bind("hp"))
	hp2_button.pressed.connect(_on_talent_upgrade.bind("hp2"))
	
	print("✅ Signals connected")

func setup_ui():
	# Configurer le background
	background.color = Color(0, 0, 0, 0.8)
	
	# Configurer les textes des boutons
	back_button.text = "◀ Retour"
	reset_button.text = "🔄 Reset"
	play_button.text = "▶ Jouer"
	
	print("✅ UI configured")

func update_ui():
	# Mettre à jour les labels d'en-tête
	var character_data = GlobalData.get_character_data(current_character_id)
	character_name_label.text = character_data.name + " - Talents"
	level_label.text = "Niveau " + str(level)
	talent_points_label.text = "Points de talents: " + str(talent_points)
	
	# Mettre à jour la barre d'expérience
	var exp_percentage = float(experience) / float(experience_needed) * 100
	experience_bar.value = exp_percentage
	experience_bar.tooltip_text = str(experience) + "/" + str(experience_needed) + " XP"
	
	# Mettre à jour chaque bouton de talent
	update_talent_button(force_button, "force", "Force", "Augmente les dégâts")
	update_talent_button(dmg_button, "damage", "Dégâts", "Dégâts supplémentaires")
	update_talent_button(crit_button, "crit", "Critique", "Chance de critique")
	update_talent_button(speed_button, "speed", "Vitesse", "Vitesse de déplacement")
	update_talent_button(hp_button, "hp", "Vie", "Points de vie")
	update_talent_button(hp2_button, "hp2", "Vie+", "Vie supplémentaire")

func update_talent_button(button: Button, stat_name: String, display_name: String, description: String):
	if not button:
		return
	
	var current_level = character_stats[stat_name]
	var max_level = talent_max_levels[stat_name]
	var cost = talent_costs[stat_name]
	var value = talent_values[stat_name]
	
	# Texte du bouton
	var button_text = display_name + "\n"
	button_text += "Niveau: " + str(current_level) + "/" + str(max_level) + "\n"
	button_text += description + "\n"
	button_text += "Coût: " + str(cost) + " pts\n"
	button_text += "Effet: +" + str(value) + get_effect_unit(stat_name)
	
	button.text = button_text
	
	# Couleur et état du bouton
	if current_level >= max_level:
		# Talent au maximum
		button.modulate = Color.GOLD
		button.disabled = true
	elif talent_points >= cost:
		# Peut être amélioré
		button.modulate = Color.GREEN
		button.disabled = false
	else:
		# Pas assez de points
		button.modulate = Color.RED
		button.disabled = true
	
	# Tooltip détaillé
	var tooltip = description + "\n\n"
	tooltip += "Niveau actuel: " + str(current_level) + "/" + str(max_level) + "\n"
	tooltip += "Effet par niveau: +" + str(value) + get_effect_unit(stat_name) + "\n"
	tooltip += "Coût: " + str(cost) + " points de talents\n"
	tooltip += "Effet total: +" + str(value * current_level) + get_effect_unit(stat_name)
	
	button.tooltip_text = tooltip

func get_effect_unit(stat_name: String) -> String:
	match stat_name:
		"force", "damage":
			return " dégâts"
		"crit":
			return "% critique"
		"speed":
			return " vitesse"
		"hp", "hp2":
			return " HP"
		"multishot":
			return " projectile"
		"pierce":
			return " pénétration"
		"fire_rate":
			return "% cadence"
		"armor":
			return "% armure"
		_:
			return ""

func _on_talent_upgrade(stat_name: String):
	print("🌟 Trying to upgrade: ", stat_name)
	
	var current_level = character_stats[stat_name]
	var max_level = talent_max_levels[stat_name]
	var cost = talent_costs[stat_name]
	
	# Vérifications
	if current_level >= max_level:
		print("❌ Talent already at max level")
		return
	
	if talent_points < cost:
		print("❌ Not enough talent points")
		return
	
	# Appliquer l'amélioration
	character_stats[stat_name] += 1
	talent_points -= cost
	
	# Effet visuel
	create_upgrade_effect(stat_name)
	
	# Sauvegarder
	save_character_data()
	
	# Mettre à jour l'affichage
	update_ui()
	
	print("✅ Upgraded ", stat_name, " to level ", character_stats[stat_name])

func create_upgrade_effect(stat_name: String):
	# Trouver le bouton correspondant
	var button: Button = null
	match stat_name:
		"force": button = force_button
		"damage": button = dmg_button
		"crit": button = crit_button
		"speed": button = speed_button
		"hp": button = hp_button
		"hp2": button = hp2_button
	
	if not button:
		return
	
	# Effet de scale et couleur
	var original_scale = button.scale
	var original_modulate = button.modulate
	
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 1.2, 0.15)
	tween.parallel().tween_property(button, "modulate", Color.YELLOW, 0.15)
	tween.tween_property(button, "scale", original_scale, 0.15)
	tween.parallel().tween_property(button, "modulate", original_modulate, 0.15)

func _on_back_button_pressed():
	print("🔙 Back to character selection")
	save_character_data()
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelection.tscn")

func _on_reset_button_pressed():
	print("🔄 Reset button pressed")
	
	# Demander confirmation
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Êtes-vous sûr de vouloir réinitialiser tous les talents ?"
	confirmation.title = "Confirmation"
	add_child(confirmation)
	confirmation.popup_centered()
	
	# Connecter la confirmation
	confirmation.confirmed.connect(_on_reset_confirmed.bind(confirmation))

func _on_reset_confirmed(dialog: ConfirmationDialog):
	# Calculer les points à rembourser
	var points_to_refund = 0
	for stat_name in character_stats.keys():
		var level = character_stats[stat_name]
		var cost = talent_costs[stat_name]
		points_to_refund += level * cost
	
	# Réinitialiser
	for stat_name in character_stats.keys():
		character_stats[stat_name] = 0
	
	talent_points += points_to_refund
	
	# Sauvegarder et mettre à jour
	save_character_data()
	update_ui()
	
	dialog.queue_free()
	print("✅ Talents reset! Refunded ", points_to_refund, " points")

func _on_play_button_pressed():
	print("▶ Starting game with talents")
	
	# Sauvegarder avant de partir
	save_character_data()
	
	# Appliquer les talents au joueur via GlobalData
	apply_talents_to_global_data()
	
	get_tree().change_scene_to_file("res://scenes/levels/TestLevel.tscn")

func apply_talents_to_global_data():
	# Créer les bonus à appliquer au joueur
	var talent_bonuses = {
		"damage_bonus": (character_stats.force * talent_values.force) + (character_stats.damage * talent_values.damage),
		"health_bonus": (character_stats.hp * talent_values.hp) + (character_stats.hp2 * talent_values.hp2),
		"speed_bonus": character_stats.speed * talent_values.speed,
		"crit_chance": character_stats.crit * (talent_values.crit / 100.0),
		"multishot": character_stats.multishot,
		"pierce": character_stats.pierce,
		"fire_rate_bonus": character_stats.fire_rate * (talent_values.fire_rate / 100.0),
		"armor_bonus": character_stats.armor * (talent_values.armor / 100.0)
	}
	
	# Sauvegarder dans GlobalData
	GlobalData.set_meta("current_talent_bonuses", talent_bonuses)
	
	print("✅ Talents applied to GlobalData: ", talent_bonuses)

# === SAUVEGARDE ET CHARGEMENT ===
func save_character_data():
	var save_data = {
		"level": level,
		"experience": experience,
		"experience_needed": experience_needed,
		"talent_points": talent_points,
		"character_stats": character_stats
	}
	
	var save_file = FileAccess.open("user://talent_data_" + str(current_character_id) + ".save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("💾 Character data saved")

func load_character_data():
	var save_path = "user://talent_data_" + str(current_character_id) + ".save"
	
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var save_data = json.data
				
				level = save_data.get("level", 1)
				experience = save_data.get("experience", 0)
				experience_needed = save_data.get("experience_needed", 100)
				talent_points = save_data.get("talent_points", 10)
				character_stats = save_data.get("character_stats", character_stats)
				
				print("💾 Character data loaded")
				return
	
	print("📁 No save file found, using defaults")

# === FONCTION POUR GAGNER DE L'XP (appelée depuis le jeu) ===
func gain_experience(amount: int):
	experience += amount
	
	# Vérifier level up
	while experience >= experience_needed:
		experience -= experience_needed
		level_up()
	
	save_character_data()
	update_ui()

func level_up():
	level += 1
	experience_needed = int(experience_needed * 1.2)
	
	# Gagner des points de talents
	talent_points += 2
	
	print("🎉 LEVEL UP! Level ", level, " | +2 talent points")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

# === FONCTION POUR APPLIQUER LES TALENTS AU JOUEUR ===
# Cette fonction sera appelée depuis TestLevel.gd
func apply_talents_to_player(player: Player):
	if not player:
		return
	
	# Appliquer les bonus de dégâts
	var damage_bonus = (character_stats.force * talent_values.force) + (character_stats.damage * talent_values.damage)
	player.damage += damage_bonus
	
	# Appliquer les bonus de vie
	var health_bonus = (character_stats.hp * talent_values.hp) + (character_stats.hp2 * talent_values.hp2)
	player.max_health += health_bonus
	player.current_health += health_bonus
	
	# Appliquer les bonus de vitesse
	var speed_bonus = character_stats.speed * talent_values.speed
	player.speed += speed_bonus
	
	# Appliquer les bonus via métadonnées
	var crit_chance = character_stats.crit * (talent_values.crit / 100.0)
	player.set_meta("crit_chance", crit_chance)
	
	var fire_rate_bonus = character_stats.fire_rate * (talent_values.fire_rate / 100.0)
	player.set_meta("fire_rate_boost", fire_rate_bonus)
	
	var armor_bonus = character_stats.armor * (talent_values.armor / 100.0)
	player.set_meta("damage_reduction", armor_bonus)
	
	player.set_meta("extra_projectiles", character_stats.multishot)
	player.set_meta("penetration_bonus", character_stats.pierce)
	
	print("✅ Talents applied to player successfully!")
	print("   Damage: +", damage_bonus)
	print("   Health: +", health_bonus)
	print("   Speed: +", speed_bonus)
	print("   Crit: +", crit_chance * 100, "%")
	print("   Multishot: +", character_stats.multishot)
	print("   Pierce: +", character_stats.pierce)
