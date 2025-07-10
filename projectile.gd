extends Node2D

var pos: Vector2
var rota: float
var dir: float
var speed = 500

var damage: int
var base_damage = 25

enum ProjectileType {
	FIRE,
	POISON,
	LIGHTNING
}

@onready var sprite = $Sprite2D

@export var projectile_type: ProjectileType = ProjectileType.FIRE
@export var fire_sprite = preload("res://SPRITES/FIRE_BALL.png")
@export var poison_sprite: Texture2D
@export var lightning_sprite = preload("res://SPRITES/ELECTRO_BALL.png")

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	add_to_group("bullet")
	$Area2D.body_entered.connect(_on_body_entered)
	
	setup_projectile_type()

func setup_projectile_type():
	
	match projectile_type:
		ProjectileType.FIRE:
			damage = base_damage + 10
			speed = 600
			if ProjectileType.FIRE:
				sprite.texture = fire_sprite
		ProjectileType.POISON:
			damage = base_damage - 5
			speed = 400
			if ProjectileType.POISON:
				sprite.texture = poison_sprite
		ProjectileType.LIGHTNING:
			damage = base_damage + 15
			speed = 800
			if ProjectileType.LIGHTNING:
				sprite.texture = lightning_sprite

func _physics_process(delta: float) -> void:
		global_position += Vector2(speed, 0).rotated(dir) * delta

func _on_body_entered(body):
	print("Collision détectée avec : ", body.name, " - Layer : ", body.collision_layer)
	if body.name == "CharacterBody2D2":
		print("La balle a touché l'ennemi!")
		queue_free()
	if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()

func get_damage():
		return damage
