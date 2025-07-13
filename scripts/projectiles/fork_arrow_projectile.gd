# ForkArrowProjectile.gd - Version corrigée
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
		call_deferred("spawn_fork", i, impact_pos)

func spawn_fork(index: int, impact_pos: Vector2):
	# Créer projectile simple
	var fork = Area2D.new()
	fork.name = "Fork_" + str(index)
	
	# Sprite
	var fork_sprite = Sprite2D.new()
	fork.add_child(fork_sprite)
	
	if sprite and sprite.texture:
		fork_sprite.texture = sprite.texture
		fork_sprite.scale = Vector2(0.7, 0.7)
		fork_sprite.modulate = Color.LIGHT_BLUE
	
	# Collision
	var fork_collision = CollisionShape2D.new()
	var fork_shape = RectangleShape2D.new()
	fork_shape.size = Vector2(10, 4)
	fork_collision.shape = fork_shape
	fork.add_child(fork_collision)
	
	# Position et direction
	fork.global_position = impact_pos
	var fork_direction = get_fork_direction(index, impact_pos)
	
	# Vérification de sécurité pour la direction
	if fork_direction == Vector2.ZERO:
		fork_direction = Vector2.RIGHT
	
	fork_sprite.rotation = fork_direction.angle()
	
	# Configuration
	fork.collision_layer = collision_layer
	fork.collision_mask = collision_mask
	
	# Ajouter au scene d'abord
	get_tree().current_scene.add_child(fork)
	
	# Puis définir les métadonnées
	fork.set_meta("direction", fork_direction)
	fork.set_meta("speed", speed * 0.8)
	fork.set_meta("damage", damage * 0.6)
	fork.set_meta("owner_type", owner_type)
	fork.set_meta("lifetime", 2.0)
	
	# Script simplifié
	var script_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 10.0
var owner_type: String = "player"
var lifetime: float = 2.0
var timer: float = 0.0

func _ready():
	# Attendre une frame pour que les métadonnées soient bien définies
	await get_tree().process_frame
	
	# Récupération des métadonnées
	if has_meta('direction'):
		direction = get_meta('direction')
		print('🏹 Fork direction: ', direction)
	
	if has_meta('speed'):
		speed = get_meta('speed')
		print('🏹 Fork speed: ', speed)
	
	if has_meta('damage'):
		damage = get_meta('damage')
	
	if has_meta('owner_type'):
		owner_type = get_meta('owner_type')
	
	if has_meta('lifetime'):
		lifetime = get_meta('lifetime')
	
	body_entered.connect(_on_hit)
	area_entered.connect(_on_area_hit)
	
	print('🏹 Fork ', name, ' ready: dir=', direction, ' speed=', speed)

func _physics_process(delta):
	# Vérification de sécurité
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
		print('⚠️ Fork direction was zero, using RIGHT')
	
	global_position += direction * speed * delta
	timer += delta
	if timer >= lifetime:
		queue_free()

func _on_hit(body):
	if not should_damage(body):
		return
	
	if body.has_method('take_damage'):
		body.take_damage(damage)
		print('🏹 Fork hit ', body.name, ' for ', damage)
	
	queue_free()

func _on_area_hit(area):
	var parent = area.get_parent()
	if parent:
		_on_hit(parent)

func should_damage(body) -> bool:
	match owner_type:
		'player':
			return body.is_in_group('enemies')
		'enemy':
			return body.is_in_group('players')
		_:
			return true
"""
	
	var script = GDScript.new()
	script.source_code = script_code
	fork.set_script(script)
	
	print("🏹 Fork ", index + 1, " spawned at ", impact_pos, " with direction ", fork_direction)

func get_fork_direction(index: int, impact_pos: Vector2) -> Vector2:
	# Chercher des ennemis proches
	var target_group = "enemies" if owner_type == "player" else "players"
	var nearby_enemies = []
	
	for enemy in get_tree().get_nodes_in_group(target_group):
		if not is_instance_valid(enemy):
			continue
		
		var distance = impact_pos.distance_to(enemy.global_position)
		if distance <= 200 and distance > 20:
			nearby_enemies.append(enemy)
	
	# Si on a des cibles, viser la plus proche pour ce fork
	if index < nearby_enemies.size():
		var target_direction = (nearby_enemies[index].global_position - impact_pos).normalized()
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
