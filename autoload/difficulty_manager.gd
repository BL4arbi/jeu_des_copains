# DifficultyManager.gd - Version corrigée sans tween_delay
extends Node

# Progression basée sur les kills
var base_enemy_health: Dictionary = {
	"Grunt": 25.0,
	"Shooter": 20.0,
	"Elite": 60.0
}

var base_enemy_damage: Dictionary = {
	"Grunt": 8.0,
	"Shooter": 6.0,
	"Elite": 10.0
}

# Système d'armure
var armor_per_kill: float = 0.02
var health_per_kill: float = 0.05
var damage_per_kill: float = 0.03

# Paliers de difficulté
var difficulty_thresholds: Array = [25, 50, 100, 200, 400, 800]
var current_difficulty_level: int = 0

func get_enemy_stats(enemy_type: String) -> Dictionary:
	var kills = GlobalData.total_kills
	
	# Calculer les multiplicateurs
	var health_multiplier = 1.0 + (kills * health_per_kill)
	var damage_multiplier = 1.0 + (kills * damage_per_kill)
	var armor_value = min(kills * armor_per_kill, 0.8)
	
	# Bonus selon les paliers
	var difficulty_bonus = get_difficulty_bonus()
	health_multiplier *= difficulty_bonus.health
	damage_multiplier *= difficulty_bonus.damage
	armor_value += difficulty_bonus.armor
	
	# Stats finales
	var final_health = base_enemy_health[enemy_type] * health_multiplier
	var final_damage = base_enemy_damage[enemy_type] * damage_multiplier
	
	# Bonus selon le type d'ennemi
	match enemy_type:
		"Elite":
			final_health *= 1.3
			final_damage *= 1.2
			armor_value += 0.1
		"Shooter":
			armor_value += 0.05
	
	return {
		"health": final_health,
		"damage": final_damage,
		"armor": min(armor_value, 0.85),
		"kills_scaled": kills
	}

func get_difficulty_bonus() -> Dictionary:
	update_difficulty_level()
	
	match current_difficulty_level:
		0: return {"health": 1.0, "damage": 1.0, "armor": 0.0}
		1: return {"health": 1.2, "damage": 1.1, "armor": 0.05}
		2: return {"health": 1.5, "damage": 1.3, "armor": 0.1}
		3: return {"health": 2.0, "damage": 1.5, "armor": 0.15}
		4: return {"health": 2.5, "damage": 1.8, "armor": 0.2}
		5: return {"health": 3.0, "damage": 2.2, "armor": 0.25}
		_: return {"health": 4.0, "damage": 3.0, "armor": 0.3}

func update_difficulty_level():
	var kills = GlobalData.total_kills
	var old_level = current_difficulty_level
	
	current_difficulty_level = 0
	for i in range(difficulty_thresholds.size()):
		if kills >= difficulty_thresholds[i]:
			current_difficulty_level = i + 1
	
	if current_difficulty_level > old_level:
		show_difficulty_notification()

func show_difficulty_notification():
	print("🔥 DIFFICULTY INCREASED! Level ", current_difficulty_level)
	
	var notification = Label.new()
	notification.text = "🔥 DIFFICULTÉ AUGMENTÉE! 🔥\nNiveau " + str(current_difficulty_level)
	notification.position = Vector2(400, 200)
	notification.add_theme_font_size_override("font_size", 32)
	notification.add_theme_color_override("font_color", Color.RED)
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(notification)
		
		# Animation CORRIGÉE sans tween_delay
		var tween = create_tween()
		tween.tween_property(notification, "scale", Vector2(1.5, 1.5), 0.5)
		tween.tween_property(notification, "scale", Vector2(1.0, 1.0), 0.5)
		
		# Timer séparé pour la disparition
		var timer = Timer.new()
		notification.add_child(timer)
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(func():
			var fade_tween = create_tween()
			fade_tween.tween_property(notification, "modulate:a", 0.0, 1.0)
			fade_tween.tween_callback(func(): notification.queue_free())
		)
		timer.start()

func get_difficulty_description() -> String:
	match current_difficulty_level:
		0: return "Facile"
		1: return "Normal" 
		2: return "Difficile"
		3: return "Expert"
		4: return "Maître"
		5: return "Légende"
		_: return "CAUCHEMAR"
