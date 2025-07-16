# TalentManager.gd - Système complet de talents avec sauvegarde
extends Node

# Données par personnage
var character_data: Dictionary = {
	0: {  # Guerrier
		"name": "Guerrier",
		"level": 1,
		"experience": 0,
		"experience_needed": 100,
		"talent_points": 10,  # Points de départ pour tester
		"talents": {},
		"stats_bonuses": {
			"damage": 0,
			"health": 0,
			"speed": 0,
			"armor": 0.0,
			"fire_rate": 0.0,
			"crit_chance": 0.0,
			"lifesteal": 0.0
		}
	},
	1: {  # Archer
		"name": "Archer",
		"level": 1,
		"experience": 0,
		"experience_needed": 100,
		"talent_points": 10,
		"talents": {},
		"stats_bonuses": {
			"damage": 0,
			"health": 0,
			"speed": 0,
			"armor": 0.0,
			"fire_rate": 0.0,
			"crit_chance": 0.0,
			"multishot": 0,
			"pierce": 0
		}
	},
	2: {  # Mage
		"name": "Mage",
		"level": 1,
		"experience": 0,
		"experience_needed": 100,
		"talent_points": 10,
		"talents": {},
		"stats_bonuses": {
			"damage": 0,
			"health": 0,
			"speed": 0,
			"armor": 0.0,
			"fire_rate": 0.0,
			"crit_chance": 0.0,
			"magic_damage": 0.0
		}
	}
}

# Arbres de talents par classe
var talent_trees: Dictionary = {
	0: {  # Guerrier
		"damage_1": {"name": "Force I", "desc": "Dégâts +8", "cost": 1, "max": 5, "effect": "damage", "value": 8, "prereq": []},
		"health_1": {"name": "Vitalité I", "desc": "Vie +30", "cost": 1, "max": 5, "effect": "health", "value": 30, "prereq": []},
		"armor_1": {"name": "Résistance I", "desc": "Armure +6%", "cost": 1, "max": 5, "effect": "armor", "value": 0.06, "prereq": []},
		
		"damage_2": {"name": "Force II", "desc": "Dégâts +12", "cost": 2, "max": 3, "effect": "damage", "value": 12, "prereq": ["damage_1"]},
		"crit_1": {"name": "Précision", "desc": "Critique +10%", "cost": 2, "max": 3, "effect": "crit_chance", "value": 0.1, "prereq": ["damage_1"]},
		"lifesteal_1": {"name": "Vol de vie", "desc": "Vol de vie +4%", "cost": 2, "max": 3, "effect": "lifesteal", "value": 0.04, "prereq": ["health_1"]},
		"armor_2": {"name": "Résistance II", "desc": "Armure +10%", "cost": 2, "max": 3, "effect": "armor", "value": 0.1, "prereq": ["armor_1"]},
		
		"berserker": {"name": "Berserker", "desc": "Dégâts +50% à faible vie", "cost": 3, "max": 1, "effect": "special", "value": 1, "prereq": ["damage_2", "crit_1"]},
		"guardian": {"name": "Gardien", "desc": "Régénération +3 HP/s", "cost": 3, "max": 1, "effect": "special", "value": 1, "prereq": ["lifesteal_1", "armor_2"]},
	},
	
	1: {  # Archer
		"speed_1": {"name": "Agilité I", "desc": "Vitesse +20", "cost": 1, "max": 5, "effect": "speed", "value": 20, "prereq": []},
		"fire_rate_1": {"name": "Cadence I", "desc": "Cadence +18%", "cost": 1, "max": 5, "effect": "fire_rate", "value": 0.18, "prereq": []},
		"damage_1": {"name": "Tir précis", "desc": "Dégâts +6", "cost": 1, "max": 5, "effect": "damage", "value": 6, "prereq": []},
		
		"speed_2": {"name": "Agilité II", "desc": "Vitesse +30", "cost": 2, "max": 3, "effect": "speed", "value": 30, "prereq": ["speed_1"]},
		"multishot_1": {"name": "Tir multiple", "desc": "+1 projectile", "cost": 2, "max": 3, "effect": "multishot", "value": 1, "prereq": ["fire_rate_1"]},
		"pierce_1": {"name": "Perçant", "desc": "+1 pénétration", "cost": 2, "max": 3, "effect": "pierce", "value": 1, "prereq": ["damage_1"]},
		"crit_1": {"name": "Œil de faucon", "desc": "Critique +15%", "cost": 2, "max": 3, "effect": "crit_chance", "value": 0.15, "prereq": ["damage_1"]},
		
		"volley": {"name": "Volée", "desc": "Tire 5 flèches", "cost": 3, "max": 1, "effect": "special", "value": 1, "prereq": ["multishot_1", "speed_2"]},
		"sniper": {"name": "Sniper", "desc": "Critiques +200%", "cost": 3, "max": 1, "effect": "special", "value": 1, "prereq": ["pierce_1", "crit_1"]},
	},
	
	2: {  # Mage
		"magic_1": {"name": "Magie I", "desc": "Dégâts +10", "cost": 1, "max": 5, "effect": "damage", "value": 10, "prereq": []},
		"mana_1": {"name": "Mana I", "desc": "Cadence +25%", "cost": 1, "max": 5, "effect": "fire_rate", "value": 0.25, "prereq": []},
		"shield_1": {"name": "Bouclier I", "desc": "Armure +8%", "cost": 1, "max": 5, "effect": "armor", "value": 0.08, "prereq": []},
		
		"magic_2": {"name": "Magie II", "desc": "Dégâts +15", "cost": 2, "max": 3, "effect": "damage", "value": 15, "prereq": ["magic_1"]},
		"fire_magic": {"name": "Magie de feu", "desc": "Projectiles brûlent", "cost": 2, "max": 3, "effect": "fire_bullets", "value": 1, "prereq": ["magic_1"]},
		"ice_magic": {"name": "Magie de glace", "desc": "Projectiles ralentissent", "cost": 2, "max": 3, "effect": "ice_bullets", "value": 1, "prereq": ["mana_1"]},
		"lightning_magic": {"name": "Foudre", "desc": "Chaînes électriques", "cost": 2, "max": 3, "effect": "lightning_bullets", "value": 1, "prereq": ["shield_1"]},
		
		"meteor": {"name": "Météore", "desc": "Déclenche météores", "cost": 3, "max": 1, "effect": "special", "value": 1, "prereq": ["fire_magic", "magic_2"]},
		"arcane_master": {"name": "Maître arcane", "desc": "Tous les effets magiques", "cost": 3, "max": 1, "effect": "special", "value": 1, "prereq": ["ice_magic", "lightning_magic"]},
	}
}

