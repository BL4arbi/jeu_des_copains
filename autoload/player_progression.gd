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
