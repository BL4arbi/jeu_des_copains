extends Node2D

var pos: Vector2
var rota: float
var dir: float
var speed = 500

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	
	# Connecter le signal de l'Area2D enfant
	$Area2D.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Déplacer la balle
	global_position += Vector2(speed, 0).rotated(dir) * delta

func _on_body_entered(body):
	print("Collision détectée avec : ", body.name, " | Layer : ", body.collision_layer)
	if body.is_in_group("enemies"):  # Vérifie si le body est dans le groupe "enemies"
		print("La balle a touché un ennemi !")
		$Sprite2D.visible = false
		queue_free()
