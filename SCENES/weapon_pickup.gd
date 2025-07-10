extends Area2D

@export var weapon_type: String = "poison"

func _ready():
	# Configuration de base
	collision_layer = 4
	collision_mask = 1
	
	# Connecter le signal
	body_entered.connect(_on_body_entered)
	
	# Couleur selon l'arme
	setup_visual()
	
	# Animation simple
	start_bounce()
	
	print("Pickup créé : ", weapon_type)

func setup_visual():
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		
		# Couleur selon le type
		match weapon_type:
			"poison":
				sprite.modulate = Color.GREEN
				sprite.scale = Vector2(1.2, 1.2)
			"thunder":
				sprite.modulate = Color.YELLOW
				sprite.scale = Vector2(1.0, 1.0)
			"normal":
				sprite.modulate = Color.WHITE
				sprite.scale = Vector2(0.8, 0.8)
			_:
				sprite.modulate = Color.GRAY

func start_bounce():
	# Animation de rebond simple
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 10, 1.0)
	tween.tween_property(self, "position:y", position.y + 10, 1.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🎁 Joueur touche pickup : ", weapon_type)
		
		if body.has_method("add_weapon"):
			var success = body.add_weapon(weapon_type)
			
			if success:
				print("✅ Arme ramassée : ", weapon_type)
				
				# Effet de ramassage
				var tween = create_tween()
				tween.parallel().tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
				tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
				tween.tween_callback(queue_free)
			else:
				print("❌ Impossible de ramasser")
