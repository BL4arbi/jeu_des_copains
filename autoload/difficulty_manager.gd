# DifficultyManager.gd - Nouveau script à créer comme autoload
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
var armor_per_kill: float = 0.02  # +2% de réduction de dégâts par kill
var health_per_kill: float = 0.05  # +5% de vie par kill
var damage_per_kill: float = 0.03  # +3% de dégâts par kill

# Paliers de difficulté
var difficulty_thresholds: Array = [25, 50, 100, 200, 400, 800]
var current_difficulty_level: int = 0

func get_enemy_stats(enemy_type: String) -> Dictionary:
	var kills = GlobalData.total_kills
	
	# Calculer les multiplicateurs
	var health_multiplier = 1.0 + (kills * health_per_kill)
	var damage_multiplier = 1.0 + (kills * damage_per_kill)
	var armor_value = min(kills * armor_per_kill, 0.8)  # Max 80% de réduction
	
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
			# Elite encore plus forts
			final_health *= 1.3
			final_damage *= 1.2
			armor_value += 0.1
		"Shooter":
			# Shooters plus résistants à distance
			armor_value += 0.05
	
	return {
		"health": final_health,
		"damage": final_damage,
		"armor": min(armor_value, 0.85),  # Max 85% de réduction
		"kills_scaled": kills
	}

func get_difficulty_bonus() -> Dictionary:
	# Vérifier si on a atteint un nouveau palier
	update_difficulty_level()
	
	# Bonus selon le niveau de difficulté
	match current_difficulty_level:
		0:  # 0-24 kills
			return {"health": 1.0, "damage": 1.0, "armor": 0.0}
		1:  # 25-49 kills
			return {"health": 1.2, "damage": 1.1, "armor": 0.05}
		2:  # 50-99 kills
			return {"health": 1.5, "damage": 1.3, "armor": 0.1}
		3:  # 100-199 kills
			return {"health": 2.0, "damage": 1.5, "armor": 0.15}
		4:  # 200-399 kills
			return {"health": 2.5, "damage": 1.8, "armor": 0.2}
		5:  # 400-799 kills
			return {"health": 3.0, "damage": 2.2, "armor": 0.25}
		_:  # 800+ kills - Mode Nightmare
			return {"health": 4.0, "damage": 3.0, "armor": 0.3}

func update_difficulty_level():
	var kills = GlobalData.total_kills
	var old_level = current_difficulty_level
	
	current_difficulty_level = 0
	for i in range(difficulty_thresholds.size()):
		if kills >= difficulty_thresholds[i]:
			current_difficulty_level = i + 1
	
	# Afficher notification si nouveau palier
	if current_difficulty_level > old_level:
		show_difficulty_notification()

func show_difficulty_notification():
	print("🔥 DIFFICULTY INCREASED! Level ", current_difficulty_level)
	
	# Créer notification à l'écran
	var notification = Label.new()
	notification.text = "🔥 DIFFICULTÉ AUGMENTÉE! 🔥\nNiveau " + str(current_difficulty_level)
	notification.position = Vector2(400, 200)
	notification.add_theme_font_size_override("font_size", 32)
	notification.add_theme_color_override("font_color", Color.RED)
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(notification)
		
		# Animation de notification
		var tween = create_tween()
		tween.tween_property(notification, "scale", Vector2(1.5, 1.5), 0.5)
		tween.tween_delay(2.0)
		tween.tween_property(notification, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): notification.queue_free())

func get_difficulty_description() -> String:
	match current_difficulty_level:
		0: return "Facile"
		1: return "Normal" 
		2: return "Difficile"
		3: return "Expert"
		4: return "Maître"
		5: return "Légende"
		_: return "CAUCHEMAR"

func get_armor_description(armor_value: float) -> String:
	if armor_value <= 0.1:
		return "Aucune armure"
	elif armor_value <= 0.3:
		return "Armure légère"
	elif armor_value <= 0.5:
		return "Armure moyenne"
	elif armor_value <= 0.7:
		return "Armure lourde"
	else:
		return "Armure ultime"
