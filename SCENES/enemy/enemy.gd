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
var poison_tick_rate = 1.0  # Dégâts chaque seconde
var poison_timer = 0.0

func _ready():
	current_health = max_health
	add_to_group("ennemi")
	
	# Configuration des couches
	collision_layer = 2
	collision_mask = 1
	
	print("=== ENNEMI CRÉÉ : ", name, " ===")
	print("Collision Layer : ", collision_layer)
	print("Collision Mask : ", collision_mask)
	
	# Connecter Area2D pour détecter les projectiles
	if has_node("Area2D"):
		$Area2D.collision_layer = 2
		$Area2D.collision_mask = 3
		$Area2D.body_entered.connect(_on_area_2d_body_entered)
		print("Area2D ennemi - Layer: ", $Area2D.collision_layer, " Mask: ", $Area2D.collision_mask)
	else:
		print("ERREUR : Area2D non trouvé sur ennemi !")
	
	# Trouver le joueur
	find_player()
	print("=============================")

func _physics_process(delta):
	# === GESTION DU POISON ===
	if is_poisoned:
		poison_timer += delta
		poison_duration -= delta
		
		# Appliquer dégâts de poison
		if poison_timer >= poison_tick_rate:
			take_poison_damage()
			poison_timer = 0.0
		
		# Vérifier si le poison s'arrête
		if poison_duration <= 0:
			cure_poison()
	
	# === MOUVEMENT VERS LE JOUEUR ===
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
	
	print(name, " est empoisonné ! ", damage_per_tick, " dégâts/sec pendant ", duration, "s")
	
	# Effet visuel poison (vert)
	flash_poison()

func take_poison_damage():
	current_health -= poison_damage
	print(name, " : -", poison_damage, " HP (poison) | Vie: ", current_health)
	
	# Effet visuel poison
	flash_poison()
	
	if current_health <= 0:
		die()

func cure_poison():
	is_poisoned = false
	poison_duration = 0.0
	poison_timer = 0.0
	print(name, " n'est plus empoisonné")
	
	# Retour à la couleur normale
	modulate = Color.WHITE

func take_damage(damage_amount):
	current_health -= damage_amount
	print(name, " : -", damage_amount, " HP (normal) | Vie: ", current_health)
	
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
		# Chercher le joueur dans la scène parent
		var parent = get_parent()
		for child in parent.get_children():
			if child.is_in_group("player"):
				player = child
				break

func _on_area_2d_body_entered(body):
	if body.is_in_group("bullet"):
		print("Détection projectile sur ", name)
		
		# Vérifier le type de projectile
		if body.has_method("is_poison_bullet") and body.is_poison_bullet():
			# Balle poison
			if body.has_method("get_damage"):
				take_damage(body.get_damage())
			if body.has_method("apply_poison"):
				apply_poison(body.poison_damage, body.poison_duration)
			body.queue_free()
			
		elif body.has_method("is_thunder_bolt") and body.is_thunder_bolt():
			# Thunder Bolt - IGNORER complètement, il gère ses propres dégâts
			print("Thunder Bolt ignoré par l'ennemi")
			
		else:
			# Balle normale
			take_damage(body.get_damage() if body.has_method("get_damage") else 25)
			body.queue_free()
