extends CharacterBody2D

@export var speed: float = 100.0
@export var chase_range: float = 300.0
@export var player: CharacterBody2D

func _physics_process(delta):
	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player < chase_range:
		# Poursuite horizontale uniquement
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * speed
	else:
		velocity.x = 0

	move_and_slide()