# Fichier de sauvegarde
const SAVE_FILE = "user://talent_progress.save"

# Signaux
signal level_up(character_id: int, new_level: int)
signal talent_points_changed(character_id: int, new_points: int)
signal experience_gained(character_id: int, amount: int)

func _ready():
	add_to_group("talent_manager")
	load_progress()
	print("🌟 Talent Manager initialized")

# === GESTION DE L'EXPÉRIENCE ===
func gain_experience(character_id: int, amount: int):
	if not character_data.has(character_id):
		return
	
	var char_data = character_data[character_id]
	char_data.experience += amount
	
	print("📈 Character ", char_data.name, " gained ", amount, " XP")
	
	# Vérifier level up
	while char_data.experience >= char_data.experience_needed:
		char_data.experience -= char_data.experience_needed
		level_up_character(character_id)
	
	experience_gained.emit(character_id, amount)
	save_progress()

func level_up_character(character_id: int):
	var char_data = character_data[character_id]
	char_data.level += 1
	char_data.experience_needed = int(char_data.experience_needed * 1.2)
	
	# Gagner des points de talents
	var talent_points_gain = 2
	char_data.talent_points += talent_points_gain
	
	print("🎉 ", char_data.name, " LEVEL UP! Level ", char_data.level, " | +", talent_points_gain, " talent points")
	
	level_up.emit(character_id, char_data.level)
	talent_points_changed.emit(character_id, char_data.talent_points)

# === GESTION DES TALENTS ===
func upgrade_talent(character_id: int, talent_id: String) -> bool:
	if not can_upgrade_talent(character_id, talent_id):
		return false
	
	var char_data = character_data[character_id]
	var talent_data = talent_trees[character_id][talent_id]
	
	# Initialiser le talent s'il n'existe pas
	if not char_data.talents.has(talent_id):
		char_data.talents[talent_id] = {"level": 0, "unlocked": false}
	
	# Dépenser les points
	char_data.talent_points -= talent_data.cost
	char_data.talents[talent_id].level += 1
	
	# Appliquer l'effet
	apply_talent_effect(character_id, talent_id, talent_data)
	
	# Débloquer de nouveaux talents
	check_unlock_talents(character_id)
	
	print("✨ Upgraded ", talent_data.name, " to level ", char_data.talents[talent_id].level)
	
	save_progress()
	return true

