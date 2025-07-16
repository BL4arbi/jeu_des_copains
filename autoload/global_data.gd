# GlobalData.gd - Version corrigée sans erreur
extends Node

var selected_character_id: int = 0
var current_level: int = 1
var total_kills: int = 0
var player_stats: Dictionary = {}
var characters_data: Array = []

# NOUVEAU : Statistiques détaillées
var elite_kills: int = 0
var boss_kills: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0
var time_survived: float = 0.0

# Signaux
signal kill_count_updated(new_count: int)
signal enemy_killed(enemy_type: String, position: Vector2)
signal elite_killed(position: Vector2)
signal boss_killed(position: Vector2)

func _ready():
	load_characters_data()

func load_characters_data():
	characters_data = [
		{
			"id": 0,
			"name": "Guerrier",
			"health": 120,
			"speed": 200,
			"damage": 25,
			"sprite_path": "res://assets/SPRITES/character/fantome festif.png",
			"description": "Personnage équilibré avec bonus de survie"
		},
		{
			"id": 1,
			"name": "Archer",
			"health": 80,
			"speed": 280,
			"damage": 30,
			"sprite_path": "res://assets/tiles/TOP_DOWN_PLAYER_NEW.png",
			"description": "Rapide mais fragile - bonus de vitesse"
		},
		{
			"id": 2,
			"name": "Mage",
			"health": 70,
			"speed": 150,
			"damage": 40,
			"sprite_path": "res://assets/SPRITES/character/VAISSEAU 1.png",
			"description": "Lent mais puissant - bonus de dégâts"
		}
	]

func select_character(character_id: int):
	selected_character_id = character_id
	player_stats = characters_data[character_id].duplicate()
	
	# CORRECTION : Vérifier si PlayerProgression existe AVANT de l'utiliser
	await get_tree().process_frame  # Attendre une frame pour que tous les autoloads soient prêts
	
	if has_node("/root/PlayerProgression"):
		var progression = get_node("/root/PlayerProgression")
		if progression.has_method("get_current_stats"):
			var current_stats = progression.get_current_stats()
			player_stats.health = current_stats.health
			player_stats.speed = current_stats.speed
			player_stats.damage = current_stats.damage
			print("✅ Progression stats applied to character")
		else:
			print("⚠️ PlayerProgression exists but missing get_current_stats method")
	else:
		print("⚠️ PlayerProgression not found, using base character stats")

func add_kill(enemy_type: String = "basic"):
	total_kills += 1
	
	# Compter les types spéciaux
	match enemy_type:
		"Elite":
			elite_kills += 1
			elite_killed.emit(Vector2.ZERO)
		"Boss":
			boss_kills += 1
			boss_killed.emit(Vector2.ZERO)
	var exp_gain = 0
	match enemy_type:
		"basic", "Grunt":
			exp_gain = 15
		"Shooter":
			exp_gain = 25
		"Elite":
			exp_gain = 50
		"Armored":
			exp_gain = 20
		_:
			exp_gain = 10
	
	gain_experience(exp_gain)
	kill_count_updated.emit(total_kills)
	print("📊 Total kills: ", total_kills, " (Elite: ", elite_kills, ", Boss: ", boss_kills, ")")

func add_damage_dealt(amount: float):
	damage_dealt += amount

func add_damage_taken(amount: float):
	damage_taken += amount

func add_survival_time(time: float):
	time_survived += time

func get_character_data(character_id: int) -> Dictionary:
	if character_id < characters_data.size():
		return characters_data[character_id]
	return {}

# NOUVEAU : Méthodes pour les statistiques
func get_kill_statistics() -> Dictionary:
	return {
		"total_kills": total_kills,
		"elite_kills": elite_kills,
		"boss_kills": boss_kills,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"time_survived": time_survived,
		"kills_per_minute": (total_kills / max(time_survived / 60.0, 0.1)),
		"damage_per_kill": (damage_dealt / max(total_kills, 1))
	}

func reset_progression():
	total_kills = 0
	elite_kills = 0
	boss_kills = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	time_survived = 0.0
	
	print("🔄 Progression reset")

# Sauvegarde simple (à améliorer plus tard)
func save_progress():
	var save_data = {
		"total_kills": total_kills,
		"elite_kills": elite_kills,
		"boss_kills": boss_kills,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"time_survived": time_survived
	}
	
	# TODO: Implémenter vraie sauvegarde
	print("💾 Progress saved: ", save_data)

func load_progress():
	# TODO: Implémenter vraie sauvegarde
	print("📁 Progress loaded") 
var talent_points: int = 5  # Points de départ pour tester
var experience: int = 0
var experience_needed: int = 100
var current_character_talents: Dictionary = {}
var current_character_talent_tree: Dictionary = {}

# Signal pour les talents
signal talent_points_changed(new_points: int)
signal experience_gained(amount: int)

# === AJOUTER CES FONCTIONS DANS GlobalData.gd ===

func gain_experience(amount: int):
	experience += amount
	experience_gained.emit(amount)
	
	# Vérifier level up
	while experience >= experience_needed:
		experience -= experience_needed
		level_up()
		experience_needed = int(experience_needed * 1.2)

func level_up():
	current_level += 1
	
	# Gagner des points de talents
	var talent_points_gained = 2
	gain_talent_points(talent_points_gained)
	
	print("🎉 LEVEL UP! Level ", current_level, " | Gained ", talent_points_gained, " talent points")

func gain_talent_points(amount: int):
	talent_points += amount
	talent_points_changed.emit(talent_points)
	print("🌟 Gained ", amount, " talent points! Total: ", talent_points)



