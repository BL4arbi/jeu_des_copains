extends Node2D

var pos: Vector2
var rota: float
var dir: float
var speed = 30

var damage = 25 
@export var lifetime = 6.0  # Durée de vie du projectile

var life_timer = 0.0

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	add_to_group("bullet")
	$Area2D.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
		global_position += Vector2(speed, 0).rotated(dir) * delta
		life_timer += delta
		if life_timer >= lifetime:
			print("Poison expiré après ", lifetime, " secondes")
			queue_free()
			return

func _on_body_entered(body):
	if body.name == "CharacterBody2D2":
		
		$Sprite2D.visible = false
		queue_free()
	if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()

func get_damage():
		return damage
