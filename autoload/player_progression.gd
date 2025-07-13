# PlayerProgressionSystem.gd - Version équilibrée avec progression réduite
extends Node

# STATS RÉDUITES - Progression plus lente
var stats_per_kill: Dictionary = {
	"damage": 0.2,      # RÉDUIT de 0.5 à 0.2
	"health": 1.0,      # RÉDUIT de 2.0 à 1.0
	"speed": 0.5,       # RÉDUIT de 1.0 à 0.5
	"fire_rate": 0.001  # RÉDUIT de 0.002 à 0.001
}

# PALIERS PLUS ESPACÉS ET BONUS RÉDUITS
var special_thresholds: Dictionary = {
	20: {"damage": 3, "description": "Premier Sang"},          # 10 -> 20
	50: {"health": 15, "description": "Survivant"},            # 25 -> 50, bonus réduit
	100: {"speed": 15, "description": "Véloce"},               # 50 -> 100
	200: {"damage": 5, "health": 25, "description": "Tueur Expérimenté"},  # 100 -> 200
	400: {"damage": 8, "speed": 20, "description": "Machine de Guerre"},   # 200 -> 400
	800: {"damage": 12, "health": 50, "speed": 30, "description": "Légende Vivante"}  # 500 -> 800
}

var player_ref: Player = null
var last_kill_count: int = 0

func _ready():
	add_to_group("progression_system")
	
	# Trouver le joueur
	player_ref = get_tree().get_first_node_in_group("players")
	
	# Connecter au signal de kills
	if GlobalData.has_signal("kill_count_updated"):
		GlobalData.kill_count_updated.connect(_on_kill_count_updated)
	
	print("📈 Player progression system initialized (BALANCED)")

func _on_kill_count_updated(new_count: int):
	if new_count > last_kill_count:
		var kills_gained = new_count - last_kill_count
		
		for i in range(kills_gained):
			apply_kill_progression(last_kill_count + i + 1)
		
		last_kill_count = new_count

func apply_kill_progression(current_kills: int):
	if not player_ref:
		return
	
	# Augmentation des stats de base (RÉDUITES)
	player_ref.base_damage += stats_per_kill.damage
	player_ref.damage += stats_per_kill.damage
	
	player_ref.max_health += stats_per_kill.health
	player_ref.current_health += stats_per_kill.health  # Bonus heal
	
	player_ref.base_speed += stats_per_kill.speed
	player_ref.speed += stats_per_kill.speed
	
	# SEULEMENT TOUS LES 5 KILLS pour réduire le spam
	if current_kills % 5 == 0:
		print("📈 Kill ", current_kills, ": +", stats_per_kill.damage, " DMG, +", stats_per_kill.health, " HP, +", stats_per_kill.speed, " SPD")
	
	# Vérifier les paliers spéciaux
	if special_thresholds.has(current_kills):
		apply_special_threshold(current_kills, special_thresholds[current_kills])
	
	# Effet visuel moins fréquent
	if current_kills % 10 == 0:  # Seulement tous les 10 kills
		create_progression_effect()

func apply_special_threshold(kills: int, bonus: Dictionary):
	if not player_ref:
		return
	
	print("🌟 PALIER SPÉCIAL ATTEINT: ", kills, " kills - ", bonus.description)
	
	# Appliquer les bonus spéciaux
	if bonus.has("damage"):
		player_ref.base_damage += bonus.damage
		player_ref.damage += bonus.damage
	
	if bonus.has("health"):
		player_ref.max_health += bonus.health
		player_ref.current_health += bonus.health
	
	if bonus.has("speed"):
		player_ref.base_speed += bonus.speed
		player_ref.speed += bonus.speed
	
	# Notification spéciale
	show_special_threshold_notification(bonus.description, bonus)

func show_special_threshold_notification(title: String, bonus: Dictionary):
	var notification = Label.new()
	notification.text = "🌟 " + title + " 🌟"
	
	# Ajouter les détails du bonus
	var bonus_text = "\n"
	if bonus.has("damage"):
		bonus_text += "+" + str(bonus.damage) + " DÉGÂTS "
	if bonus.has("health"):
		bonus_text += "+" + str(bonus.health) + " VIE "
	if bonus.has("speed"):
		bonus_text += "+" + str(bonus.speed) + " VITESSE "
	
	notification.text += bonus_text
	notification.position = Vector2(350, 250)
	notification.add_theme_font_size_override("font_size", 24)
	notification.add_theme_color_override("font_color", Color.GOLD)
	
	get_tree().current_scene.add_child(notification)
	
	# Animation spéciale
	var tween = create_tween()
	tween.tween_property(notification, "scale", Vector2(1.3, 1.3), 0.8)
	tween.tween_property(notification, "scale", Vector2(1.0, 1.0), 0.8)
	
	# Timer pour disparition
	var timer = Timer.new()
	notification.add_child(timer)
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(func():
		var fade_tween = create_tween()
		fade_tween.tween_property(notification, "modulate:a", 0.0, 1.5)
		fade_tween.tween_callback(func(): notification.queue_free())
	)
	timer.start()

func create_progression_effect():
	if not player_ref:
		return
	
	# Effet visuel de montée en niveau
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	# Créer un effet doré
	var effect_size = 64
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(effect_size / 2, effect_size / 2)
	
	for x in range(effect_size):
		for y in range(effect_size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effect_size / 2:
				var alpha = 1.0 - (distance / (effect_size / 2))
				image.set_pixel(x, y, Color(1.0, 0.8, 0.0, alpha * 0.7))  # Doré
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = player_ref.global_position - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation de l'effet
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.6)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): effect.queue_free())

# Méthodes utilitaires
func get_total_stats_gained() -> Dictionary:
	var kills = GlobalData.total_kills
	var total_stats = {
		"damage": kills * stats_per_kill.damage,
		"health": kills * stats_per_kill.health,
		"speed": kills * stats_per_kill.speed
	}
	
	# Ajouter les bonus des paliers
	for threshold in special_thresholds.keys():
		if kills >= threshold:
			var bonus = special_thresholds[threshold]
			if bonus.has("damage"):
				total_stats.damage += bonus.damage
			if bonus.has("health"):
				total_stats.health += bonus.health
			if bonus.has("speed"):
				total_stats.speed += bonus.speed
	
	return total_stats

func get_next_threshold() -> Dictionary:
	var kills = GlobalData.total_kills
	
	for threshold in special_thresholds.keys():
		if kills < threshold:
			return {
				"kills_needed": threshold,
				"kills_remaining": threshold - kills,
				"bonus": special_thresholds[threshold]
			}
	
	return {"kills_needed": -1}  # Pas de prochain palier