func apply_talents_to_player(player: Player):
	if current_character_talents.is_empty():
		print("⚠️ No talents to apply")
		return
	
	print("🌟 Applying talents to player...")
	
	# Appliquer chaque talent
	for talent_id in current_character_talents.keys():
		var talent_state = current_character_talents[talent_id]
		var talent_level = talent_state.level
		
		if talent_level > 0:
			var talent_data = get_talent_data_by_id(talent_id)
			if talent_data:
				apply_talent_effect(player, talent_data, talent_level)

func get_talent_data_by_id(talent_id: String) -> Dictionary:
	if current_character_talent_tree.has("talents"):
		for talent_data in current_character_talent_tree.talents:
			if talent_data.id == talent_id:
				return talent_data
	return {}

func apply_talent_effect(player: Player, talent_data: Dictionary, level: int):
	var effect_type = talent_data.effect
	var effect_value = talent_data.value * level
	
	match effect_type:
		"damage":
			player.damage += effect_value
			print("💪 Talent damage: +", effect_value)
		
		"health":
			player.max_health += effect_value
			player.current_health += effect_value
			print("❤️ Talent health: +", effect_value)
		
		"speed":
			player.speed += effect_value
			print("⚡ Talent speed: +", effect_value)
		
		"armor":
			var current_armor = player.get_meta("damage_reduction", 0.0)
			player.set_meta("damage_reduction", current_armor + effect_value)
			print("🛡️ Talent armor: +", effect_value * 100, "%")
		
		"fire_rate":
			var current_fire_rate = player.get_meta("fire_rate_boost", 0.0)
			player.set_meta("fire_rate_boost", current_fire_rate + effect_value)
			print("🔫 Talent fire rate: +", effect_value * 100, "%")
		
		"crit_chance":
			var current_crit = player.get_meta("crit_chance", 0.0)
			player.set_meta("crit_chance", current_crit + effect_value)
			print("💥 Talent crit chance: +", effect_value * 100, "%")
		
		"lifesteal":
			var current_lifesteal = player.get_meta("lifesteal", 0.0)
			player.set_meta("lifesteal", current_lifesteal + effect_value)
			print("🧛 Talent lifesteal: +", effect_value * 100, "%")
		
		"multishot":
			var current_multishot = player.get_meta("extra_projectiles", 0)
			player.set_meta("extra_projectiles", current_multishot + int(effect_value))
			print("🎯 Talent multishot: +", int(effect_value))
		
		"pierce":
			var current_pierce = player.get_meta("penetration_bonus", 0)
			player.set_meta("penetration_bonus", current_pierce + int(effect_value))
			print("🏹 Talent pierce: +", int(effect_value))
		
		"range":
			var current_range = player.get_meta("range_bonus", 1.0)
			player.set_meta("range_bonus", current_range + effect_value)
			print("🎯 Talent range: +", effect_value * 100, "%")
		
		"fire_bullets":
			var current_fire = player.get_meta("fire_damage_percent", 0.0)
			player.set_meta("fire_damage_percent", current_fire + (effect_value * 0.02))
			print("🔥 Talent fire bullets: +", effect_value * 2, "% HP as fire damage")
		
		"ice_bullets":
			var current_ice = player.get_meta("ice_slow_power", 0.0)
			player.set_meta("ice_slow_power", current_ice + (effect_value * 0.15))
			print("❄️ Talent ice bullets: +", effect_value * 15, "% slow")
		
		"lightning_bullets":
			var current_lightning = player.get_meta("lightning_stun_duration", 0.0)
			player.set_meta("lightning_stun_duration", current_lightning + (effect_value * 0.5))
			print("⚡ Talent lightning bullets: +", effect_value * 0.5, "s stun")
		
		"special":
			apply_special_talent_effect(player, talent_data.id, level)

func apply_special_talent_effect(player: Player, talent_id: String, level: int):
	match talent_id:
		"warrior_berserker":
			player.set_meta("berserker_mode", true)
			print("🔥 Berserker mode activated!")
		
		"warrior_guardian":
			player.set_meta("health_regen", 2.0)
			print("🛡️ Guardian regeneration activated!")
		
		"archer_volley":
			player.set_meta("volley_shots", 5)
			print("🏹 Volley shots activated!")
		
		"archer_sniper":
			var current_crit_damage = player.get_meta("crit_damage_multiplier", 1.5)
			player.set_meta("crit_damage_multiplier", current_crit_damage + 2.0)
			print("🎯 Sniper mode activated!")
		
		"mage_meteor":
			player.set_meta("meteor_rain_chance", 0.1)
			print("☄️ Meteor rain activated!")
		
		"mage_arcane":
			player.set_meta("fire_damage_percent", 0.03)
			player.set_meta("ice_slow_power", 0.25)
			player.set_meta("lightning_stun_duration", 1.0)
			print("🔮 Arcane mastery activated!")



# === FONCTION POUR RÉINITIALISER LES DONNÉES DE TALENTS ===

func reset_talent_data():
	talent_points = 5
	experience = 0
	experience_needed = 100
	current_character_talents.clear()
	current_character_talent_tree.clear()
	print("🔄 Talent data reset")

# === FONCTION POUR SAUVEGARDER/CHARGER LES TALENTS ===

func save_talent_data() -> Dictionary:
	return {
		"talent_points": talent_points,
		"experience": experience,
		"experience_needed": experience_needed,
		"current_character_talents": current_character_talents,
		"current_character_talent_tree": current_character_talent_tree
	}

func load_talent_data(data: Dictionary):
	talent_points = data.get("talent_points", 5)
	experience = data.get("experience", 0)
	experience_needed = data.get("experience_needed", 100)
	current_character_talents = data.get("current_character_talents", {})
	current_character_talent_tree = data.get("current_character_talent_tree", {})
	
	print("💾 Talent data loaded")
