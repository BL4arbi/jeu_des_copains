# ForkArrowProjectile.gd - Version corrigée et simplifiée
extends Area2D
class_name ForkArrowProjectile

# Variables principales
var damage: float = 15.0
var speed: float = 400.0
var lifetime: float = 5.0
var direction: Vector2 = Vector2.RIGHT
var owner_type: String = "player"

# Variables fork
var fork_count: int = 3
var has_forked: bool = false
var targets_hit: Array = []
var lifetime_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	collision_layer = 4 if owner_type == "player" else 8
	collision_mask = 2 if owner_type == "player" else 1
	
	if sprite:
		sprite.modulate = Color.PURPLE
	
	print("🏹 Fork Arrow ready!")

func setup(projectile_damage: float, projectile_speed: float, projectile_lifetime: float):
	damage = projectile_damage
	speed = projectile_speed
	lifetime = projectile_lifetime

func set_owner_type(type: String):
	owner_type = type
	collision_layer = 4 if owner_type == "player" else 8
	collision_mask = 2 if owner_type == "player" else 1

func launch(start_pos: Vector2, target_pos: Vector2):
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	
	# Vérification de sécurité
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	if sprite:
		sprite.rotation = direction.angle()

func _physics_process(delta):
	# Vérification de sécurité
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	global_position += direction * speed * delta
	
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		if not has_forked:
			create_fork_arrows(global_position)
		queue_free()

func _on_body_entered(body):
	print("🏹 Fork hit body: ", body.name)
	
	if not should_damage_target(body):
		return
	
	if body in targets_hit:
		return
	
	targets_hit.append(body)
	
	# Fork AVANT de faire des dégâts
	if not has_forked:
		has_forked = true
		create_fork_arrows(body.global_position)
	
	# Dégâts
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("✅ Fork damage: ", damage)
	
	queue_free()

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent:
		_on_body_entered(parent)

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true

func create_fork_arrows(impact_pos: Vector2):
	print("🏹 Creating ", fork_count, " fork arrows!")
	
	for i in range(fork_count):
		call_deferred("spawn_simple_fork", i, impact_pos)

func spawn_simple_fork(index: int, impact_pos: Vector2):
	# Créer un projectile simple basé sur BaseProjectile
	var fork_scene = preload("res://scenes/projectiles/BasicProjectile.tscn")
	var fork = fork_scene.instantiate()
	
	# Ajouter à la scène
	get_tree().current_scene.add_child(fork)
	
	# Configuration de base
	fork.set_owner_type(owner_type)
	fork.setup(damage * 0.6, speed * 0.8, 2.0)  # Dégâts et vitesse réduits
	
	# Direction du fork
	var fork_direction = get_fork_direction(index, impact_pos)
	var target_pos = impact_pos + fork_direction * 300
	
	# Lancer le fork
	fork.launch(impact_pos, target_pos)
	
	# Modifier l'apparence pour le distinguer
	if fork.sprite:
		fork.sprite.modulate = Color.LIGHT_BLUE
		fork.sprite.scale = Vector2(0.7, 0.7)
	
	print("🏹 Fork ", index + 1, " spawned with direction ", fork_direction)

func get_fork_direction(index: int, impact_pos: Vector2) -> Vector2:
	# Chercher des ennemis proches
	var target_group = "enemies" if owner_type == "player" else "players"
	var nearby_enemies = []
	
	for enemy in get_tree().get_nodes_in_group(target_group):
		if not is_instance_valid(enemy):
			continue
		
		var distance = impact_pos.distance_to(enemy.global_position)
		if distance <= 200 and distance > 20:
			nearby_enemies.append({
				"enemy": enemy,
				"distance": distance
			})
	
	# Trier par distance
	nearby_enemies.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Si on a des cibles, viser les plus proches
	if index < nearby_enemies.size():
		var target_direction = (nearby_enemies[index].enemy.global_position - impact_pos).normalized()
		if target_direction != Vector2.ZERO:
			return target_direction
	
	# Sinon, spread en éventail
	var base_angle = direction.angle()
	var spread = PI / 3  # 60 degrés
	var angle_step = spread / max(1, fork_count - 1)
	var fork_angle = base_angle - (spread / 2) + (index * angle_step)
	
	var result = Vector2(cos(fork_angle), sin(fork_angle))
	
	# Vérification finale
	if result == Vector2.ZERO:
		result = Vector2.RIGHT
	
	return result
