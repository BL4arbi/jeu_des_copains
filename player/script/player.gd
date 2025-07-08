class_name Player extends CharacterBody2D

var movespeed : float = 100.0



func _process(_delta: float) -> void:
	var direction = Input.get_vector("left","right","up","down")
	print(direction)
	velocity = direction * movespeed
	move_and_slide()