func can_upgrade_talent(character_id: int, talent_id: String) -> bool:
	if not character_data.has(character_id) or not talent_trees[character_id].has(talent_id):
		return false
	
	var char_data = character_data[character_id]
	var talent_data = talent_trees[character_id][talent_id]
	
	# Initialiser le talent s'il n'existe pas
	if not char_data.talents.has(talent_id):
		char_data.talents[talent_id] = {"level": 0, "unlocked": talent_data.prereq.is_empty()}
	
	var talent_state = char_data.talents[talent_id]
	
	# Vérifications
	if not talent_state.unlocked:
		return false
	if talent_state.level >= talent_data.max:
		return false
	if char_data.talent_points < talent_data.cost:
		return false
	
	return true

func apply_talent_effect(character_id: int, talent_id: String, talent_data: Dictionary):
	var char_data = character_data[character_id]
	var effect_type = talent_data.effect
	var effect_value = talent_data.value
	
	# Appliquer aux bonus de stats
	match effect_type:
		"damage":
			char_data.stats_bonuses.damage += effect_value
		"health":
			char_data.stats_bonuses.health += effect_value
		"speed":
			char_data.stats_bonuses.speed += effect_value
		"armor":
			char_data.stats_bonuses.armor += effect_value
		"fire_rate":
			char_data.stats_bonuses.fire_rate += effect_value
		"crit_chance":
			char_data.stats_bonuses.crit_chance += effect_value
		"lifesteal":
			char_data.stats_bonuses.lifesteal += effect_value
		"multishot":
			char_data.stats_bonuses.multishot += effect_value
		"pierce":
			char_data.stats_bonuses.pierce += effect_value
		"fire_bullets", "ice_bullets", "lightning_bullets":
			char_data.stats_bonuses[effect_type] = effect_value
		"special":
			char_data.stats_bonuses["special_" + talent_id] = effect_value

func check_unlock_talents(character_id: int):
	var char_data = character_data[character_id]
	var talents = talent_trees[character_id]
	
	for talent_id in talents.keys():
		if not char_data.talents.has(talent_id):
			char_data.talents[talent_id] = {"level": 0, "unlocked": false}
		
		var talent_state = char_data.talents[talent_id]
		var talent_data = talents[talent_id]
		
		if talent_state.unlocked:
			continue
		
		# Vérifier les prérequis
		var can_unlock = true
		for prereq_id in talent_data.prereq:
			if not char_data.talents.has(prereq_id) or char_data.talents[prereq_id].level == 0:
				can_unlock = false
				break
		
		if can_unlock:
			talent_state.unlocked = true
			print("🔓 Talent unlocked: ", talent_data.name)

# === APPLICATION AU JOUEUR ===
func apply_talents_to_player(player: Player, character_id: int):
	if not character_data.has(character_id):
		return
	
	var char_data = character_data[character_id]
	var bonuses = char_data.stats_bonuses
	
	print("🌟 Applying talents to ", char_data.name)
	
	# Appliquer les bonus de stats
	player.damage += bonuses.damage
	player.max_health += bonuses.health
	player.current_health += bonuses.health
	player.speed += bonuses.speed
	
	# Appliquer les bonus via métadonnées
	player.set_meta("damage_reduction", bonuses.armor)
	player.set_meta("fire_rate_boost", bonuses.fire_rate)
	player.set_meta("crit_chance", bonuses.crit_chance)
	player.set_meta("lifesteal", bonuses.lifesteal)
	
	# Bonus spécifiques aux archers
	if bonuses.has("multishot"):
		player.set_meta("extra_projectiles", bonuses.multishot)
	if bonuses.has("pierce"):
		player.set_meta("penetration_bonus", bonuses.pierce)
	
	# Effets magiques pour les mages
	if bonuses.has("fire_bullets"):
		player.set_meta("fire_damage_percent", bonuses.fire_bullets * 0.03)
	if bonuses.has("ice_bullets"):
		player.set_meta("ice_slow_power", bonuses.ice_bullets * 0.2)
	if bonuses.has("lightning_bullets"):
		player.set_meta("lightning_stun_duration", bonuses.lightning_bullets * 0.8)
	
	# Effets spéciaux
	apply_special_effects(player, bonuses)
	
	print("✅ Talents applied successfully")

