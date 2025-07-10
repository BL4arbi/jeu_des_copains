extends Node2D

var pos: Vector2
var rota: float
var dir: float
@export var speed = 400
@export var bounce_speed = 200
@export var damage = 30
@export var max_bounces = 3
@export var bounce_range = 200.0
@export var knockback_force = 300.0

var current_bounces = 0
var hit_enemies = []
var current_target = null
var is_bouncing = false

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	add_to_group("bullet")
	
	print("Thunder Bolt créé - PROPRE")
	
	# Couleur jaune pour l'éclair
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.YELLOW

func _physics_process(delta: float) -> void:
	if is_bouncing and current_target and is_instance_valid(current_target):
		# Rebond vers la cible
		var direction = (current_target.global_position - global_position).normalized()
		global_position += direction * bounce_speed * delta
		rotation = direction.angle()
		
		# Vérifier si on a atteint la cible
		if global_position.distance_to(current_target.global_position) < 40:
			hit_enemy(current_target)
	else:
		# Mouvement normal
		global_position += Vector2(speed, 0).rotated(dir) * delta
		rotation = dir
		check_collision_with_enemies()

func check_collision_with_enemies():
	var enemies = get_tree().get_nodes_in_group("ennemi")
	
	for enemy in enemies:
		if not enemy in hit_enemies and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < 40:
				hit_enemy(enemy)
				break

func hit_enemy(enemy):
	if enemy in hit_enemies:
		return
	
	hit_enemies.append(enemy)
	
	print("⚡ Thunder Bolt frappe : ", enemy.name, " (", current_bounces + 1, "/", max_bounces, ")")
	
	# Dégâts
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	# Knockback
	apply_knockback(enemy)
	
	# Effet visuel SIMPLE (juste changer la couleur du sprite existant)
	flash_simple()
	
	# Arrêter le mouvement
	is_bouncing = false
	current_target = null
	
	await get_tree().create_timer(0.1).timeout
	
	current_bounces += 1
	
	if current_bounces < max_bounces:
		find_next_target()
	else:
		print("Thunder Bolt terminé")
		queue_free()

func apply_knockback(enemy):
	var knockback_direction = (enemy.global_position - global_position).normalized()
	
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(knockback_direction * knockback_force)
	elif "velocity" in enemy:
		enemy.velocity += knockback_direction * knockback_force

func find_next_target():
	var nearest_enemy = null
	var nearest_distance = bounce_range
	
	var enemies = get_tree().get_nodes_in_group("ennemi")
	
	for enemy in enemies:
		if enemy in hit_enemies or not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	
	if nearest_enemy:
		current_target = nearest_enemy
		is_bouncing = true
		print("🎯 Rebond vers : ", nearest_enemy.name)
	else:
		print("Aucune cible - Thunder Bolt disparaît")
		queue_free()

func flash_simple():
	# Effet visuel ULTRA simple - juste changer les propriétés du sprite existant
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(1.5, 1.5)
		
		# Revenir à la normale
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "modulate", Color.YELLOW, 0.2)
		tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)

func get_damage():
	return damage

func is_thunder_bolt():
	return true
