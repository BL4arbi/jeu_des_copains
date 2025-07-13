# TestLevel.gd - Version corrigée avec création simple des systèmes
extends Node2D

# Références aux éléments de la scène
@onready var player: Player = get_node_or_null("Player")
@onready var hud: Control = get_node_or_null("CanvasLayer/HUD")
@onready var health_bar: ProgressBar = get_node_or_null("CanvasLayer/HUD/HealthBar")
@onready var kill_counter: Label = get_node_or_null("CanvasLayer/HUD/KillCounter")
@onready var level_info: Label = get_node_or_null("CanvasLayer/HUD/LevelInfo")

# Systèmes du jeu
var drop_system: EnemyDropSystem
var buff_system: BuffSystem

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
	
	# === CRÉER LES SYSTÈMES DE JEU SIMPLEMENT ===
	setup_game_systems()
	
	# Timer de nettoyage local
	setup_local_cleanup()
	
	# Connecter les signaux
	setup_signals()
	
	update_hud()

func setup_game_systems():
	# === SYSTÈME DE DROPS D'ARMES ===
	drop_system = EnemyDropSystem.new()
	drop_system.name = "DropSystem"
	add_child(drop_system)
	drop_system.add_to_group("drop_system")
	
	# === SYSTÈME DE BUFFS ===
	buff_system = BuffSystem.new()
	buff_system.name = "BuffSystem"
	add_child(buff_system)
	buff_system.add_to_group("buff_system")
	
	print("✅ Drop system created")
	print("⭐ Buff system created")

func setup_signals():
	# Connecter le signal de kill count
	if GlobalData.has_signal("kill_count_updated"):
		GlobalData.kill_count_updated.connect(_on_kill_count_updated)
	
	# Connecter le signal enemy_killed pour les systèmes
	if GlobalData.has_signal("enemy_killed"):
		GlobalData.enemy_killed.connect(_on_enemy_killed)
		print("✅ Enemy killed signal connected")
	else:
		print("❌ WARNING: enemy_killed signal not found in GlobalData!")
	
	# Connecter le signal de santé du joueur
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

# Relayer les morts d'ennemis aux systèmes
func _on_enemy_killed(enemy_type: String, enemy_position: Vector2):
	print("📢 Enemy killed relayed: ", enemy_type, " at ", enemy_position)
	
	# Notifier le système de drops
	if drop_system and drop_system.has_method("_on_enemy_killed"):
		drop_system._on_enemy_killed(enemy_type, enemy_position)
	
	# Notifier le système de buffs
	if buff_system and buff_system.has_method("_on_enemy_killed"):
		buff_system._on_enemy_killed(enemy_type, enemy_position)
		print("⭐ Buff system notified of enemy death")

func _on_kill_count_updated(new_count: int):
	if kill_counter:
		kill_counter.text = "Kills: " + str(new_count)

func _on_player_health_changed(current_health: float, max_health: float):
	if health_bar:
		var health_percent = (current_health / max_health) * 100
		health_bar.value = health_percent

func setup_local_cleanup():
	local_cleanup_timer = Timer.new()
	add_child(local_cleanup_timer)
	local_cleanup_timer.wait_time = 5.0
	local_cleanup_timer.timeout.connect(_local_cleanup)
	local_cleanup_timer.start()
	
	print("🧹 Local cleanup timer started")

func _local_cleanup():
	cleanup_level_sprites()

func cleanup_level_sprites():
	var sprites_removed = 0
	
	# Parcourir tous les enfants du niveau
	var children_to_check = get_children().duplicate()
	
	for child in children_to_check:
		# Vérifier que l'enfant existe encore
		if not is_instance_valid(child):
			continue
		
		# Sprites orphelins au niveau racine
		if child is Sprite2D:
			if not child.get_parent() is WeaponPickup and not child.get_parent() is BaseProjectile:
				print("🧹 Removing orphaned sprite at level root: ", child.name)
				child.queue_free()
				sprites_removed += 1
		
		# Pickups corrompus
		elif child is WeaponPickup:
			var should_remove = false
			
			if not is_instance_valid(child.sprite):
				should_remove = true
				print("🧹 Pickup has invalid sprite")
			
			if "is_being_destroyed" in child and child.is_being_destroyed:
				should_remove = true
				print("🧹 Pickup marked for destruction")
			
			if should_remove:
				var weapon_name = "Unknown"
				if "weapon_name" in child and child.weapon_name:
					weapon_name = child.weapon_name
				print("🧹 Removing corrupted pickup: ", weapon_name)
				child.queue_free()
				sprites_removed += 1
		
		# Nettoyer les Area2D orphelines (projectiles morts)
		elif child is Area2D and not child is WeaponPickup:
			if not child.has_method("_physics_process") or not is_instance_valid(child.get_parent()):
				print("🧹 Removing orphaned Area2D: ", child.name)
				child.queue_free()
				sprites_removed += 1
		
		# Nettoyer les timers orphelins
		elif child is Timer:
			var timer_parent = child.get_parent()
			if not is_instance_valid(timer_parent) or timer_parent == self:
				print("🧹 Removing orphaned timer: ", child.name)
				child.queue_free()
				sprites_removed += 1
		
		# Nettoyer les labels temporaires
		elif child is Label:
			if child.name.begins_with("damage_") or child.position.y < -100:
				print("🧹 Removing temporary label: ", child.name)
				child.queue_free()
				sprites_removed += 1
	
	if sprites_removed > 0:
		print("🧹 Level cleanup: ", sprites_removed, " objects removed")

