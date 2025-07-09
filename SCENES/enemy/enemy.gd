extends CharacterBody2D

@export var speed: float = 80.0
@export var chase_range: float = 500.0
@export var player: CharacterBody2D
@export var max_health = 100
var current_health

func _ready():
	current_health = max_health
	add_to_group("ennemi")
	
	print("=== ENNEMI CRÉÉ : ", name, " ===")
	print("Position : ", global_position)
	print("Collision Layer : ", collision_layer)
	print("Collision Mask : ", collision_mask)
	
	# Trouver le joueur
	find_player()
	
	# Connecter Area2D
	if has_node("Area2D"):
		$Area2D.body_entered.connect(_on_area_2d_body_entered)
		print("Area2D connecté pour ", name)
	else:
		print("ERREUR : Area2D non trouvé pour ", name)

func find_player():
	if player == null:
		# Chercher le joueur dans la scène parent
		var parent = get_parent()
		for child in parent.get_children():
			if child.name == "CharacterBody2D" or child.has_method("_on_node_2d_input_event"):
				player = child
				break
	
	if player:
		print("Joueur trouvé pour ", name, " : ", player.name)
	else:
		print("ERREUR : Joueur NON trouvé pour ", name)

func _physics_process(delta):
	if player == null:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player < chase_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		print(name, " poursuit le joueur - Distance: ", distance_to_player)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _on_area_2d_body_entered(body):
	print("=== ", name, " DÉTECTE COLLISION ===")
	print("Corps détecté : ", body.name)
	print("Groupes du corps : ", body.get_groups())
	
	if body.is_in_group("bullet"):
		print("C'est une balle ! Dégâts appliqués à ", name)
		take_damage(25)
	else:
		print("Ce n'est pas une balle...")

func take_damage(damage_amount):
	current_health -= damage_amount
	print("*** ", name, " TOUCHÉ ! Vie restante : ", current_health, " ***")
	
	flash_red()
	
	if current_health <= 0:
		die()

func die():
	print("*** ", name, " EST MORT ! ***")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func flash_red():
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
