extends CharacterBody2D
class_name BaseCharacter

# Stats
var current_health: float = 100.0
var max_health: float = 100.0
var speed: float = 200.0
var damage: float = 20.0

# Composants (à ajouter quand la scène sera créée)
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	# Initialiser depuis GlobalData si disponible
	if GlobalData and GlobalData.player_stats.size() > 0:
		var data = GlobalData.player_stats
		max_health = data.get("health", 100)
		current_health = max_health
		speed = data.get("speed", 200)
		damage = data.get("damage", 20)

func take_damage(amount: float):
	current_health = max(0, current_health - amount)
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(max_health, current_health + amount)

func die():
	print("Character died!")
