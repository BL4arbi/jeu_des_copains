extends Button

func _ready():
	visible = false

func _process(delta: float) -> void:
	if get_tree().paused == true and owner.health <= 0 and visible == false :
		visible = true

func _on_pressed() -> void:
	get_tree().paused = false 
	SaveDataa.gold += owner.gold
	SaveDataa.set_and_save()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
