# HealthBar.gd
# Script à attacher à la ProgressBar de santé
extends ProgressBar

var target_character: Node = null

func _ready():
	# Trouver le personnage parent
	target_character = get_parent()
	
	if target_character:
		# Connecter aux signaux du personnage
		if target_character.has_signal("health_changed"):
			target_character.health_changed.connect(_on_health_changed)
			print("✅ HealthBar connected to: ", target_character.name)
		else:
			print("❌ No health_changed signal found on: ", target_character.name)
		
		# Configuration initiale
		max_value = 100
		value = 100
		
		# Style de la barre
		setup_health_bar_style()
	else:
		print("❌ ERROR: HealthBar parent not found")

func setup_health_bar_style():
	# Position au-dessus du personnage
	position = Vector2(-25, -40)  # Ajuster selon tes sprites
	size = Vector2(50, 6)
	
	# Style visuel
	modulate = Color.GREEN
	
	# Toujours visible au-dessus
	z_index = 100

func _on_health_changed(current_health: float, max_health: float):
	print("🩺 HealthBar update: ", current_health, "/", max_health)
	
	# Mettre à jour les valeurs
	max_value = max_health
	value = current_health
	
	# Changer la couleur selon le pourcentage de vie
	var health_percent = current_health / max_health if max_health > 0 else 0
	
	if health_percent > 0.6:
		modulate = Color.GREEN
	elif health_percent > 0.3:
		modulate = Color.YELLOW
	else:
		modulate = Color.RED
	
	# Masquer si vie pleine (optionnel)
	visible = current_health < max_health

func _process(_delta):
	# S'assurer que la barre reste au-dessus du personnage
	if target_character and is_instance_valid(target_character):
		# Suivre la position du personnage
		global_position = target_character.global_position + Vector2(-25, -40)
	else:
		# Le personnage a été détruit
		queue_free()
