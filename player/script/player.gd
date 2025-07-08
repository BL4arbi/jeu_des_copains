class_name Player extends CharacterBody2D

var movespeed : float = 120.0
var porj_path=preload("res://projectile.tscn")

func Enter()-> void :
	
	pass
func _process(delta: float) -> void:
	var direction = Input.get_vector("left","right","up","down")
	velocity = direction * movespeed
	move_and_slide()

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("click"):
		fire()	

func fire():
	var bullet = porj_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $Node2D.global_position
	bullet.rota=global_rotation
	get_parent().add_child(bullet)
	
	
