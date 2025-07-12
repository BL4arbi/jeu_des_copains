extends Node
class_name WeaponSystem

@export var owner_node: Node2D
@onready var inventory: PlayerInventory = $PlayerInventory

# Configuration de tir
var fire_rate: float = 0.5
var fire_timer: float = 0.0
var can_fire: bool = true

func _ready():
	# Connecter les signaux de l'inventaire
	if inventory:
		inventory.weapon_changed.connect(_on_weapon_changed)

func _process(delta):
	# Gérer le timer de cadence de tir
	if not can_fire:
		fire_timer += delta
		if fire_timer >= fire_rate:
			can_fire = true
			fire_timer = 0.0

func fire_projectile(target_position: Vector2) -> bool:
	if not can_fire or not owner_node or not inventory:
		return false
	
	var current_weapon = inventory.get_current_weapon()
	if not current_weapon:
		return false
	
	# Calculer la direction
	var direction = (target_position - owner_node.global_position).normalized()
	
	# Charger et instancier le projectile
	if ResourceLoader.exists(current_weapon.projectile_scene_path):
		var projectile_scene = load(current_weapon.projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		
		# Ajouter à la scène
		get_tree().current_scene.add_child(projectile)
		
		# Initialiser et lancer
		if projectile.has_method("initialize_from_data"):
			projectile.initialize_from_data(current_weapon)
		
		if projectile.has_method("launch"):
			projectile.launch(owner_node.global_position, direction)
		
		can_fire = false
		fire_timer = 0.0
		return true
	else:
		print("ERROR: Projectile scene not found: ", current_weapon.projectile_scene_path)
		return false

func pickup_weapon(weapon_data: ProjectileData):
	if inventory:
		inventory.add_weapon(weapon_data)

func switch_weapon(direction: int):
	if inventory:
		inventory.switch_weapon(direction)

func _on_weapon_changed(weapon: ProjectileData):
	# Ajuster la cadence de tir selon l'arme
	match weapon.projectile_name:
		"Tir Basique":
			fire_rate = 0.3
		"Tir Rapide":
			fire_rate = 0.1
		"Canon Lourd":
			fire_rate = 1.0
		_:
			fire_rate = 0.5
	
	print("Fire rate set to: ", fire_rate)
