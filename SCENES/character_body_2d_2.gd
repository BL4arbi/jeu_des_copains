extends CharacterBody2D

@export var speed: float = 80.0
@export var chase_range: float = 100.0
@export var player: CharacterBody2D

func _physics_process(_delta):
	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player < chase_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
func _on_body_entered(body):
	
	if body.is_in_group("enemies"):
		 
		print("La balle a touché un ennemi !")
		
		body.queue_free()  # Supprime l'ennemi
		queue_free()       # Supprime la balle aussi
