# BaseCharacter.gd - Version corrigée
extends CharacterBody2D
class_name BaseCharacter

# Stats
var current_health: float = 100.0
var max_health: float = 100.0
var speed: float = 200.0
var damage: float = 20.0

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
