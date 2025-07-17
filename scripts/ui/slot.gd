extends PanelContainer

@export var item : Weapon :
	set(value):
		item = value
		if item:
			$TextureRect.texture = value.texture
			$Cooldown.wait_time = value.cooldown
			item.slot = self

func _on_cooldown_timeout() -> void:
	if not item:
		return
	$Cooldown.wait_time = item.cooldown
	item.activate(owner, owner.nearest_enemy, get_tree())
