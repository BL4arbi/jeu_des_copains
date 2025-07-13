# BaseCharacter.gd - Version corrigée
extends CharacterBody2D
class_name BaseCharacter

# Stats
var current_health: float = 100.0
var max_health: float = 100.0
var speed: float = 200.0
var damage: float = 20.0
var poison_stacks: int = 0
var max_poison_stacks: int = 10
var poison_damage_per_stack: float = 1.0
var poison_duration: float = 0.0
var poison_timer: Timer = null

var burn_stacks: int = 0
var max_burn_stacks: int = 5
var burn_damage_per_stack: float = 2.0
var burn_duration: float = 0.0
var burn_timer: Timer = null
# Animation et affichage
var is_moving: bool = false
var last_direction: Vector2 = Vector2.RIGHT

# Composants
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")

# Signaux
signal health_changed(current_health: float, max_health: float)
signal died()

func _ready():
	# Initialiser depuis GlobalData si disponible
	if GlobalData and GlobalData.player_stats.size() > 0:
		var data = GlobalData.player_stats
		max_health = data.get("health", 100)
		current_health = max_health
		speed = data.get("speed", 200)
		damage = data.get("damage", 20)
	
	# Initialiser la health bar
	update_health_bar()

func _physics_process(_delta):
	# Vérifier si le personnage bouge
	var was_moving = is_moving
	is_moving = velocity.length() > 10.0
	
	# Mettre à jour la direction si on bouge
	if is_moving:
		last_direction = velocity.normalized()
	
	# Jouer les animations appropriées
	if was_moving != is_moving:
		update_animation()

func update_animation():
	if not animation_player:
		return
	
	if is_moving:
		if animation_player.has_animation("walk"):
			animation_player.play("walk")
	else:
		if animation_player.has_animation("idle"):
			animation_player.play("idle")

func update_sprite_direction():
	if sprite and is_moving:
		# Flip horizontal selon la direction
		sprite.flip_h = last_direction.x < 0

func take_damage(amount: float):
	var old_health = current_health
	current_health = max(0, current_health - amount)
	
	print(name, " took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Flash de dégâts
	flash_damage()
	
	# Émettre le signal
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and old_health > 0:
		die()

func heal(amount: float):
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	if current_health != old_health:
		health_changed.emit(current_health, max_health)

func flash_damage():
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func update_health_bar():
	if health_bar:
		var health_percent = (current_health / max_health) * 100 if max_health > 0 else 0
		health_bar.value = health_percent
		
		# Couleur selon la vie
		if health_percent > 60:
			health_bar.modulate = Color.GREEN
		elif health_percent > 30:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED
		
		# Masquer si vie pleine
		health_bar.visible = current_health < max_health

func die():
	print("Character died!")
	died.emit()
	
	# Animation de mort si disponible
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	queue_free()
func apply_poison_effect(duration: float, power: float):
	# Ajouter une stack de poison
	poison_stacks = min(poison_stacks + 1, max_poison_stacks)
	poison_duration = max(poison_duration, duration)  # Prendre la plus longue durée
	
	print("☠️ ", name, " poisoned! Stack: ", poison_stacks, "/", max_poison_stacks)
	
	# Démarrer/redémarrer le timer de poison
	setup_poison_timer()
	
	# Effet visuel selon le nombre de stacks
	update_poison_visual()

func setup_poison_timer():
	# Nettoyer l'ancien timer
	if poison_timer and is_instance_valid(poison_timer):
		poison_timer.queue_free()
	
	# Créer le nouveau timer
	poison_timer = Timer.new()
	add_child(poison_timer)
	poison_timer.wait_time = 0.5  # Dégâts toutes les 0.5 secondes
	poison_timer.timeout.connect(_on_poison_tick)
	poison_timer.start()
	
	# Timer pour la durée totale
	var duration_timer = Timer.new()
	add_child(duration_timer)
	duration_timer.wait_time = poison_duration
	duration_timer.one_shot = true
	duration_timer.timeout.connect(_on_poison_end)
	duration_timer.start()

func _on_poison_tick():
	if poison_stacks <= 0:
		return
	
	# Calculer les dégâts totaux
	var total_poison_damage = poison_stacks * poison_damage_per_stack
	take_damage(total_poison_damage)
	
	# Effet visuel de dégâts de poison
	show_poison_damage_number(total_poison_damage)
	
	print("☠️ Poison tick: ", total_poison_damage, " damage (", poison_stacks, " stacks)")

func _on_poison_end():
	print("☠️ Poison effect ended for ", name)
	poison_stacks = 0
	poison_duration = 0.0
	
	if poison_timer and is_instance_valid(poison_timer):
		poison_timer.queue_free()
		poison_timer = null
	
	# Retirer l'effet visuel
	if sprite and is_instance_valid(sprite):
		sprite.modulate = Color.WHITE

func update_poison_visual():
	if not sprite or not is_instance_valid(sprite):
		return
	
	# Intensité verte selon le nombre de stacks
	var green_intensity = 1.0 + (poison_stacks * 0.2)  # Plus de stacks = plus vert
	var color = Color(0.8, green_intensity, 0.8, 1.0)
	sprite.modulate = color
	
	# Créer des particules de poison pour les hautes stacks
	if poison_stacks >= 5:
		create_poison_particles()

func create_poison_particles():
	for i in range(3):
		var particle = Sprite2D.new()
		get_tree().current_scene.add_child(particle)
		
		var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		image.fill(Color.GREEN)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		particle.texture = texture
		
		particle.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		# Animation flottante
		var tween = create_tween()
		tween.parallel().tween_property(particle, "position:y", particle.position.y - 30, 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): particle.queue_free())

