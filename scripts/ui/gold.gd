extends Label

func _process(delta: float) -> void:
	text = "Gold : " + str(SaveDataa.gold)
