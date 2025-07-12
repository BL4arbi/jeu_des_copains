extends Node
class_name WeaponSpawner

@export var weapon_pickup_scene: PackedScene = preload("res://scenes/ui/weapon_pickup.tscn")
@export var spawn_area: Rect2 = Rect2(100, 100, 600, 400)
@export var spawn_interval: float = 10.0  # Spawn une arme toutes les 10 secondes

var spawn_timer: float = 0.0
var weapons_on_ground: Array = []

# Armes disponibles
var available_weapons: Array = [
	{
		"name": "Tir Rapide",
		"damage": 8.0,
		"speed": 600.0,
		"fire_rate": 0.15,
		"scene_path": "res://scenes/projectiles/RapidProjectile.tscn"
	},
	{
		"name": "Canon Lourd", 
		"damage": 25.0,
		"speed": 300.0,
		"fire_rate": 0.8,
		"scene_path": "res://scenes/projectiles/HeavyProjectile.tscn"
	}
]

func _ready():
	# Spawner 2 armes au début
	spawn_weapon()
	spawn_weapon()

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_weapon()
		spawn_timer = 0.0

func spawn_weapon():
	if weapons_on_ground.size() >= 4:
		return
	
	var spawn_pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	
	var weapon_data = available_weapons[randi() % available_weapons.size()]
	
	var pickup = weapon_pickup_scene.instantiate()
	pickup.weapon_name = weapon_data.name
	pickup.damage = weapon_data.damage
	pickup.speed = weapon_data.speed
	pickup.fire_rate = weapon_data.fire_rate
	pickup.projectile_scene_path = weapon_data.scene_path
	pickup.global_position = spawn_pos
	
	call_deferred("add_child", pickup)  # ← CORRIGÉ ICI
	weapons_on_ground.append(pickup)
	
	pickup.tree_exiting.connect(_on_weapon_picked_up.bind(pickup))
	print("Spawned weapon: ", weapon_data.name, " at ", spawn_pos)

func _on_weapon_picked_up(pickup):
	weapons_on_ground.erase(pickup)
