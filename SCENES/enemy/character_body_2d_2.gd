extends CharacterBody2D

@export var speed: float = 80.0
@export var chase_range: float = 1500
@export var player: CharacterBody2D


@export var max_health = 300
var current_health

func _ready():
	current_health = max_health
	add_to_group("ennemi")

func take_damage(damage_amount):
	current_health -= damage_amount
	print("Ennemi touché ! Vie restante : ", current_health)
	
	# Effet visuel (optionnel)
	flash_red()
	
	if current_health <= 0:
		die()

func die():
	print("L'ennemi est mort !")
	# Animation de mort (optionnel)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func flash_red():
	# Effet visuel quand l'ennemi prend des dégâts
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
func _physics_process(delta):
	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player < chase_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _on_area_2d_body_entered(body):
	if body.is_in_group("bullet"):
		queue_free()        # Tue l’ennemi
		body.queue_free()   # Tue le projectile aussi
