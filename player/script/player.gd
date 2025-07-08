class_name Player extends CharacterBody2D

var movespeed : float = 50.0



func _process(delta: float) -> void:
	var direction = Input.get_vector("left","right","up","down")
	print(direction)
	velocity = direction * movespeed
	move_and_slide()
