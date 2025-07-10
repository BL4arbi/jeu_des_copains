extends Node2D

@export var weapon_pickup_scene: PackedScene = preload("res://SCENES/weapon_pickup.gd")

var available_weapons = ["poison", "thunder", "fireball"]

func _ready():
	# Spawner des armes au démarrage
	spawn_initial_weapons()
	
	# Timer pour spawner plus d'armes
	var timer = Timer.new()
	timer.wait_time = 10.0  # Spawner une arme toutes les 10 secondes
	timer.timeout.connect(spawn_random_weapon)
	timer.autostart = true
	add_child(timer)

func spawn_initial_weapons():
	# Spawner 3 armes au début
	for i in range(3):
		var pos = Vector2(
			randf_range(200, 1000),
			randf_range(200, 600)
		)
		spawn_weapon_at(pos, available_weapons[i % available_weapons.size()])

func spawn_random_weapon():
	var pos = Vector2(
		randf_range(200, 1000),
		randf_range(200, 600)
	)
	var weapon_type = available_weapons[randi() % available_weapons.size()]
	spawn_weapon_at(pos, weapon_type)

func spawn_weapon_at(position: Vector2, weapon_type: String):
	var pickup = weapon_pickup_scene.instantiate()
	pickup.global_position = position
	pickup.weapon_type = weapon_type
	
	add_child(pickup)
	print("Arme spawnée : ", weapon_type, " à ", position)
