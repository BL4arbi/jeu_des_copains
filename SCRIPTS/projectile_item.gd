extends Node2D
class_name ProjectileItem

enum ProjectileType {
	FIRE,
	POISON,
	LIGHTNING
}

@export var projectile_type: ProjectileType
@export var fire_item_sprite: Texture2D = preload("res://SPRITES/FIRE_BALL.png")
@export var poison_item_sprite: Texture2D 
@export var lightning_item_sprite: Texture2D = preload("res://SPRITES/ELECTRO_BALL.png")

signal body_entered

func _ready():
	# Configuration du sprite selon le type
	var sprite = $Sprite2D
	
	# Couleur selon le type
	match projectile_type:
		ProjectileType.FIRE:
			if fire_item_sprite:
				sprite.texture = fire_item_sprite
		ProjectileType.POISON:
			if poison_item_sprite:
				sprite.texture = poison_item_sprite
		ProjectileType.LIGHTNING:
			if lightning_item_sprite:
				sprite.texture = lightning_item_sprite
	
	# Effet visuel (bobbing)
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 10, 1.0)
	tween.tween_property(self, "position:y", position.y + 10, 1.0)
	
	# Connecter le signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("allies"):
		body.change_projectile_type(projectile_type)
		queue_free()
