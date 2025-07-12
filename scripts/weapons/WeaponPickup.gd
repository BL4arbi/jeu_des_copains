# WeaponPickup.gd
extends Area2D
class_name WeaponPickup

@export var weapon_name: String = ""
@export var projectile_scene_path: String = ""
@export var damage: float = 10.0
@export var speed: float = 400.0
@export var fire_rate: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = get_node_or_null("Label")

func _ready():
	body_entered.connect(_on_pickup)
	
	if label:
		label.text = weapon_name
	
	create_weapon_sprite()

func create_weapon_sprite():
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	
	match weapon_name:
		"Tir Rapide":
			image.fill(Color.YELLOW)
		"Canon Lourd":
			image.fill(Color.RED)
		_:
			image.fill(Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _on_pickup(body):
	if body.is_in_group("players") and body.has_method("pickup_weapon"):
		var weapon_data = ProjectileData.new()
		weapon_data.projectile_name = weapon_name
		weapon_data.damage = damage
		weapon_data.speed = speed
		weapon_data.fire_rate = fire_rate
		weapon_data.projectile_scene_path = projectile_scene_path
		
		body.pickup_weapon(weapon_data)
		queue_free()
