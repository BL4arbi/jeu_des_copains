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

func setup(projectile_damage: float, projectile_speed: float, projectile_lifetime: float):
	damage = projectile_damage
	speed = projectile_speed
	lifetime = projectile_lifetime

func launch(start_position: Vector2, target_position: Vector2):
	global_position = start_position
	direction = (target_position - start_position).normalized()

func _physics_process(delta):
	global_position += direction * speed * delta
	
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		queue_free()

func _on_hit(body):
	if body.is_in_group("players"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	queue_free()
