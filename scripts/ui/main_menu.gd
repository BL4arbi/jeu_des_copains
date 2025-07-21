extends Control

func _ready():
	menu()

func _on_back_pressed():
	menu()

func menu():
	$Menu.show()
	$SkillTree.hide()
	$Gold.hide()
	$Bestiary.hide()
	$Back.hide()
	tween_pop($Menu)

func skill_tree():
	$SkillTree.show()
	$Gold.show()
	$Menu.hide()
	$Back.show()
	tween_pop($SkillTree)
	


func tween_pop(panel):
	panel.scale = Vector2(0.85,0.85)
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(panel, "scale", Vector2(1,1), 0.5)



func best():
	$Bestiary.show()
	$Menu.hide()
	$Gold.hide()
	$Back.show()
	tween_pop($Bestiary)

func _on_talent_pressed() -> void:
		skill_tree()



func _on_bestiary_pressed() -> void:
	best()
