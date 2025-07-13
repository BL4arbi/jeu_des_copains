# BossEnemy.gd - Exemple de Boss avec drops spéciaux
extends BaseEnemy
class_name BossEnemy

# Stats de Boss
var boss_phase: int = 1
var max_phases: int = 3
var phase_health_thresholds: Array = [0.66, 0.33, 0.0]

func _ready():
	super._ready()
	
	# Configuration spéciale de Boss
	enemy_type = "Boss"
	is_elite = true
	
	# Stats de Boss
	max_health = 300.0
	current_health = max_health
	speed = 40.0  # Plus lent mais résistant
	damage = 15.0
	
	# Ajouts spéciaux
	add_to_group("bosses")
	
	print("=== BOSS SPAWNED ===")
	print("Boss Health: ", max_health)

func _physics_process(delta):
	super._physics_process(delta)
	
	# Vérifier les changements de phase
	check_phase_transition()

func check_phase_transition():
	var health_ratio = current_health / max_health
	var new_phase = 1
	
	for i in range(phase_health_thresholds.size()):
		if health_ratio <= phase_health_thresholds[i]:
			new_phase = i + 2  # Phase 2, 3, 4...
	
	if new_phase != boss_phase:
		trigger_phase_transition(new_phase)

func trigger_phase_transition(new_phase: int):
	boss_phase = new_phase
	print("🔥 BOSS PHASE ", boss_phase, " ACTIVATED!")
	
	# Effets selon la phase
	match boss_phase:
		2:
			# Phase 2 : Plus rapide, attaques spéciales plus fréquentes
			speed *= 1.3
			special_attack_delay *= 0.7  # Attaques spéciales plus fréquentes
			change_boss_color(Color.ORANGE)
			
		3:
			# Phase 3 : Attaques désespérées, très dangereuses
			speed *= 1.5
			damage *= 1.4
			special_attack_delay *= 0.5
			change_boss_color(Color.RED)
			
			# Attaque spéciale de rage
			trigger_rage_mode()

func change_boss_color(color: Color):
	if sprite:
		sprite.modulate = color
		
		# Effet de transition
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)

func trigger_rage_mode():
	print("💀 BOSS RAGE MODE!")
	
	# Attaque spéciale de rage : barrage de projectiles
	for i in range(12):  # 12 projectiles en cercle
		if not ResourceLoader.exists(projectile_scene_path):
			continue
		
		var projectile_scene = load(projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		
		get_tree().current_scene.add_child(projectile)
		
		if projectile.has_method("set_owner_type"):
			projectile.set_owner_type("enemy")
		
		projectile.setup(damage * 1.5, 400.0, 6.0)
		
		# Direction en cercle
		var angle = (i * PI * 2) / 12
		var direction = Vector2(cos(angle), sin(angle))
		
		var spawn_pos = global_position + direction * 50
		var target_pos = global_position + direction * 500
		
		projectile.launch(spawn_pos, target_pos)
		
		await get_tree().create_timer(0.1).timeout

# Override die() pour drops de Boss
func die():
	print("💀 BOSS DEFEATED!")
	
	# Effet spécial de mort de Boss
	create_boss_death_effect()
	
	# Signaler la mort de Boss (drops garantis)
	signal_enemy_death()
	
	# Bonus spécial pour avoir tué un Boss
	grant_boss_kill_bonus()
	
	# Stats GlobalData
	GlobalData.total_kills += 10  # Boss vaut 10 kills
	if GlobalData.has_method("add_boss_kill"):
		GlobalData.add_boss_kill()
	
	# Animation de mort épique
	if animation_player and animation_player.has_animation("boss_death"):
		animation_player.play("boss_death")
		await animation_player.animation_finished
	
	queue_free()

func create_boss_death_effect():
	# Série d'explosions pour la mort du Boss
	for i in range(8):
		var explosion = Sprite2D.new()
		get_tree().current_scene.add_child(explosion)
		
		# Explosion colorée
		var colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.WHITE]
		var explosion_color = colors[i % colors.size()]
		
		var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(explosion_color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		explosion.texture = texture
		
		# Position aléatoire autour du Boss
		var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
		explosion.global_position = global_position + offset
		
		# Animation d'explosion avec délai
		var tween = create_tween()
		var delay = i * 0.2
		
		tween.tween_delay(delay)
		tween.parallel().tween_property(explosion, "scale", Vector2(4, 4), 0.6)
		tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.6)
		tween.tween_callback(func(): explosion.queue_free())

