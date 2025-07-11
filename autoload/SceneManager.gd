extends Node

var current_scene = null

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(path: String):
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path: String):
	if current_scene:
		current_scene.free()
	
	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

func goto_character_selection():
	goto_scene("res://scenes/ui/CharacterSelection.tscn")

func goto_level(level_id: int):
	var level_path = "res://scenes/levels/Level" + str(level_id) + ".tscn"
	if ResourceLoader.exists(level_path):
		goto_scene(level_path)
	else:
		goto_scene("res://scenes/levels/Level1.tscn")  # Fallback

func goto_main_menu():
	goto_scene("res://scenes/ui/MainMenu.tscn")
