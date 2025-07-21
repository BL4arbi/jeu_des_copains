extends TextureButton

@export var skill : Skill
var enabled : bool = false :
		set(value):
			enabled = value
			$Panel.show_behind_parent = value
func _ready():
	if skill :
		texture_normal = skill.texture 

func is_upgradable()->bool :
	if get_index()==0:
		return true
	elif get_index() > 0:
		if get_parent().get_child(get_index() -1).enabled == true :
			return true 
		else :
			return false 
	return false 
	


func _on_pressed() -> void:
	
	if skill.cost <= SaveDataa.gold and is_upgradable() and not enabled :
		
		SaveDataa.gold -= skill.cost
		enabled = true
		get_parent().get_parent().set_skill_tree()
		get_parent().get_parent().get_total_stats()
