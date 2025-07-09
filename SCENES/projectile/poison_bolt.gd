extends Node2D

var pos: Vector2
var rota: float
var dir: float
@export var speed = 400
@export var damage = 30
@export var max_bounces = 3
@export var bounce_range = 200.0

var current_bounces = 0
var hit_enemies = []
var current_target = null
var is_bouncing = false

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	add_to_group("bullet")
	
	print("=== THUNDER BOLT CRÉÉ ===")
	print("Position : ", global_position)
	print("Direction : ", dir)
	
	# Couleur jaune pour l'éclair
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.YELLOW

func _physics_process(delta: float) -> void:
	if is_bouncing and current_target and is_instance_valid(current_target):
		# Se diriger vers la cible actuelle
		var direction = (current_target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		
		# Vérifier si on a atteint la cible
		if global_position.distance_to(current_target.global_position) < 40:
			hit_enemy(current_target)
	else:
		# Mouvement normal en ligne droite
		global_position += Vector2(speed, 0).rotated(dir) * delta
		
		# Vérifier collision avec tous les ennemis
		check_collision_with_enemies()

func check_collision_with_enemies():
	var enemies = get_tree().get_nodes_in_group("ennemi")
	
	for enemy in enemies:
		if not enemy in hit_enemies and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < 40:  # Distance de collision
				print("COLLISION MANUELLE ! Thunder Bolt touche : ", enemy.name)
				hit_enemy(enemy)
				break

func hit_enemy(enemy):
	# Ajouter l'ennemi à la liste des touchés
	hit_enemies.append(enemy)
	
	print("Thunder Bolt frappe : ", enemy.name, " (rebond ", current_bounces + 1, "/", max_bounces, ")")
	
	# Infliger des dégâts DIRECTEMENT
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		print("Dégâts infligés : ", damage)
	
	# Effet visuel éclair
	flash_lightning()
	
	# Incrémenter le compteur de rebonds
	current_bounces += 1
	
	# Vérifier s'il reste des rebonds
	if current_bounces < max_bounces:
		find_next_target()
	else:
		print("Thunder Bolt épuisé après ", max_bounces, " rebonds")
		queue_free()

func find_next_target():
	var nearest_enemy = null
	var nearest_distance = bounce_range
	
	# Chercher tous les ennemis dans la scène
	var enemies = get_tree().get_nodes_in_group("ennemi")
	
	for enemy in enemies:
		# Ignorer les ennemis déjà touchés
		if enemy in hit_enemies:
			continue
		
		# Vérifier si l'ennemi est mort
		if not is_instance_valid(enemy):
			continue
		
		# Calculer la distance
		var distance = global_position.distance_to(enemy.global_position)
		
		# Trouver l'ennemi le plus proche dans la portée
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	
	if nearest_enemy:
		current_target = nearest_enemy
		is_bouncing = true
		print("Prochain rebond vers : ", nearest_enemy.name, " (distance: ", nearest_distance, ")")
		
		# Créer effet visuel de rebond
		create_bounce_effect(nearest_enemy.global_position)
	else:
		print("Aucun ennemi dans la portée, Thunder Bolt disparaît")
		queue_free()

func create_bounce_effect(target_pos):
	# Effet visuel : ligne d'éclair vers la cible
	var line = Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(target_pos))
	line.default_color = Color.CYAN
	line.width = 3
	add_child(line)
	
	# Faire disparaître la ligne après un court instant
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func flash_lightning():
	# Effet visuel quand l'éclair touche
	modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.YELLOW, 0.1)

func get_damage():
	return damage

func is_thunder_bolt():
	return true