func grant_boss_kill_bonus():
	# Bonus spéciaux pour avoir tué un Boss
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("heal"):
		# Soins complets
		player.heal(player.max_health)
		print("🎉 Boss kill bonus: Full heal!")
	
	# Bonus de chance de drop temporaire
	var drop_system = get_tree().get_first_node_in_group("drop_system")
	if drop_system and drop_system.has_method("trigger_elite_kill_bonus"):
		drop_system.trigger_elite_kill_bonus()
		print("🎉 Boss kill bonus: Double drop chance!")

# Attaques spéciales de Boss
func try_special_attack():
	if enemy_type != "Boss":
		return false
	
	# Vérifier le cooldown
	if special_attack_cooldown > 0:
		return false
	
	# Chance selon la phase
	var attack_chance = 0.02 * boss_phase  # Plus fréquent selon la phase
	
	if randf() < attack_chance:
		var attack_type = randi() % 3
		match attack_type:
			0:
				cast_boss_meteor_storm()
			1:
				cast_boss_lightning_field()
			2:
				cast_boss_projectile_spiral()
		
		# Cooldown selon la phase
		special_attack_cooldown = special_attack_delay / boss_phase
		return true
	
	return false

func cast_boss_meteor_storm():
	print("🔥 BOSS METEOR STORM!")
	
	# 5 météores aléatoires
	for i in range(5):
		if not ResourceLoader.exists("res://scenes/projectiles/MeteorProjectile.tscn"):
			continue
		
		var meteor_scene = load("res://scenes/projectiles/MeteorProjectile.tscn")
		var meteor = meteor_scene.instantiate()
		
		get_tree().current_scene.add_child(meteor)
		
		meteor.set_owner_type("enemy")
		meteor.setup(damage * 1.2, 250.0, 8.0)
		
		await get_tree().create_timer(0.4).timeout

func cast_boss_lightning_field():
	print("⚡ BOSS LIGHTNING FIELD!")
	
	# Éclairs en grille
	for x in range(-2, 3):
		for y in range(-2, 3):
			if abs(x) + abs(y) <= 2:  # Pattern en croix
				var lightning_scene = load("res://scenes/projectiles/LightningProjectile.tscn")
				var lightning = lightning_scene.instantiate()
				
				get_tree().current_scene.add_child(lightning)
				
				lightning.set_owner_type("enemy")
				lightning.setup(damage * 0.8, 0.0, 3.0)
				
				var strike_pos = global_position + Vector2(x * 100, y * 100)
				lightning.global_position = strike_pos
				
				await get_tree().create_timer(0.2).timeout

func cast_boss_projectile_spiral():
	print("🌀 BOSS SPIRAL ATTACK!")
	
	# Spirale de projectiles
	for i in range(16):
		var projectile_scene = load(projectile_scene_path)
		var projectile = projectile_scene.instantiate()
		
		get_tree().current_scene.add_child(projectile)
		
		projectile.set_owner_type("enemy")
		projectile.setup(damage * 0.6, 300.0, 5.0)
		
		# Angle en spirale
		var angle = (i * PI * 2 / 4) + (i * 0.3)  # 4 branches qui tournent
		var direction = Vector2(cos(angle), sin(angle))
		
		var spawn_pos = global_position + direction * 60
		var target_pos = global_position + direction * 400
		
		projectile.launch(spawn_pos, target_pos)
		
		await get_tree().create_timer(0.1).timeout