func force_cleanup_all():
	print("🧹 FORCE CLEANUP ACTIVATED!")
	
	var total_removed = 0
	var children_to_check = get_children().duplicate()
	
	for child in children_to_check:
		if not is_instance_valid(child):
			continue
		
		# Garder seulement les éléments essentiels
		var is_essential = false
		
		if child.name in ["Player", "CanvasLayer", "TileMapLayer", "WeaponSpawner", "EnemySpawner", "DropSystem", "BuffSystem"]:
			is_essential = true
		
		if child.is_in_group("players") or child.is_in_group("essential"):
			is_essential = true
		
		if not is_essential:
			print("🧹 Force removing: ", child.name, " (", child.get_class(), ")")
			child.queue_free()
			total_removed += 1
	
	print("🧹 Force cleanup removed ", total_removed, " objects")

func _input(event):
	# Nettoyage manuel avec C
	if Input.is_action_just_pressed("clear"):
		print("🧹 Manual cleanup triggered from TestLevel!")
		
		cleanup_level_sprites()
		
		if Input.is_key_pressed(KEY_SHIFT):
			print("🧹 SHIFT+C detected - FORCE CLEANUP!")
			force_cleanup_all()
		
		if has_node("/root/WeaponCleanupManager"):
			var cleanup_manager = get_node("/root/WeaponCleanupManager")
			if cleanup_manager.has_method("force_cleanup"):
				cleanup_manager.force_cleanup()
		
		print("🧹 Manual cleanup complete!")
	
	# Test: K pour ajouter des kills
	if Input.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_K):
		GlobalData.add_kill()
		update_hud()
		print("Kill added! Total:", GlobalData.total_kills)
	
	# Test: B pour forcer un buff (pour debug)
	if Input.is_key_pressed(KEY_B) and Input.is_action_just_pressed("ui_accept"):
		if buff_system and player:
			buff_system.force_drop_buff(player.global_position)
			print("🧪 Force dropped buff for testing")
	
	# Test: Echap pour retourner à la sélection
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/CharacterSelection.tscn")

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
		
		# Sauvegarder les stats de base pour les buffs
		player.base_damage = player.damage
		player.base_speed = player.speed
		
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
		0: image.fill(Color.RED)
		1: image.fill(Color.GREEN)
		2: image.fill(Color.BLUE)
		_: image.fill(Color.WHITE)
	
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

func get_game_stats() -> Dictionary:
	var stats = {
		"player_health": player.current_health if player else 0,
		"total_kills": GlobalData.total_kills,
		"active_buffs": 0,
		"active_enemies": get_tree().get_nodes_in_group("enemies").size(),
		"active_projectiles": get_tree().get_nodes_in_group("projectiles").size()
	}
	
	if buff_system:
		stats.active_buffs = buff_system.get_active_buffs().size()
	
	return stats

func _process(_delta):
	# Update continu du HUD
	update_hud()
	
	# Debug stats (optionnel)
	if OS.is_debug_build() and Input.is_key_pressed(KEY_F3):
		var stats = get_game_stats()
		if not has_node("DebugStats"):
			var debug_label = Label.new()
			debug_label.name = "DebugStats"
			debug_label.position = Vector2(10, 150)
			debug_label.add_theme_color_override("font_color", Color.YELLOW)
			add_child(debug_label)
		
		var debug_label = get_node("DebugStats")
		debug_label.text = "DEBUG STATS:\n"
		debug_label.text += "Player HP: " + str(int(stats.player_health)) + "\n"
		debug_label.text += "Kills: " + str(stats.total_kills) + "\n"
		debug_label.text += "Active Buffs: " + str(stats.active_buffs) + "\n"
		debug_label.text += "Enemies: " + str(stats.active_enemies) + "\n"
		debug_label.text += "Projectiles: " + str(stats.active_projectiles)
	elif has_node("DebugStats"):
		get_node("DebugStats").queue_free()