func apply_special_effects(player: Player, bonuses: Dictionary):
	# Berserker du guerrier
	if bonuses.has("special_berserker"):
		player.set_meta("berserker_mode", true)
		print("🔥 Berserker mode activated!")
	
	# Gardien du guerrier
	if bonuses.has("special_guardian"):
		player.set_meta("health_regen", 3.0)
		print("🛡️ Guardian regeneration activated!")
	
	# Volée de l'archer
	if bonuses.has("special_volley"):
		player.set_meta("volley_shots", 5)
		print("🏹 Volley shots activated!")
	
	# Sniper de l'archer
	if bonuses.has("special_sniper"):
		var current_crit_damage = player.get_meta("crit_damage_multiplier", 1.5)
		player.set_meta("crit_damage_multiplier", current_crit_damage + 2.0)
		print("🎯 Sniper mode activated!")
	
	# Météore du mage
	if bonuses.has("special_meteor"):
		player.set_meta("meteor_rain_chance", 0.12)
		print("☄️ Meteor rain activated!")
	
	# Maître arcane du mage
	if bonuses.has("special_arcane_master"):
		player.set_meta("fire_damage_percent", 0.04)
		player.set_meta("ice_slow_power", 0.3)
		player.set_meta("lightning_stun_duration", 1.2)
		print("🔮 Arcane mastery activated!")

# === SAUVEGARDE ET CHARGEMENT ===
func save_progress():
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(character_data))
		save_file.close()
		print("💾 Progress saved")
	else:
		print("❌ Failed to save progress")

func load_progress():
	if FileAccess.file_exists(SAVE_FILE):
		var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var saved_data = json.data
				
				# Fusionner les données sauvegardées avec les données par défaut
				for char_id in saved_data.keys():
					if character_data.has(int(char_id)):
						merge_character_data(int(char_id), saved_data[char_id])
				
				print("💾 Progress loaded")
				return
	
	print("📁 No save file found, using defaults")

func merge_character_data(char_id: int, saved_data: Dictionary):
	var char_data = character_data[char_id]
	
	# Mettre à jour les données sauvegardées
	char_data.level = saved_data.get("level", 1)
	char_data.experience = saved_data.get("experience", 0)
	char_data.experience_needed = saved_data.get("experience_needed", 100)
	char_data.talent_points = saved_data.get("talent_points", 10)
	char_data.talents = saved_data.get("talents", {})
	
	# Recalculer les bonus
	recalculate_stats_bonuses(char_id)

func recalculate_stats_bonuses(char_id: int):
	var char_data = character_data[char_id]
	
	# Réinitialiser les bonus
	for key in char_data.stats_bonuses.keys():
		if key.begins_with("special_"):
			char_data.stats_bonuses[key] = 0
		elif typeof(char_data.stats_bonuses[key]) == TYPE_FLOAT:
			char_data.stats_bonuses[key] = 0.0
		else:
			char_data.stats_bonuses[key] = 0
	
	# Recalculer selon les talents
	var talents = talent_trees[char_id]
	for talent_id in char_data.talents.keys():
		var talent_state = char_data.talents[talent_id]
		if talent_state.level > 0 and talents.has(talent_id):
			var talent_data = talents[talent_id]
			for i in range(talent_state.level):
				apply_talent_effect(char_id, talent_id, talent_data)

# === FONCTIONS UTILITAIRES ===
func get_character_data(character_id: int) -> Dictionary:
	return character_data.get(character_id, {})

func get_talent_data(character_id: int, talent_id: String) -> Dictionary:
	if talent_trees.has(character_id):
		return talent_trees[character_id].get(talent_id, {})
	return {}

func get_talent_level(character_id: int, talent_id: String) -> int:
	var char_data = character_data.get(character_id, {})
	if char_data.has("talents") and char_data.talents.has(talent_id):
		return char_data.talents[talent_id].level
	return 0

func reset_character_talents(character_id: int):
	if not character_data.has(character_id):
		return
	
	var char_data = character_data[character_id]
	
	# Calculer les points à rembourser
	var points_to_refund = 0
	for talent_id in char_data.talents.keys():
		var talent_state = char_data.talents[talent_id]
		if talent_state.level > 0:
			var talent_data = talent_trees[character_id][talent_id]
			points_to_refund += talent_state.level * talent_data.cost
	
	# Réinitialiser
	char_data.talents.clear()
	char_data.talent_points += points_to_refund
	
	# Recalculer les bonus
	recalculate_stats_bonuses(character_id)
	
	print("🔄 Character talents reset! Refunded ", points_to_refund, " points")
	save_progress()

# === INTÉGRATION AVEC LE SYSTÈME DE KILLS ===
func on_enemy_killed(enemy_type: String, character_id: int):
	var exp_gain = 0
	
	match enemy_type:
		"Grunt":
			exp_gain = 25
		"Shooter":
			exp_gain = 35
		"Elite":
			exp_gain = 60
		_:
			exp_gain = 20
	
	gain_experience(character_id, exp_gain)
