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
	var target = get_nearest_enemy()
	if target:
		item.activate(owner, target, get_tree())

func get_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty():
		return null
	
	var nearest = null
	var shortest_distance = INF 
	var max_range = 80
	
	for enemy in enemies:
		var distance = owner.global_position.distance_to(enemy.global_position)
		if distance < shortest_distance and distance <= max_range:
			shortest_distance = distance
			nearest = enemy
	
	return nearest
