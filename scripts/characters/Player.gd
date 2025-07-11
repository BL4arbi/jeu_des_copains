# Player.gd
extends BaseCharacter
class_name Player

var weapons: Array[ProjectileData] = []
var current_weapon: int = 0
var fire_timer: float = 0.0

func _ready():
	super._ready()
	add_to_group("players")
	
	var basic_weapon = ProjectileData.new()
	basic_weapon.projectile_name = "Tir Basique"
	basic_weapon.damage = 10.0
	basic_weapon.speed = 500.0
	basic_weapon.fire_rate = 0.3
	basic_weapon.lifetime = 5.0
	basic_weapon.projectile_scene_path = "res://scenes/projectiles/BasicProjectile.tscn"
	weapons.append(basic_weapon)

func _physics_process(delta):
	handle_movement()
	handle_shooting(delta)
	handle_weapon_switch()
	handle_sprite_rotation()

func handle_movement():
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1
	if Input.is_action_pressed("weapon_1"):
		current_weapon=0
	if Input.is_action_pressed("weapon_2"):
		current_weapon=1
	if Input.is_action_pressed("weapon_3"):
		current_weapon=2
	if Input.is_action_pressed("weapon_4"):
		current_weapon=3
	if Input.is_action_pressed("weapon_5"):
		current_weapon=4
	
	input_direction = input_direction.normalized()
	velocity = input_direction * speed
	move_and_slide()

func handle_shooting(delta):
	fire_timer += delta
	
	if weapons.size() == 0:
		return
	
	var current_fire_rate = weapons[current_weapon].fire_rate
	
	if (Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_timer >= current_fire_rate:
		fire_projectile()
		fire_timer = 0.0


func handle_sprite_rotation():
	if sprite:
		var mouse_pos = get_global_mouse_position()
		# Juste flip horizontal, pas de rotation
		sprite.flip_h = mouse_pos.x < global_position.x

func fire_projectile():
	var weapon = weapons[current_weapon]
	var mouse_pos = get_global_mouse_position()
	
	var projectile_scene = load(weapon.projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.setup(weapon.damage, weapon.speed, weapon.lifetime, "player")
	var spawn_offset = (mouse_pos - global_position).normalized() * 30
	projectile.launch(global_position + spawn_offset, mouse_pos)
func handle_weapon_switch():
	# Flèche haut pour cycler
	if Input.is_action_just_pressed("ui_up") and weapons.size() > 1:
		current_weapon = (current_weapon + 1) % weapons.size()
		print("Switched to: ", weapons[current_weapon].projectile_name)
	
	# Touches 1-5
	if Input.is_action_just_pressed("ui_accept"):
		if Input.is_key_pressed(KEY_1): current_weapon = 0
		elif Input.is_key_pressed(KEY_2) and weapons.size() > 1: current_weapon = 1
		elif Input.is_key_pressed(KEY_3) and weapons.size() > 2: current_weapon = 2

func pickup_weapon(weapon_data: ProjectileData):
	for weapon in weapons:
		if weapon.projectile_name == weapon_data.projectile_name:
			return false
	
	weapons.append(weapon_data)
	print("Added weapon: ", weapon_data.projectile_name)
	return true
