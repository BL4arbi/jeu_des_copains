# WeaponCleanupManager.gd - À ajouter comme autoload
extends Node

# Timer pour nettoyer les sprites orphelins
var cleanup_timer: Timer
var cleanup_interval: float = 5.0  # Nettoyer toutes les 5 secondes

func _ready():
	# Créer le timer de nettoyage
	cleanup_timer = Timer.new()
	add_child(cleanup_timer)
	cleanup_timer.wait_time = cleanup_interval
	cleanup_timer.timeout.connect(_cleanup_orphaned_sprites)
	cleanup_timer.start()
	
	print("Weapon Cleanup Manager started")

func _cleanup_orphaned_sprites():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	var sprites_cleaned = 0
	
	# Nettoyer les sprites orphelins
	_cleanup_node_children(current_scene, sprites_cleaned)
	
	if sprites_cleaned > 0:
		print("🧹 Cleaned ", sprites_cleaned, " orphaned sprites")

func _cleanup_node_children(node: Node, sprites_cleaned: int):
	for child in node.get_children():
		# Nettoyer les sprites orphelins (sans parent valide ou scène)
		if child is Sprite2D:
			if _should_cleanup_sprite(child):
				child.queue_free()
				sprites_cleaned += 1
		
		# Nettoyer les projectiles "morts"
		if child.has_method("_on_lifetime_end") and child.has_property("lifetime_timer"):
			if child.lifetime_timer >= child.lifetime * 2:  # Double du temps de vie
				child.queue_free()
				sprites_cleaned += 1
		
		# Récursion pour les enfants
		_cleanup_node_children(child, sprites_cleaned)

func _should_cleanup_sprite(sprite: Sprite2D) -> bool:
	# Vérifier si le sprite a un parent valide
	var parent = sprite.get_parent()
	if not parent or not is_instance_valid(parent):
		return true
	
	# Vérifier si c'est un effet temporaire sans timer
	if sprite.name.begins_with("effect_") or sprite.name.begins_with("glow_"):
		if not sprite.get_children().any(func(child): return child is Timer):
			return true
	
	# Vérifier si le sprite est très ancien (position fixe depuis longtemps)
	if sprite.has_meta("creation_time"):
		var creation_time = sprite.get_meta("creation_time")
		if Time.get_ticks_msec() - creation_time > 30000:  # 30 secondes
			return true
	
	return false

# Méthode pour marquer un sprite temporaire
func mark_temporary_sprite(sprite: Sprite2D, lifetime: float = 10.0):
	sprite.set_meta("creation_time", Time.get_ticks_msec())
	sprite.set_meta("cleanup_time", lifetime)
	
	# Créer un timer pour ce sprite spécifique
	var timer = Timer.new()
	sprite.add_child(timer)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(sprite):
			sprite.queue_free()
	)
	timer.start()

# Méthode pour forcer le nettoyage
func force_cleanup():
	print("🧹 Force cleanup initiated")
	_cleanup_orphaned_sprites()
