# PlayerProgressionSystem.gd - Système de progression complet
extends Node
class_name PlayerProgressionSystem

# Signaux pour communiquer avec les autres systèmes
signal enemy_killed(enemy_type: String, position: Vector2)
signal level_up(new_level: int)
signal stat_upgraded(stat_name: String, new_value: float)

# Variables de progression
var player_ref: Player = null
var buff_system_ref: Node = null

# Statistiques du joueur
var player_level: int = 1
var experience: int = 0
var experience_needed: int = 100
var total_kills: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0

# Multiplicateurs et bonus permanents
var permanent_stats: Dictionary = {
	"damage_multiplier": 1.0,
	"health_multiplier": 1.0,
	"speed_multiplier": 1.0,
	"fire_rate_multiplier": 1.0,
	"armor": 0.0,
	"lifesteal": 0.0,
	"extra_projectiles": 0,
	"penetration": 0,
	"crit_chance": 0.0,
	"crit_damage": 1.5
}

# Système de kills par type d'ennemi
var kill_counts: Dictionary = {
	"Grunt": 0,
	"Shooter": 0,
	"Elite": 0
}

# Valeurs d'XP par ennemi
var experience_values: Dictionary = {
	"Grunt": 10,
	"Shooter": 25,
	"Elite": 50
}

func _ready():
	add_to_group("player_progression")
	print("🎯 PlayerProgressionSystem initialized")
	
	# Trouver les références
	call_deferred("find_references")

func find_references():
	# Attendre que tout soit chargé
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Trouver le joueur
	player_ref = get_tree().get_first_node_in_group("players")
	if not player_ref:
		print("❌ Player not found in PlayerProgressionSystem")
		return
	
	# Trouver le buff system
	buff_system_ref = get_tree().get_first_node_in_group("buff_system")
	if not buff_system_ref:
		print("❌ BuffSystem not found in PlayerProgressionSystem")
		return
	
	# Connecter les signaux
	connect_signals()
	
	# Appliquer les stats de base
	apply_permanent_stats()
	
	print("✅ PlayerProgressionSystem ready and connected")

func connect_signals():
	# Connecter notre signal au BuffSystem
	if enemy_killed.connect(buff_system_ref._on_enemy_killed) != OK:
		print("❌ Failed to connect enemy_killed signal to BuffSystem")
	else:
		print("✅ Connected to BuffSystem")

# Fonction principale appelée quand un ennemi meurt
func on_enemy_killed(enemy_type: String, enemy_position: Vector2):
	# Incrémenter les compteurs
	total_kills += 1
	if kill_counts.has(enemy_type):
		kill_counts[enemy_type] += 1
	
	# Gagner de l'expérience
	var exp_gain = experience_values.get(enemy_type, 10)
	gain_experience(exp_gain)
	
	# Émettre le signal pour le BuffSystem
	enemy_killed.emit(enemy_type, enemy_position)
	
	# Progression automatique selon les kills
	check_auto_progression()
	
	print("💀 ", enemy_type, " killed! Total: ", total_kills, " | XP: +", exp_gain)

func gain_experience(amount: int):
	experience += amount
	
	# Vérifier level up
	while experience >= experience_needed:
		do_level_up()

func do_level_up():
	experience -= experience_needed
	player_level += 1
	experience_needed = int(experience_needed * 1.2)  # +20% XP needed per level
	
	# Bonus de level up
	apply_level_up_bonus()
	
	level_up.emit(player_level)
	print("🌟 LEVEL UP! Level ", player_level, " | Next: ", experience_needed, " XP")

func apply_level_up_bonus():
	if not player_ref:
		return
	
	# Bonus de vie à chaque level
	var health_bonus = 20 + (player_level * 5)
	player_ref.max_health += health_bonus
	player_ref.current_health += health_bonus
	
	# Bonus de dégâts tous les 2 niveaux
	if player_level % 2 == 0:
		var damage_bonus = 5 + player_level
		player_ref.damage += damage_bonus
		print("💪 Damage increased by ", damage_bonus)
	
	# Bonus de vitesse tous les 3 niveaux
	if player_level % 3 == 0:
		var speed_bonus = 15
		player_ref.speed += speed_bonus
		print("⚡ Speed increased by ", speed_bonus)
	
	# Bonus spéciaux tous les 5 niveaux
	if player_level % 5 == 0:
		grant_special_bonus()

func grant_special_bonus():
	# Bonus aléatoire spécial tous les 5 niveaux
	var bonuses = [
		"damage_boost",
		"fire_rate_boost", 
		"armor_boost",
		"lifesteal_boost"
	]
	
	var bonus = bonuses[randi() % bonuses.size()]
	
	match bonus:
		"damage_boost":
			permanent_stats.damage_multiplier += 0.15
			print("🔥 Permanent +15% damage!")
		"fire_rate_boost":
			permanent_stats.fire_rate_multiplier += 0.1
			print("🔫 Permanent +10% fire rate!")
		"armor_boost":
			permanent_stats.armor += 0.05
			print("🛡️ Permanent +5% armor!")
		"lifesteal_boost":
			permanent_stats.lifesteal += 0.03
			print("🧛 Permanent +3% lifesteal!")
	
	apply_permanent_stats()

