class_name Player extends CharacterBody2D

var movespeed : float = 150
var porj_path=preload("res://projectile.tscn")
var thunder_bolt_scene: PackedScene = preload("res://SCENES/projectile/poison_bolt.tscn")

enum ProjectileType {
	FIRE,
	POISON,
	LIGHTNING
}

var current_projectile_type: ProjectileType = ProjectileType.FIRE
var projectile_type: ProjectileType = ProjectileType.FIRE

func _ready() -> void:
	add_to_group("allies")

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
	if Input.is_action_just_pressed("clique"):
			shoot_thunder_bolt()
func shoot_thunder_bolt():
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Créer le Thunder Bolt
	var thunder = thunder_bolt_scene.instantiate()
	thunder.pos = global_position
	thunder.dir = direction.angle()
	thunder.rota = thunder.dir
	
	get_parent().add_child(thunder)
	
func fire():
	var bullet = porj_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $Node2D.global_position
	bullet.rota=global_rotation
	bullet.projectile_type = current_projectile_type
	get_parent().add_child(bullet)
	
func change_projectile_type(new_type: ProjectileType):
	current_projectile_type = new_type
	print("Type de projectile changé vers : ", ProjectileType.keys()[new_type])	
