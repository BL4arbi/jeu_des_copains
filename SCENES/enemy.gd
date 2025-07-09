extends CharacterBody2D

@export var max_health = 100
var current_health

func _ready():
	current_health = max_health
	add_to_group("ennemi")

func take_damage(damage_amount):
	current_health -= damage_amount
	print("Ennemi touché ! Vie restante : ", current_health)
	
	flash_red()
	
	if current_health <= 0:
		die()

func die():
	print("L'ennemi est mort !")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func flash_red():
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