func check_auto_progression():
	# Progression automatique basée sur les kills
	var total = total_kills
	
	# Bonus tous les 25 kills
	if total > 0 and total % 25 == 0:
		auto_stat_increase()
	
	# Bonus spéciaux selon le type d'ennemi
	if kill_counts.Elite >= 5 and kill_counts.Elite % 5 == 0:
		grant_elite_kill_bonus()

func auto_stat_increase():
	if not player_ref:
		return
	
	# Augmentation aléatoire de stat
	var stats = ["damage", "health", "speed"]
	var chosen_stat = stats[randi() % stats.size()]
	
	match chosen_stat:
		"damage":
			var bonus = 8 + (total_kills / 50)
			player_ref.damage += bonus
			stat_upgraded.emit("damage", player_ref.damage)
			print("💥 Auto-upgrade: +", bonus, " damage!")
		
		"health":
			var bonus = 30 + (total_kills / 25)
			player_ref.max_health += bonus
			player_ref.current_health += bonus
			stat_upgraded.emit("health", player_ref.max_health)
			print("❤️ Auto-upgrade: +", bonus, " health!")
		
		"speed":
			var bonus = 20 + (total_kills / 100)
			player_ref.speed += bonus
			stat_upgraded.emit("speed", player_ref.speed)
			print("⚡ Auto-upgrade: +", bonus, " speed!")

func grant_elite_kill_bonus():
	# Bonus spécial pour avoir tué des Elite
	permanent_stats.crit_chance += 0.02
	permanent_stats.crit_damage += 0.1
	
	apply_permanent_stats()
	print("👑 Elite kill bonus: +2% crit chance, +10% crit damage!")

func apply_permanent_stats():
	if not player_ref:
		return
	
	# Appliquer tous les bonus permanents via metadata
	for stat_name in permanent_stats.keys():
		var value = permanent_stats[stat_name]
		player_ref.set_meta(stat_name, value)
	
	# Mise à jour de l'UI si elle existe
	if player_ref.has_method("update_health_bar"):
		player_ref.update_health_bar()

# Fonctions pour ajouter des bonus permanents (appelées par BuffSystem)
func add_permanent_damage(amount: float):
	if player_ref:
		player_ref.damage += amount
		damage_dealt += amount
		print("🔥 Permanent damage: +", amount)

func add_permanent_health(amount: float):
	if player_ref:
		player_ref.max_health += amount
		player_ref.current_health += amount
		print("❤️ Permanent health: +", amount)

func add_permanent_speed(amount: float):
	if player_ref:
		player_ref.speed += amount
		print("⚡ Permanent speed: +", amount)

func add_permanent_multiplier(stat_name: String, amount: float):
	if permanent_stats.has(stat_name):
		permanent_stats[stat_name] += amount
		apply_permanent_stats()
		print("📈 Permanent ", stat_name, ": +", amount)

# Système de sauvegarde/chargement (optionnel)
func get_save_data() -> Dictionary:
	return {
		"level": player_level,
		"experience": experience,
		"experience_needed": experience_needed,
		"total_kills": total_kills,
		"kill_counts": kill_counts,
		"permanent_stats": permanent_stats,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken
	}

func load_save_data(data: Dictionary):
	player_level = data.get("level", 1)
	experience = data.get("experience", 0)
	experience_needed = data.get("experience_needed", 100)
	total_kills = data.get("total_kills", 0)
	kill_counts = data.get("kill_counts", {"Grunt": 0, "Shooter": 0, "Elite": 0})
	permanent_stats = data.get("permanent_stats", permanent_stats)
	damage_dealt = data.get("damage_dealt", 0.0)
	damage_taken = data.get("damage_taken", 0.0)
	
	apply_permanent_stats()
	print("💾 Progress loaded: Level ", player_level, " | Kills: ", total_kills)

# Fonctions utilitaires pour l'interface
func get_kill_count(enemy_type: String) -> int:
	return kill_counts.get(enemy_type, 0)

func get_total_kills() -> int:
	return total_kills

func get_level() -> int:
	return player_level

func get_experience_progress() -> float:
	return float(experience) / float(experience_needed)

func get_stat_value(stat_name: String) -> float:
	return permanent_stats.get(stat_name, 0.0)

# Debug et test
func add_test_kills(enemy_type: String, count: int):
	for i in range(count):
		on_enemy_killed(enemy_type, Vector2.ZERO)

func reset_progression():
	player_level = 1
	experience = 0
	experience_needed = 100
	total_kills = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	kill_counts = {"Grunt": 0, "Shooter": 0, "Elite": 0}
	permanent_stats = {
		"damage_multiplier": 1.0,
		"health_multiplier": 1.0,
		"speed_multiplier": 1.0,
		"fire_rate_multiplier": 1.0,
		"armor": 0.0,
		"lifesteal": 0.0,
		"extra_projectiles": 0,
		"penetration": 0,
		"crit_chance": 0.0,
		"crit_damage": 1.5
	}
	print("🔄 Progression reset!")

# Fonctions pour recevoir les dégâts (pour les stats)
func on_damage_dealt(amount: float):
	damage_dealt += amount

func on_damage_taken(amount: float):
	damage_taken += amount
