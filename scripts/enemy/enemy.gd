#enemy
extends CharacterBody2D
@export var player : CharacterBody2D
@onready var agent = $NavigationAgent2D  # ✅ CORRECTION: NavigationAgent2D pas NavigationLink2D
var damage_popup_node = preload("res://scene/Damage.tscn")
var direction : Vector2
var speed : float = 75
var damage : float = 0
var separation : float
var knockback : Vector2
var home_position : Vector2
var target : Node2D = null
var drop = preload("res://scene/pickups.tscn")

var health : float : 
	set(value):
		health = value 
		if health <= 0:
			drop_item()
			queue_free()

var elite : bool = false:
	set(value):
		elite = value
		if value:
			$Sprite2D.material = load("res://assets/shader/elite.tres")
			scale = Vector2(1.5, 1.5)

var type : Enemy:
	set(value):
		type = value
		$Sprite2D.texture = value.texture
		damage = value.damage
		health = value.health

func set_target(new_player: CharacterBody2D):
	target = new_player
	if target and agent:
		agent.set_target_position(target.global_position)
		print("Enemy target set to: ", target.name if target else "null")
	elif agent:
		agent.set_target_position(home_position)
		print("Enemy returning home")

func clear_target():
	target = null
	if agent:
		agent.set_target_position(home_position)
		print("Enemy cleared target, returning home")

func check_separation(_delta):
	if not player:
		return
	separation = (player.position - position).length()
	if separation >= 500 and not elite:
		queue_free()
	if separation < player.nearest_enemy_distance:
		player.nearest_enemy = self

func _physics_process(delta):
	# Vérifier que agent existe
	if not agent:
		return
	
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) > 500:
			clear_target()
		else:
			agent.set_target_position(target.global_position)
	elif global_position.distance_to(home_position) > 10:
		agent.set_target_position(home_position)
	
	# Navigation
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_path_point = agent.get_next_path_position()
		direction = (next_path_point - global_position).normalized()
		velocity = direction * speed
	
	move_and_slide()

func knockback_update(delta):
	if not player:
		return
	velocity = (player.position - position).normalized() * speed
	knockback = knockback.move_toward(Vector2.ZERO, 1)
	velocity += knockback
	var collider = move_and_collide(velocity * delta)
	if collider:
		collider.get_collider().knockback = (collider.get_collider().global_position - global_position).normalized() * 50

func damage_popup(amount):
	var popup = damage_popup_node.instantiate() 
	popup.text = str(amount) 
	popup.position = position + Vector2(-50, -25)
	get_tree().current_scene.add_child(popup)

func take_damage(amount):
	var tween = get_tree().create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(3, 0.25, 0.25), 0.2)
	tween.chain().tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.2)
	tween.bind_node(self)
	damage_popup(amount)
	health -= amount

func drop_item():
	if not type or type.drops.size() == 0:
		return 
	var item = type.drops.pick_random()
	if elite:
		item = load("res://ressource/drop/Chest.tres")
	var item_to_drop = drop.instantiate() 
	
	item_to_drop.type = item 
	item_to_drop.position = position 
	item_to_drop.player = player 
	
	get_tree().current_scene.call_deferred("add_child", item_to_drop)
func _ready() -> void:
	add_to_group("enemy")
