# GlobalData.gd
extends Node

var selected_character_id: int = 0
var current_level: int = 1
var total_kills: int = 0
var player_stats: Dictionary = {}
var characters_data: Array = []

# Signaux
signal kill_count_updated(new_count: int)

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
			"description": "Personnage équilibré"
		},
		{
			"id": 1,
			"name": "Archer",
			"health": 80,
			"speed": 280,
			"damage": 30,
			"sprite_path": "res://assets/SPRITES/character/Hunter_Walk.png",
			"description": "Rapide mais fragile"
		},
		{
			"id": 2,
			"name": "Mage",
			"health": 70,
			"speed": 150,
			"damage": 40,
			"sprite_path": "res://assets/SPRITES/character/VAISSEAU 1.png",
			"description": "Lent mais puissant"
		}
	]

func select_character(character_id: int):
	selected_character_id = character_id
	player_stats = characters_data[character_id].duplicate()

func add_kill():
	total_kills += 1
	kill_count_updated.emit(total_kills)

func get_character_data(character_id: int) -> Dictionary:
	if character_id < characters_data.size():
		return characters_data[character_id]
	return {}
