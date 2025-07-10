extends Node2D

@export var enemy_scene: PackedScene = preload("res://SCENES/enemy/enemy.tscn")
@export var item_scene: PackedScene = preload("res://SCENES/Projectile_Item.tscn")
@export var spawn_interval = 1 # Secondes entre chaque spawn
@export var item_spawn_interval = 4.0
var spawn_timer: Timer
var item_spawn_timer: Timer

func _ready():
	# Créer un timer pour faire apparaître des ennemis
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)
	
	item_spawn_timer = Timer.new()
	item_spawn_timer.wait_time = item_spawn_interval
	item_spawn_timer.timeout.connect(_on_item_spawn_timer_timeout)
	item_spawn_timer.autostart = true
	add_child(item_spawn_timer)

func _on_spawn_timer_timeout():
	# Position aléatoire pour le nouvel ennemi
	var spawn_pos = Vector2(
		randf_range(100, 1000),
		randf_range(100, 600)
	)
	spawn_enemy_at(spawn_pos)

func _on_item_spawn_timer_timeout():
	var item_spawn_pos = Vector2(
		randf_range(100, 1000),
		randf_range(100, 600)
	)
	spawn_item_at(item_spawn_pos)

func spawn_item_at(position: Vector2):
	var item = item_scene.instantiate()
	item.global_position = position
	
	# Système de pourcentages de spawn
	var random_value = randf() * 100  # Valeur entre 0 et 100
	var selected_type: ProjectileItem.ProjectileType
	
	# Définir les pourcentages (total doit faire 100)
	if random_value <= 50:  # 50% de chance
		selected_type = ProjectileItem.ProjectileType.FIRE
	elif random_value <= 80:  # 30% de chance (80 - 50)
		selected_type = ProjectileItem.ProjectileType.POISON
	else:  # 20% de chance (100 - 80)
		selected_type = ProjectileItem.ProjectileType.LIGHTNING
	
	item.projectile_type = selected_type
	
	# Configurer les couches de collision
	if item.has_node("Area2D"):
		item.get_node("Area2D").collision_layer = 4
		item.get_node("Area2D").collision_mask = 1
	
	add_child(item)
	print("Item de type ", ProjectileItem.ProjectileType.keys()[selected_type], " spawné")

func spawn_enemy_at(position: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	
	# FORCER les couches de collision pour l'ennemi
	enemy.collision_layer = 2
	enemy.collision_mask = 1
	
	# Assigner le joueur
	var player = get_node("CharacterBody2D")
	enemy.player = player
	
	add_child(enemy)
	
	# Attendre que l'ennemi soit ajouté, puis configurer l'Area2D
	await get_tree().process_frame
	
	# FORCER les couches pour l'Area2D
	if enemy.has_node("Area2D"):
		enemy.get_node("Area2D").collision_layer = 2
		enemy.get_node("Area2D").collision_mask = 3  # Pour détecter les balles (layer 3)
		print("Area2D configuré pour ", enemy.name)
# AJOUTE ça dans ton script de scène principale (test_zone.gd)

func _input(event):
	# Appuie sur la touche C pour nettoyer tous les sprites orphelins
	if Input.is_action_just_pressed("clear"):  # Touche Escape
		clean_orphan_sprites()

func clean_orphan_sprites():
	var count = 0
	# Chercher tous les Sprite2D orphelins dans la scène
	for node in get_tree().get_nodes_in_group("orphan_sprites"):
		node.queue_free()
		count += 1
	
	# Chercher tous les Line2D orphelins
	var all_nodes = get_tree().current_scene.find_children("*", "Line2D")
	for line in all_nodes:
		if line.get_parent() != get_tree().current_scene:
			line.queue_free()
			count += 1
	
	print("🧹 Nettoyé ", count, " sprites orphelins")
