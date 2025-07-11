# BaseProjectile.gd
extends RigidBody2D
class_name BaseProjectile

var damage: float = 10.0
var speed: float = 400.0
var lifetime: float = 3.0
var direction: Vector2

@onready var area_detector: Area2D = get_node_or_null("AreaDetector")

var lifetime_timer: float = 0.0

func _ready():
	gravity_scale = 0
	lock_rotation = true
	
	if area_detector:
		area_detector.body_entered.connect(_on_hit)



func launch(start_position: Vector2, target_position: Vector2):
	global_position = start_position
	direction = (target_position - start_position).normalized()

func _physics_process(delta):
	global_position += direction * speed * delta
	
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		queue_free()


# Ajouter une variable pour identifier le tireur
var shooter_type: String = "player"  # ou "enemy"

func setup(projectile_damage: float, projectile_speed: float, projectile_lifetime: float, shooter: String = "player"):
	damage = projectile_damage
	speed = projectile_speed
	lifetime = projectile_lifetime
	shooter_type = shooter
	
	# Configurer les layers selon le tireur
	if shooter_type == "player":
		collision_layer = 4  # Layer 3 pour projectiles joueur
		collision_mask = 6   # Mask pour toucher ennemis (layer 2) + murs (layer 5)
	else:
		collision_layer = 8  # Layer 4 pour projectiles ennemis  
		collision_mask = 17  # Mask pour toucher joueur (layer 1) + murs (layer 5)

func _on_hit(body):
	# Vérifier que le projectile ne touche pas son tireur
	if shooter_type == "player" and body.is_in_group("players"):
		return
	if shooter_type == "enemy" and body.is_in_group("enemies"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
