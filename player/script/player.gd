extends CharacterBody2D 
# Vitesse horizontale du joueur
@export var speed: float = 200.0
# Puissance du saut
@export var jump_velocity: float = -400.0
# Gravité (si tu ne veux pas utiliser celle du projet)
@export var gravity: float = 1000.0

func _physics_process(delta):
	var direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# Mouvement horizontal
	velocity.x = direction * speed

	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += gravity * delta

	# Saut
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Appliquer le mouvement
	move_and_slide()
