# BaseEnemy.gd
extends CharacterBody2D
class_name BaseEnemy

# Stats de l'ennemi
var max_health: float = 50.0
var current_health: float = 50.0
var speed: float = 100.0
var damage: float = 10.0
var can_shoot: bool = false
var projectile_scene_path: String = ""
var fire_rate: float = 2.0
var detection_range: float = 300.0
var melee_range: float = 50.0
var is_elite: bool = false
var enemy_type: String = "Grunt"

# Variables pour les shooters
var optimal_distance: float = 200.0  # Distance idéale pour tirer
var dodge_timer: float = 0.0
var dodge_cooldown: float = 2.0
var dodge_direction: Vector2 = Vector2.ZERO

# Composants
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var area_detector: Area2D = $Area2D
@onready var area_collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")

# Variables d'état
var target: Player
var fire_timer: float = 0.0

func _ready():
	add_to_group("enemies")
	current_health = max_health
	
	target = get_tree().get_first_node_in_group("players")
	
	if area_detector:
		area_detector.body_entered.connect(_on_hit_player)
	
	if animation_player and animation_player.has_animation("walk"):
		animation_player.play("walk")
	
	update_health_bar()

func _physics_process(delta):
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		
		# Comportement selon le type d'ennemi
		match enemy_type:
			"Grunt":
				basic_behavior(delta, distance)
			"Shooter":
				shooter_behavior(delta, distance)
			"Elite":
				elite_behavior(delta, distance)

func basic_behavior(delta, distance):
	# Fonce droit vers le joueur pour attaque au corps à corps
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if sprite:
		sprite.flip_h = direction.x < 0

func shooter_behavior(delta, distance):
	dodge_timer += delta
	
	if distance > optimal_distance:
		# Trop loin - se rapprocher
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	elif distance < optimal_distance - 50:
		# Trop proche - reculer
		var direction = (global_position - target.global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		# À bonne distance - bouger aléatoirement pour esquiver
		if dodge_timer >= dodge_cooldown:
			# Nouveau mouvement d'esquive
			var random_angle = randf() * TAU
			dodge_direction = Vector2(cos(random_angle), sin(random_angle))
			dodge_timer = 0.0
		
		# Mouvement d'esquive
		velocity = dodge_direction * speed * 0.6  # Plus lent en esquive
		move_and_slide()
	
	# Tirer si à bonne distance
	if distance <= optimal_distance + 50 and can_shoot:
		handle_shooting(delta)
	
	# Flip du sprite
	if sprite:
		var direction_to_player = (target.global_position - global_position).normalized()
		sprite.flip_h = direction_to_player.x < 0

func elite_behavior(delta, distance):
	if distance > melee_range + 20:
		# Se rapprocher pour attaque au corps à corps (plus de dégâts)
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		# À portée - arrêter de bouger
		velocity = Vector2.ZERO
	
	# Tirer aussi si pas trop proche
	if distance > 80 and distance < 300 and can_shoot:
		handle_shooting(delta)
	
	if sprite:
		var direction = (target.global_position - global_position).normalized()
		sprite.flip_h = direction.x < 0

func handle_shooting(delta):
	if not target or projectile_scene_path == "":
		return
		
	fire_timer += delta
	
	if fire_timer >= fire_rate:
		shoot_at_player()
		fire_timer = 0.0

func shoot_at_player():
	var projectile_scene = load(projectile_scene_path)
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	# Dégâts selon le type
	var projectile_damage = damage * 0.8 if enemy_type == "Shooter" else damage * 0.6
	projectile.setup(projectile_damage, 250.0, 4.0)
	
	var direction = (target.global_position - global_position).normalized()
	var spawn_pos = global_position + direction * 30
	
	projectile.launch(spawn_pos, target.global_position)
	

func take_damage(amount: float):
	current_health = max(0, current_health - amount)
	
	print(name, " took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	flash_damage()
	update_health_bar()
	
	if current_health <= 0:
		die()

func flash_damage():
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func update_health_bar():
	if health_bar:
		health_bar.value = (current_health / max_health) * 100

func die():
	print(name, " died!")
	
	if is_elite:
		GlobalData.total_kills += 3
	else:
		GlobalData.add_kill()
	
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	queue_free()

func _on_hit_player(body):
	if body.is_in_group("players") and body.has_method("take_damage"):
		# Dégâts de mêlée plus élevés pour l'élite
		var melee_damage = damage * 1.5 if is_elite else damage
		body.take_damage(melee_damage)
		print(name, " hit player for ", melee_damage, " melee damage!")