func show_poison_damage_number(damage_amount: float):
	var damage_label = Label.new()
	damage_label.text = "-" + str(int(damage_amount))
	damage_label.add_theme_color_override("font_color", Color.GREEN)
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.position = global_position + Vector2(randf_range(-15, 15), -40)
	
	get_tree().current_scene.add_child(damage_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position:y", damage_label.position.y - 30, 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): damage_label.queue_free())

# NOUVEAU : Méthode pour appliquer des brûlures cumulables
func apply_burn_effect(duration: float, power: float):
	# Ajouter une stack de brûlure
	burn_stacks = min(burn_stacks + 1, max_burn_stacks)
	burn_duration = max(burn_duration, duration)
	
	print("🔥 ", name, " burning! Stack: ", burn_stacks, "/", max_burn_stacks)
	
	# Même système que le poison mais pour les brûlures
	setup_burn_timer()
	update_burn_visual()

func setup_burn_timer():
	if burn_timer and is_instance_valid(burn_timer):
		burn_timer.queue_free()
	
	burn_timer = Timer.new()
	add_child(burn_timer)
	burn_timer.wait_time = 0.7  # Un peu plus lent que le poison
	burn_timer.timeout.connect(_on_burn_tick)
	burn_timer.start()
	
	var duration_timer = Timer.new()
	add_child(duration_timer)
	duration_timer.wait_time = burn_duration
	duration_timer.one_shot = true
	duration_timer.timeout.connect(_on_burn_end)
	duration_timer.start()

func _on_burn_tick():
	if burn_stacks <= 0:
		return
	
	var total_burn_damage = burn_stacks * burn_damage_per_stack
	take_damage(total_burn_damage)
	
	show_burn_damage_number(total_burn_damage)
	print("🔥 Burn tick: ", total_burn_damage, " damage (", burn_stacks, " stacks)")

func _on_burn_end():
	print("🔥 Burn effect ended for ", name)
	burn_stacks = 0
	burn_duration = 0.0
	
	if burn_timer and is_instance_valid(burn_timer):
		burn_timer.queue_free()
		burn_timer = null
	
	if sprite and is_instance_valid(sprite):
		sprite.modulate = Color.WHITE

func update_burn_visual():
	if not sprite or not is_instance_valid(sprite):
		return
	
	var red_intensity = 1.0 + (burn_stacks * 0.3)
	var color = Color(red_intensity, 0.8, 0.8, 1.0)
	sprite.modulate = color

func show_burn_damage_number(damage_amount: float):
	var damage_label = Label.new()
	damage_label.text = "-" + str(int(damage_amount))
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.position = global_position + Vector2(randf_range(-15, 15), -40)
	
	get_tree().current_scene.add_child(damage_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position:y", damage_label.position.y - 30, 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): damage_label.queue_free())

# MÉTHODE pour obtenir les stacks (pour debug ou UI)
func get_status_stacks() -> Dictionary:
	return {
		"poison": poison_stacks,
		"burn": burn_stacks,
		"max_poison": max_poison_stacks,
		"max_burn": max_burn_stacks
	}
