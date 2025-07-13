# WeaponSpawner.gd - Désactiver le spawn automatique
extends Node
class_name WeaponSpawner

# DÉSACTIVER COMPLÈTEMENT LE SPAWNER AUTOMATIQUE
# Commenter ou supprimer _ready() et _process()

func _ready():
	# COMMENTÉ - Plus de spawn automatique
	# spawn_weapon()
	print("WeaponSpawner disabled - weapons only drop from enemies now")

func _process(delta):
	# COMMENTÉ - Plus de spawn par timer
	# spawn_timer += delta
	# if spawn_timer >= spawn_interval and weapons_on_ground.size() < max_weapons_on_ground:
	#     spawn_weapon()
	#     spawn_timer = 0.0
	pass

# Garder les autres méthodes au cas où tu veux les réactiver plus tard
# Mais elles ne seront plus appelées automatiquement
