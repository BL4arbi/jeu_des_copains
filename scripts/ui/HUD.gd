# HUD.gd
extends Control

@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var kill_counter: Label = get_node_or_null("KillCounter")
@onready var level_info: Label = get_node_or_null("LevelInfo")

var player: Player

func _ready():
	player = get_tree().get_first_node_in_group("players")
	GlobalData.kill_count_updated.connect(_on_kill_count_updated)

func _on_kill_count_updated(new_count: int):
	if kill_counter:
		kill_counter.text = "Kills: " + str(new_count)

func _process(_delta):
	update_inventory()
func update_inventory():
	if not player:
		return
	
	for i in range(5):
		var slot = get_node_or_null("InventoryContainer/Slot" + str(i+1))
		if slot:
			var icon = slot.get_node_or_null("WeaponIcon")
			if icon and i < player.weapons.size():
				# Couleur selon l'arme
				var weapon = player.weapons[i]
				var image = Image.create(50, 50, false, Image.FORMAT_RGB8)
				match weapon.projectile_name:
					"Tir Basique": image.fill(Color.WHITE)
					"Tir Rapide": image.fill(Color.YELLOW)
					"Canon Lourd": image.fill(Color.RED)
					_: image.fill(Color.GRAY)
				
				var texture = ImageTexture.new()
				texture.set_image(image)
				icon.texture = texture
				
				# Sélection
				icon.modulate = Color.WHITE if i == player.current_weapon else Color.GRAY
			elif icon:
				icon.texture = null
