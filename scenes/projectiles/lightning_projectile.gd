# LightningProjectile.gd - Version modulaire avec variables configurables
extends BaseProjectile
class_name LightningProjectile

# === VARIABLES CONFIGURABLES (pour futurs accessoires) ===
var max_targets: int = 3              # Nombre max d'ennemis touchés
var strike_radius: float = 80.0       # Rayon de frappe de chaque éclair
var chain_range: float = 120.0        # Distance de chaînage entre cibles
var warning_time: float = 1.0         # Temps d'avertissement
var paralysis_duration: float = 1.5   # Durée de paralysie
var damage_multiplier: float = 1.0    # Multiplicateur de dégâts
var range_multiplier: float = 1.0     # Multiplicateur de portée
var target_multiplier: float = 1.0    # Multiplicateur de nombre de cibles

# Variables internes
var warning_shown: bool = false
var warning_indicators: Array = []
var target_positions: Array = []

func _ready():
	super._ready()
	setup_lightning_behavior()

func setup_lightning_behavior():
	speed = 0  # La foudre ne bouge pas
	lifetime = 4.0
	
	# Trouver les cibles autour du joueur
	find_lightning_targets()
	
	# Créer les avertissements
	create_warning_indicators()
	
	# Délai avant de frapper
	var warning_timer = Timer.new()
	add_child(warning_timer)
	warning_timer.wait_time = warning_time
	warning_timer.one_shot = true
	warning_timer.timeout.connect(_on_lightning_strike)
	warning_timer.start()
	
	print("⚡ Lightning preparing to strike ", target_positions.size(), " targets")

func find_lightning_targets():
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	
	# Calculer le nombre effectif de cibles (avec multiplicateur)
	var effective_max_targets = int(max_targets * target_multiplier)
	
	# Trier par distance au joueur/lanceur
	var launcher = get_tree().get_first_node_in_group("players") if owner_type == "player" else null
	if not launcher:
		launcher = get_tree().get_first_node_in_group("enemies")
	
	if not launcher:
		return
	
	# Filtrer et trier les cibles
	var valid_targets = []
	var effective_range = chain_range * range_multiplier
	
	for target in potential_targets:
		var distance = launcher.global_position.distance_to(target.global_position)
		if distance <= effective_range:
			valid_targets.append({"target": target, "distance": distance})
	
	# Trier par distance (plus proches en premier)
	valid_targets.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Prendre les N plus proches
	for i in range(min(effective_max_targets, valid_targets.size())):
		target_positions.append(valid_targets[i].target.global_position)
	
	print("Found ", target_positions.size(), " lightning targets")

func create_warning_indicators():
	clear_warnings()
	
	for target_pos in target_positions:
		var warning = create_warning_circle(target_pos)
		warning_indicators.append(warning)
		get_tree().current_scene.add_child(warning)

func create_warning_circle(position: Vector2) -> Sprite2D:
	var warning = Sprite2D.new()
	
	# Calculer le rayon effectif avec multiplicateur
	var effective_radius = strike_radius * range_multiplier
	var size = int(effective_radius * 2)
	
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= effective_radius:
				var alpha = 0.7
				# Bordure plus visible
				if distance > effective_radius - 6:
					alpha = 1.0
				# Couleur selon le propriétaire
				var color = Color.YELLOW if owner_type == "player" else Color.PURPLE
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	warning.texture = texture
	warning.global_position = position - Vector2(effective_radius, effective_radius)
	
	# Animation clignotante plus rapide si temps court
	var blink_speed = 0.3 / warning_time  # S'adapte au temps d'avertissement
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(warning, "modulate:a", 0.3, blink_speed)
	tween.tween_property(warning, "modulate:a", 1.0, blink_speed)
	
	return warning

func _on_lightning_strike():
	warning_shown = true
	print("⚡ Lightning strikes ", target_positions.size(), " targets!")
	
	# Supprimer les avertissements
	clear_warnings()
	
	# Frapper chaque position cible
	for target_pos in target_positions:
		strike_at_position(target_pos)
		
		# Délai entre les éclairs pour l'effet
		await get_tree().create_timer(0.1).timeout
	
	queue_free()

func strike_at_position(strike_pos: Vector2):
	var effective_radius = strike_radius * range_multiplier
	var effective_damage = damage * damage_multiplier
	
	# Trouver toutes les cibles dans le rayon de frappe
	var target_group = "enemies" if owner_type == "player" else "players"
	var all_targets = get_tree().get_nodes_in_group(target_group)
	
	for target in all_targets:
		var distance = strike_pos.distance_to(target.global_position)
		if distance <= effective_radius:
			if target.has_method("take_damage"):
				# Dégâts selon la distance (plus fort au centre)
				var distance_ratio = 1.0 - (distance / effective_radius)
				var final_damage = effective_damage * distance_ratio
				target.take_damage(final_damage)
				
				# Effet de paralysie
				if target.has_method("apply_status_effect"):
					target.apply_status_effect("freeze", paralysis_duration, 1.0)
				
				print("⚡ Lightning hit ", target.name, " for ", final_damage, " damage")
	
	# Effet visuel d'éclair
	create_lightning_effect(strike_pos)

func create_lightning_effect(position: Vector2):
	var effect = Sprite2D.new()
	get_tree().current_scene.add_child(effect)
	
	# Taille de l'effet selon le rayon
	var effect_size = int(strike_radius * range_multiplier * 1.5)
	var image = Image.create(effect_size, effect_size, false, Image.FORMAT_RGBA8)
	
	# Couleur selon le propriétaire
	var effect_color = Color.YELLOW if owner_type == "player" else Color.PURPLE
	image.fill(effect_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	effect.texture = texture
	effect.global_position = position - Vector2(effect_size / 2, effect_size / 2)
	
	# Animation d'explosion
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.4)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): effect.queue_free())

func clear_warnings():
	for warning in warning_indicators:
		if is_instance_valid(warning):
			warning.queue_free()
	warning_indicators.clear()

# === MÉTHODES POUR FUTURS ACCESSOIRES ===
func apply_accessory_modifiers(modifiers: Dictionary):
	# Exemple d'utilisation future :
	# lightning.apply_accessory_modifiers({
	#   "max_targets_bonus": 2,
	#   "damage_multiplier": 1.5,
	#   "range_multiplier": 1.3
	# })
	
	if modifiers.has("max_targets_bonus"):
		max_targets += modifiers.max_targets_bonus
	
	if modifiers.has("damage_multiplier"):
		damage_multiplier *= modifiers.damage_multiplier
	
	if modifiers.has("range_multiplier"):
		range_multiplier *= modifiers.range_multiplier
	
	if modifiers.has("target_multiplier"):
		target_multiplier *= modifiers.target_multiplier
	
	if modifiers.has("warning_time_reduction"):
		warning_time = max(0.3, warning_time - modifiers.warning_time_reduction)
	
	if modifiers.has("paralysis_duration_bonus"):
		paralysis_duration += modifiers.paralysis_duration_bonus
	
	print("Lightning modifiers applied: ", modifiers)

# Override pour empêcher collision normale
func _on_hit_target(_body):
	# La foudre ne touche que lors de la frappe programmée
	pass

func _physics_process(delta):
	# Pas de mouvement pour la foudre
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		clear_warnings()
		queue_free()
