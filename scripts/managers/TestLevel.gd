# TestLevel.gd
# À attacher au nœud TestLevel dans res://scripts/managers/TestLevel.gd

extends Node2D

# Références aux éléments de la scène
@onready var player: Player = get_node_or_null("Player")
@onready var hud: Control = get_node_or_null("CanvasLayer/HUD")
@onready var health_bar: ProgressBar = get_node_or_null("CanvasLayer/HUD/HealthBar")
@onready var kill_counter: Label = get_node_or_null("CanvasLayer/HUD/KillCounter")
@onready var level_info: Label = get_node_or_null("CanvasLayer/HUD/LevelInfo")
#test
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
	var drop_system = EnemyDropSystem.new()
	drop_system.name = "DropSystem"
	add_child(drop_system)
	drop_system.add_to_group("drop_system")
	
	print("Drop system created and added to scene")
	update_hud()

func center_player():
	# Centrer le joueur à l'écran
	var viewport_size = get_viewport().get_visible_rect().size
	var center_position = viewport_size / 2
	player.global_position = center_position
	print("Player centered at: ", center_position)

func apply_character_stats():
	# Appliquer les stats du personnage sélectionné
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
	# Mettre à jour le sprite du joueur
	var character_data = GlobalData.get_character_data(GlobalData.selected_character_id)
	
	if character_data.has("sprite_path") and player.sprite:
		var sprite_path = character_data.sprite_path
		print("Trying to load sprite: ", sprite_path)
		
		if ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			player.sprite.texture = texture
			#player.sprite.scale = Vector2(0.5, 0.5)  # Ajuster la taille si nécessaire
			print("Player sprite loaded successfully!")
		else:
			print("Sprite not found at: ", sprite_path)
			create_colored_sprite()
	else:
		print("No sprite path or player.sprite not found")
		create_colored_sprite()

func create_colored_sprite():
	# Créer un rectangle coloré selon le personnage
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	
	match GlobalData.selected_character_id:
		0:  # Guerrier - Rouge
			image.fill(Color.RED)
		1:  # Archer - Vert
			image.fill(Color.GREEN)
		2:  # Mage - Bleu
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
	
	# Mettre à jour la barre de vie
	if player and health_bar:
		var health_percent = (player.current_health / player.max_health) * 100
		health_bar.value = health_percent

func _input(_event):
	# Test: K pour ajouter des kills
	if Input.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_K):
		GlobalData.add_kill()
		update_hud()
		print("Kill added! Total:", GlobalData.total_kills)
	
	# Test: Echap pour retourner à la sélection
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/CharacterSelection.tscn")
