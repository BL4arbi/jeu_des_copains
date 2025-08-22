extends CharacterBody2D


var health : float = 100:
	set(value):
		health = max(value, 0)
		%Health.value = value
		if health <=0:
			get_tree().paused = true
var movement_speed : float = 150
var max_health : float = 100 :
	set(value):
		max_health = value
		%Health.max_value = value
var recovery : float = 0
var armor : float = 0
var might : float = 1.0:
	set(value):
		might = value 
		%Might.text = "M : " + str(value) 
	
	
var area : float = 0
var magnet : float  = 0:
	set(value):
		magnet = value
		%Magnet.shape.radius = 50 + value
var growth : float = 1


var nearest_enemy : CharacterBody2D
var nearest_enemy_distance : float = 150 + area

var XP : int = 0:
	set(value):
		XP = value
		%XP.value = value
var total_XP : int = 0
var level : int = 1:
	set(value):
		level = value
		%Level.text = "Lv " + str(value)
		%Options.show_options()
		
		if level >= 3:
			%XP.max_value = 20
		elif level >= 7:
			%XP.max_value = 40

var gold : int = 0 :
	set(value):
		gold = value 
		%Gold.text = "Gold : " + str(value)

func _physics_process(delta):
	if is_instance_valid(nearest_enemy):
		nearest_enemy_distance = nearest_enemy.separation
	else:
		nearest_enemy_distance = 150 + area
		nearest_enemy = null
	
	velocity = Input.get_vector("move_left","move_right","move_up","move_down") * movement_speed
	move_and_collide(velocity * delta)
	check_XP()
	health += recovery * delta

func take_damage(amount):
	health -= max(amount *(amount/(amount+armor)) , 1)




func _ready():
	Persistencee.gain_bonus_stats(self)
	add_to_group("player")
	
func _on_timer_timeout():
	%Collision.set_deferred("disabled", true)
	%Collision.set_deferred("disabled", false)

func gain_XP(amount):
	XP += amount * growth
	total_XP += amount * growth

func check_XP():
	if XP > %XP.max_value:
		XP -= %XP.max_value
		level += 1


func _on_magnet_area_entered(area):
	if area.has_method("follow"):
		area.follow(self)
func gain_gold(amount):
	gold+=amount
func open_chest():
	$UI/Chest.open()
	
	


func _on_selfdamage_body_entered(body: Node2D) -> void:
	print('contact')
	take_damage(body.damage)
