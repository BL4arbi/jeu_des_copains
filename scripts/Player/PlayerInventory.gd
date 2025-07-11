# === PlayerInventory.gd ===
# Version mise à jour pour l'UI
# À placer dans res://scripts/player/PlayerInventory.gd

extends Node
class_name PlayerInventory

# Inventaire des armes
var weapons: Array[ProjectileData] = []
var current_weapon_index: int = 0
var max_weapons: int = 5  # 5 slots comme demandé

# Signaux
signal weapon_added(weapon: ProjectileData)
signal weapon_changed(weapon: ProjectileData)
signal inventory_full()

func _ready():
	# Ajouter l'arme de base
	add_basic_weapon()

func add_basic_weapon():
	# Créer l'arme de base
	var basic_weapon = ProjectileData.new()
	basic_weapon.projectile_id = 0
	basic_weapon.projectile_name = "Tir Basique"
	basic_weapon.damage = 10.0
	basic_weapon.speed = 500.0
	basic_weapon.lifetime = 3.0
	basic_weapon.projectile_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
	basic_weapon.description = "Projectile de base - fiable et efficace"
	
	weapons.append(basic_weapon)

func add_weapon(weapon: ProjectileData) -> bool:
	# Vérifier si on a déjà cette arme
	for existing_weapon in weapons:
		if existing_weapon.projectile_id == weapon.projectile_id:
			print("Weapon already owned: ", weapon.projectile_name)
			return false
	
	# Vérifier si l'inventaire est plein
	if weapons.size() >= max_weapons:
		inventory_full.emit()
		print("Inventory full!")
		return false
	
	# Ajouter l'arme
	weapons.append(weapon)
	weapon_added.emit(weapon)
	print("Added weapon to inventory: ", weapon.projectile_name)
	return true

func switch_weapon(direction: int):
	if weapons.size() <= 1:
		return
	
	current_weapon_index = (current_weapon_index + direction) % weapons.size()
	if current_weapon_index < 0:
		current_weapon_index = weapons.size() - 1
	
	weapon_changed.emit(get_current_weapon())
	print("Switched to: ", get_current_weapon().projectile_name)

func select_weapon(index: int):
	if index >= 0 and index < weapons.size():
		current_weapon_index = index
		weapon_changed.emit(get_current_weapon())
		print("Selected weapon: ", get_current_weapon().projectile_name)

func get_current_weapon() -> ProjectileData:
	if weapons.size() > 0 and current_weapon_index < weapons.size():
		return weapons[current_weapon_index]
	return null

func get_weapons_list() -> Array[ProjectileData]:
	return weapons

func remove_weapon(index: int) -> bool:
	if index >= 0 and index < weapons.size() and weapons.size() > 1:
		# Ne pas permettre de supprimer l'arme de base (index 0)
		if index == 0:
			return false
		
		weapons.remove_at(index)
		
		# Ajuster l'index actuel si nécessaire
		if current_weapon_index >= weapons.size():
			current_weapon_index = weapons.size() - 1
		
		weapon_changed.emit(get_current_weapon())
		return true
	
	return false
