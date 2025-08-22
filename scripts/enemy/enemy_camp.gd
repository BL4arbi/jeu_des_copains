extends Node2D
@export var player : CharacterBody2D
@export var enemy : PackedScene
@export var enemy_types : Array[Enemy]
@export var camp_rect : Rect2 
@export var enemy_scene : PackedScene
@export var enemy_count : int = 5
@export var enemies : Node2D

func _ready():
	spawn_enemies()
func spawn_enemies(elite : bool = false):
	var center = camp_rect.position + camp_rect.size / 2
	var radius = min(camp_rect.size.x,camp_rect.size.y)/3.0 
	
	for i in range(enemy_count):
		var angle = (TAU / enemy_count) * i +randf_range(-0.2,0.2)
		var offset = Vector2(cos(angle),sin(angle))*randf_range(radius *0.7,radius)
		var local_pos = center + offset
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.type = enemy_types.pick_random()
		enemy_instance.position = position + local_pos
		enemy_instance.player = player  
		enemy_instance.elite = elite
		enemy_instance.set("home_position",enemy.position)
		enemies.add_child(enemy_instance)

func remove_camp():
	for enemy in enemies.get_children():
		enemy.queue_free()
	queue_free()

func _on_player_body_entered(body: Node2D) -> void:
	if body == player:
		player = body 
		for enemy in enemies.get_children():
			enemy.set_target(player)

func _on_player_body_exited(body: Node2D) -> void:
	if body == player:
		player = null 
		for enemy in enemies.get_children():
			enemy.set_target(player)
