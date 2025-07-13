# ForkArrowProjectile.gd - Version corrigée sans erreurs
extends BaseProjectile
class_name ForkArrowProjectile

var fork_count: int = 3
var fork_range: float = 200.0
var fork_damage_ratio: float = 0.6
var fork_speed_ratio: float = 0.8
var spread_angle: float = PI / 3
var damage_multiplier: float = 1.0
var range_multiplier: float = 1.0

var has_forked: bool = false
# targets_hit est déjà défini dans BaseProjectile, on l'utilise directement

func _ready():
	super._ready()
	setup_fork_arrow()

func setup_fork_arrow():
	projectile_type = "fork"
	if sprite:
		sprite.modulate = Color.PURPLE
		if direction != Vector2.ZERO:
			sprite.rotation = direction.angle()

func _physics_process(delta):
	# Mouvement de base
	global_position += direction * speed * delta
	
	# Rotation du sprite
	if sprite and direction != Vector2.ZERO:
		sprite.rotation = direction.angle()
	
	# Timer de vie
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		on_lifetime_end()

func _on_hit_target(body):
	print("🏹 Fork Arrow hit: ", body.name)
	
	if not should_damage_target(body):
		return
	
	# Éviter de toucher la même cible plusieurs fois
	if body in targets_hit:
		return
	
	targets_hit.append(body)
	
	# FORK AVANT LES DÉGÂTS pour garantir qu'elle se déclenche
	if not has_forked:
		create_fork_projectiles(body.global_position)
		has_forked = true
		print("🏹 Fork triggered!")
	
	# Infliger les dégâts
	if body.has_method("take_damage"):
		var initial_damage = damage * damage_multiplier
		body.take_damage(initial_damage)
		print("✅ Fork Arrow damage: ", initial_damage)
	
	# Appliquer effet de statut si disponible
	if has_status_effect and body.has_method("apply_status_effect"):
		body.apply_status_effect(status_type, status_duration, status_power)
	
	# Détruire le projectile principal après fork et dégâts
	queue_free()

func create_fork_projectiles(impact_position: Vector2):
	print("🏹 Creating ", fork_count, " fork arrows!")
	
	var nearby_targets = find_nearby_targets(impact_position)
	
	for i in range(fork_count):
		call_deferred("spawn_fork_projectile", i, impact_position, nearby_targets)

func spawn_fork_projectile(fork_index: int, impact_position: Vector2, nearby_targets: Array):
	# Vérifier que la scène existe toujours
	if not get_tree() or not get_tree().current_scene:
		return
	
	# Utiliser BasicProjectile pour éviter les problèmes
	var basic_projectile_path = "res://scenes/projectiles/BasicProjectile.tscn"
	if not ResourceLoader.exists(basic_projectile_path):
		print("❌ BasicProjectile scene not found!")
		return
	
	var fork_scene = load(basic_projectile_path)
	var fork = fork_scene.instantiate()
	
	if not fork:
		print("❌ Failed to instantiate fork projectile!")
		return
	
	get_tree().current_scene.add_child(fork)
	
	# Position et direction
	fork.global_position = impact_position
	var fork_direction = calculate_fork_direction(fork_index, nearby_targets, impact_position)
	fork.direction = fork_direction
	
	# Configuration de la fork
	var fork_damage = damage * fork_damage_ratio * damage_multiplier
	var fork_speed = speed * fork_speed_ratio
	var fork_lifetime = lifetime * 0.6  # Plus courte
	
	fork.setup(fork_damage, fork_speed, fork_lifetime)
	fork.set_owner_type(owner_type)
	
	# ⚠️ TRÈS IMPORTANT : Empêcher le re-fork !
	fork.projectile_type = "basic"  # PAS "fork" !
	
	# ⚠️ DOUBLEMENT IMPORTANT : Supprimer la méthode _on_hit_target si elle existe
	if fork.has_signal("body_entered"):
		# Déconnecter tous les signaux existants
		for connection in fork.body_entered.get_connections():
			fork.body_entered.disconnect(connection.callable)
		
		# Reconnecter seulement au hit normal de BaseProjectile
		fork.body_entered.connect(fork._on_hit_target)
	
	# Apparence distincte pour les forks
	if fork.sprite:
		fork.sprite.modulate = Color.LIGHT_BLUE
		fork.sprite.scale = Vector2(0.7, 0.7)
		if fork_direction != Vector2.ZERO:
			fork.sprite.rotation = fork_direction.angle()
	
	# Effet de statut hérité
	if has_status_effect and fork.has_method("add_status_effect"):
		fork.add_status_effect(status_type, status_duration * 0.7, status_power * 0.8)
	
	print("🏹 Fork ", fork_index+1, " spawned successfully (type: ", fork.projectile_type, ")")

func find_nearby_targets(impact_position: Vector2) -> Array:
	var target_group = "enemies" if owner_type == "player" else "players"
	var potential_targets = get_tree().get_nodes_in_group(target_group)
	var nearby_targets = []
	
	var effective_range = fork_range * range_multiplier
	
	for target in potential_targets:
		if not is_instance_valid(target):
			continue
			
		var distance = impact_position.distance_to(target.global_position)
		if distance <= effective_range and distance > 20:  # Pas trop proche
			nearby_targets.append({
				"target": target,
				"distance": distance,
				"position": target.global_position
			})
	
	# Trier par distance (plus proches en premier)
	nearby_targets.sort_custom(func(a, b): return a.distance < b.distance)
	
	print("🏹 Found ", nearby_targets.size(), " nearby targets for fork")
	return nearby_targets

func calculate_fork_direction(fork_index: int, nearby_targets: Array, impact_position: Vector2) -> Vector2:
	# Si on a des cibles proches, viser les premières
	if fork_index < nearby_targets.size():
		var target_pos = nearby_targets[fork_index].position
		return (target_pos - impact_position).normalized()
	else:
		# Sinon, spread en éventail
		var base_angle = direction.angle()
		var angle_step = spread_angle / max(1, fork_count - 1)
		var fork_angle = base_angle - (spread_angle / 2) + (fork_index * angle_step)
		
		# Petite variation aléatoire
		fork_angle += randf_range(-PI/12, PI/12)  # ±15 degrés
		
		return Vector2(cos(fork_angle), sin(fork_angle))

func should_damage_target(body) -> bool:
	match owner_type:
		"player":
			return body.is_in_group("enemies")
		"enemy":
			return body.is_in_group("players")
		_:
			return true

func on_lifetime_end():
	# Si pas encore forké à la fin de vie, fork quand même
	if not has_forked:
		print("🏹 Fork triggered on lifetime end")
		create_fork_projectiles(global_position)
		has_forked = true
	
	queue_free()

# Override pour empêcher la gestion normale des hits de BaseProjectile
func _on_hit_area(area):
	# Ne pas traiter les hits d'area pour éviter les conflits
	pass
