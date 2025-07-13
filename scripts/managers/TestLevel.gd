# TestLevel.gd - Ajout du nettoyage automatique
extends Node2D

# Références aux éléments de la scène
@onready var player: Player = get_node_or_null("Player")
@onready var hud: Control = get_node_or_null("CanvasLayer/HUD")
@onready var health_bar: ProgressBar = get_node_or_null("CanvasLayer/HUD/HealthBar")
@onready var kill_counter: Label = get_node_or_null("CanvasLayer/HUD/KillCounter")
@onready var level_info: Label = get_node_or_null("CanvasLayer/HUD/LevelInfo")

# Timer de nettoyage local
var local_cleanup_timer: Timer

func _ready():
	print("=== TestLevel Ready ===")
	print("GlobalData player_stats: ", GlobalData.player_stats)
	
	if player:
		print("Player found in scene!")
		center_player()
		apply_character_stats()
		update_player_sprite()
	else:
		print("ERROR: No Player found in scene!")
	
	# Créer le système de drops
	var drop_system = EnemyDropSystem.new()
	drop_system.name = "DropSystem"
	add_child(drop_system)
	drop_system.add_to_group("drop_system")
	
	print("Drop system created and added to scene")
	
	# AJOUT : Timer de nettoyage local pour ce niveau
	setup_local_cleanup()
	
	update_hud()

func setup_local_cleanup():
	# Timer de nettoyage spécifique à ce niveau
	local_cleanup_timer = Timer.new()
	add_child(local_cleanup_timer)
	local_cleanup_timer.wait_time = 5.0  # Toutes les 5 secondes
	local_cleanup_timer.timeout.connect(_local_cleanup)
	local_cleanup_timer.start()
	
	print("🧹 Local cleanup timer started")

func _local_cleanup():
	# Nettoyage spécifique au niveau
	cleanup_level_sprites()

func cleanup_level_sprites():
	var sprites_removed = 0
	
	# Parcourir tous les enfants du niveau
	var children_to_check = get_children().duplicate()
	
	for child in children_to_check:
		# Sprites orphelins au niveau racine
		if child is Sprite2D:
			if not child.get_parent() is WeaponPickup and not child.get_parent() is BaseProjectile:
				print("🧹 Removing orphaned sprite at level root: ", child.name)
				child.queue_free()
				sprites_removed += 1
		
		# Pickups corrompus
		if child is WeaponPickup:
			if not is_instance_valid(child.sprite) or child.is_being_destroyed:
				print("🧹 Removing corrupted pickup: ", child.weapon_name if child.weapon_name else "Unknown")
				child.queue_free()
				sprites_removed += 1
	
	if sprites_removed > 0:
		print("🧹 Level cleanup: ", sprites_removed, " objects removed")

func center_player():
	var viewport_size = get_viewport().get_visible_rect().size
	var center_position = viewport_size / 2
	player.global_position = center_position
	print("Player centered at: ", center_position)

func apply_character_stats():
	if GlobalData.player_stats.size() > 0:
		var stats = GlobalData.player_stats
		player.max_health = stats.get("health", 100)
		player.current_health = player.max_health
		player.speed = stats.get("speed", 200)
		player.damage = stats.get("damage", 20)
		
		print("Stats applied - Health:", player.max_health, " Speed:", player.speed, " Damage:", player.damage)
	else:
		print("No character selected, using default stats")

func update_player_sprite():
	var character_data = GlobalData.get_character_data(GlobalData.selected_character_id)
	
	if character_data.has("sprite_path") and player.sprite:
		var sprite_path = character_data.sprite_path
		print("Trying to load sprite: ", sprite_path)
		
		if ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			player.sprite.texture = texture
			print("Player sprite loaded successfully!")
		else:
			print("Sprite not found at: ", sprite_path)
			create_colored_sprite()
	else:
		print("No sprite path or player.sprite not found")
		create_colored_sprite()

func create_colored_sprite():
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	
	match GlobalData.selected_character_id:
		0:
			image.fill(Color.RED)
		1:
			image.fill(Color.GREEN)
		2:
			image.fill(Color.BLUE)
		_:
			image.fill(Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	if player.sprite:
		player.sprite.texture = texture
		print("Created colored sprite for character: ", GlobalData.selected_character_id)

func update_hud():
	if not hud:
		print("HUD not found!")
		return
	
	if kill_counter:
		kill_counter.text = "Kills: " + str(GlobalData.total_kills)
	if level_info:
		level_info.text = "Niveau: " + str(GlobalData.current_level)
	
	if player and health_bar:
		var health_percent = (player.current_health / player.max_health) * 100
		health_bar.value = health_percent

func _input(event):
	# AJOUT : Nettoyage manuel avec C
	if Input.is_action_just_pressed("clear"):
		print("🧹 Manual cleanup triggered from TestLevel!")
		
		# Nettoyage local
		cleanup_level_sprites()
		
		# Nettoyage global si le CleanupManager existe
		if has_node("/root/CleanupManager"):
			get_node("/root/CleanupManager").force_cleanup_all()
		
		print("🧹 Manual cleanup complete!")
	
	# Test: K pour ajouter des kills
	if Input.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_K):
		GlobalData.add_kill()
		update_hud()
		print("Kill added! Total:", GlobalData.total_kills)
	
	# Test: Echap pour retourner à la sélection
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/CharacterSelection.tscn")
