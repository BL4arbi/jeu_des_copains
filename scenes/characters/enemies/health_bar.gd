# HealthBar.gd
# Script à attacher à la ProgressBar de santé
extends ProgressBar

var target_character: BaseCharacter = null

func _ready():
	# Trouver le personnage parent
	target_character = get_parent() as BaseCharacter
	
	if target_character:
		# Connecter aux signaux du personnage
		target_character.health_changed.connect(_on_health_changed)
		
		# Configuration initiale
		max_value = 100
		value = 100
		
		# Style de la barre
		setup_health_bar_style()
		
		print("HealthBar connected to: ", target_character.name)
	else:
		print("ERROR: HealthBar not found valid parent character")

func setup_health_bar_style():
	# Position au-dessus du personnage
	position = Vector2(-30, -50)  # Ajuster selon tes sprites
	size = Vector2(60, 8)
	
	# Style visuel (si tu n'as pas de thème)
	modulate = Color.WHITE
	
	# Toujours visible au-dessus
	z_index = 100

func _on_health_changed(current_health: float, max_health: float):
	# Mettre à jour les valeurs
	max_value = max_health
	value = current_health
	
	# Changer la couleur selon le pourcentage de vie
	var health_percent = current_health / max_health
	
	if health_percent > 0.6:
		modulate = Color.GREEN
	elif health_percent > 0.3:
		modulate = Color.YELLOW
	else:
		modulate = Color.RED
	
	# Masquer si vie pleine (optionnel)
	visible = current_health < max_health
	
	print("HealthBar updated: ", current_health, "/", max_health)

func _process(_delta):
	# S'assurer que la barre reste au-dessus du personnage
	if target_character and is_instance_valid(target_character):
		# Suivre la position du personnage
		global_position = target_character.global_position + Vector2(-30, -50)
	else:
		# Le personnage a été détruit
		queue_free()
