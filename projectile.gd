extends Node2D

var pos: Vector2
var rota: float
var dir: float
var speed = 30

var damage = 25 

enum ProjectileType{
	FIRE,
	POISON,
	LIGHTNING
}

var projectile_type: ProjectileType = ProjectileType.FIRE

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	add_to_group("bullet")
	$Area2D.body_entered.connect(_on_body_entered)
	
	setup_projectile_properties()
	
func _physics_process(delta: float) -> void:
		global_position += Vector2(speed, 0).rotated(dir) * delta

func _on_body_entered(body):
	if body.name == "CharacterBody2D2":
		
		$Sprite2D.visible = false
		queue_free()
	if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()

func get_damage():
		return damage

func setup_projectile_properties():
	match projectile_type:
		ProjectileType.FIRE:
			damage = 25
			speed = 300
			$Sprite2D.texture = preload("res://SPRITES/FIRE_BALL.png")
		ProjectileType.POISON:
			damage = 15
			speed = 250
		ProjectileType.LIGHTNING:
			damage = 100
			speed = 50
			$Sprite2D.texture = preload("res://SPRITES/ELECTRO_BALL.png")
