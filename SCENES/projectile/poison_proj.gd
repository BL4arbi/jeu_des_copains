extends Node2D

var pos: Vector2
var rota: float
var dir: float
@export var speed = 500
@export var damage = 15
@export var poison_damage = 8
@export var poison_duration = 4.0
@export var lifetime = 6.0  # Durée de vie du projectile

var life_timer = 0.0

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	add_to_group("bullet")
	
	print("💚 Poison créé - Durée: ", lifetime, "s")
	
	# Garder la couleur ORIGINALE du sprite
	# Pas de modulation pour garder la texture de base

func _physics_process(delta: float) -> void:
	# Gérer la durée de vie
	life_timer += delta
	if life_timer >= lifetime:
		print("Poison expiré après ", lifetime, " secondes")
		queue_free()
		return
	
	# Mouvement simple en ligne droite
	global_position += Vector2(speed, 0).rotated(dir) * delta
	rotation = dir
	
	# Vérifier collision
	check_collision_with_enemies()

func check_collision_with_enemies():
	var enemies = get_tree().get_nodes_in_group("ennemi")
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < 35:
				hit_enemy(enemy)
				break

func hit_enemy(enemy):
	print("💚 Poison touche : ", enemy.name)
	
	# Dégâts instantanés
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	# Poison
	if enemy.has_method("apply_poison"):
		enemy.apply_poison(poison_damage, poison_duration)
	
	# Détruire immédiatement
	queue_free()

func get_damage():
	return damage

func is_poison_bullet():
	return true
