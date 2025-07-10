extends CharacterBody2D

@export var speed: float = 80.0
@export var chase_range: float = 500.0
@export var player: CharacterBody2D
@export var max_health = 100
var current_health

# Variables pour le poison
var is_poisoned = false
var poison_damage = 5
var poison_duration = 0.0
var poison_tick_rate = 1.0
var poison_timer = 0.0

# Barre de vie
var health_bar: ProgressBar

func _ready():
	current_health = max_health
	add_to_group("ennemi")
	
	# Configuration des couches
	collision_layer = 2
	collision_mask = 1
	
	# Créer la barre de vie adaptée au sprite
	create_smart_health_bar()
	
	# Connecter Area2D
	if has_node("Area2D"):
		$Area2D.collision_layer = 2
		$Area2D.collision_mask = 3
		$Area2D.body_entered.connect(_on_area_2d_body_entered)
	
	find_player()
	print("Ennemi créé avec ", max_health, " HP")

func create_smart_health_bar():
	# Barre de vie VERTICALE petite
	health_bar = ProgressBar.new()
	health_bar.rotation_degrees = 90
	health_bar.size = Vector2(4, 20)  # 4 pixels large, 20 pixels haut
	health_bar.position = Vector2(-2, -25)  # Centrée au-dessus de la tête
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP  # Se remplit du bas vers le haut
	
	# Style SIMPLE
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Fond gris foncé
	health_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color.GREEN
	health_bar.add_theme_stylebox_override("fill", style_fill)
	
	add_child(health_bar)
	update_health_bar()
	print("Barre de vie VERTICALE créée : 4x20 pixels")

func update_health_bar():
	if health_bar:
		# Calculer le pourcentage de vie
		var health_percentage = (float(current_health) / float(max_health)) * 100.0
		health_bar.value = max(0, health_percentage)
		
		# Couleur selon la vie
		var style_fill = StyleBoxFlat.new()
		if health_percentage > 60:
			style_fill.bg_color = Color.GREEN
		elif health_percentage > 30:
			style_fill.bg_color = Color.YELLOW
		else:
			style_fill.bg_color = Color.RED
		
		health_bar.add_theme_stylebox_override("fill", style_fill)

func _physics_process(delta):
	# Gestion du poison
	if is_poisoned:
		poison_timer += delta
		poison_duration -= delta
		
		if poison_timer >= poison_tick_rate:
			take_poison_damage()
			poison_timer = 0.0
		
		if poison_duration <= 0:
			cure_poison()
	
	# Mouvement
	if player == null:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player < chase_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func apply_poison(damage_per_tick: int, duration: float):
	is_poisoned = true
	poison_damage = damage_per_tick
	poison_duration = duration
	poison_timer = 0.0
	
	print(name, " empoisonné: ", damage_per_tick, " dmg/sec pendant ", duration, "s")
	flash_poison()

func take_poison_damage():
	current_health -= poison_damage
	current_health = max(0, current_health)
	
	print(name, " : -", poison_damage, " HP (POISON) | Vie: ", current_health, "/", max_health)
	
	update_health_bar()
	flash_poison()
	
	if current_health <= 0:
		die()

func cure_poison():
	is_poisoned = false
	poison_duration = 0.0
	poison_timer = 0.0
	print(name, " n'est plus empoisonné")
	modulate = Color.WHITE

func take_damage(damage_amount):
	current_health -= damage_amount
	current_health = max(0, current_health)
	
	print(name, " : -", damage_amount, " HP | Vie: ", current_health, "/", max_health)
	
	update_health_bar()
	flash_red()
	
	if current_health <= 0:
		die()

func die():
	print("*** ", name, " EST MORT ! ***")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func flash_red():
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func flash_poison():
	modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func find_player():
	if player == null:
		var parent = get_parent()
		for child in parent.get_children():
			if child.is_in_group("player"):
				player = child
				break

func apply_knockback(force: Vector2):
	velocity += force

func _on_area_2d_body_entered(body):
	# Les projectiles gèrent eux-mêmes les dégâts
	pass
