extends Node2D
class_name EffectReceiver
 
signal effect_started(effect_type: Util.EffectType)
signal effect_ended(effect_type: Util.EffectType)
signal health_changed(current_hp: int, max_hp: int)
signal damaged(amount: float)
signal died()
 
@export var max_hp: int = 100
var current_hp: int = 100
 
var velocity_knockback: Vector2 = Vector2.ZERO
var knockback_friction: float = 800.0
 
var active_dots: Array[Dictionary] = []
var active_stat_modifiers: Dictionary = {}
 
var speed_multiplier := 1.0
var attack_multiplier := 1.0
var defense_multiplier := 1.0
 
var active_states: Dictionary = {}     # { EffectType: true }
var state_timers: Dictionary = {}      # { EffectType: float }
 
func _process(delta: float) -> void:
	_process_dots(delta)
	_process_stat_modifiers(delta)
	_process_state_timers(delta)
	_process_knockback(delta)
 
func apply_effect(effect: Effect, source: Node = null):
	print(effect.name)
	emit_signal("effect_started", effect.effect_type)
 
	match effect.behavior:
		Util.EffectBehavior.INSTANT:
			_apply_instant_effect(effect, source)
		Util.EffectBehavior.DOT:
			_add_dot_effect(effect)
		Util.EffectBehavior.BUFF, Util.EffectBehavior.DEBUFF:
			_add_stat_modifier(effect)
 
func _apply_instant_effect(effect: Effect, source: Node = null):
	if effect.damage:
		take_damage(effect.damage)
 
	if effect.effect_type == Util.EffectType.KNOCKBACK:
		if source:
			apply_knockback_from(source.global_position, effect.knockback_strength)
 
	if effect.effect_type in [Util.EffectType.STUN, Util.EffectType.ROOT, Util.EffectType.FEAR]:
		_apply_state(effect.effect_type, effect.duration)
 
	if effect.stat_modifiers:
		_add_stat_modifier(effect)
 
func _apply_state(effect_type: Util.EffectType, duration: float):
	active_states[effect_type] = true
	state_timers[effect_type] = duration
 
func _process_state_timers(delta: float):
	for effect_type in state_timers.keys():
		state_timers[effect_type] -= delta
		if state_timers[effect_type] <= 0:
			active_states[effect_type] = false
			state_timers.erase(effect_type)
			emit_signal("effect_ended", effect_type)
 
func is_under(effect_type: Util.EffectType) -> bool:
	return active_states.get(effect_type, false)
 
func take_damage(damage: DamageData):
	var final_damage = damage.amount
	current_hp = clamp(current_hp - final_damage, 0, max_hp)
	emit_signal("damaged", final_damage)
	emit_signal("health_changed", current_hp, max_hp)
 
	if current_hp <= 0:
		died.emit()
 
func _add_dot_effect(effect: Effect):
	active_dots.append({"effect": effect, "timer": 0.0, "elapsed": 0.0})
 
func _process_dots(delta: float):
	for i in active_dots.size():
		var dot = active_dots[i]
		var e: Effect = dot.effect
		dot["elapsed"] += delta
		dot["timer"] += delta
 
		if dot["timer"] >= e.tick_interval:
			dot["timer"] = 0.0
			if e.damage:
				take_damage(e.damage)
 
		if dot["elapsed"] >= e.duration:
			emit_signal("effect_ended", e.effect_type)
			active_dots.remove_at(i)
			return
 
func _add_stat_modifier(effect: Effect):
	if effect.stat_modifiers == null:
		return
 
	active_stat_modifiers[effect.effect_type] = {
		"modifier": effect.stat_modifiers,
		"remaining_time": effect.duration
	}
 
	_apply_stat(effect.stat_modifiers)
 
func _apply_stat(data: StatModifierData):
	speed_multiplier *= data.speed_multiplier
	attack_multiplier *= data.attack_multiplier
	defense_multiplier *= data.defense_multiplier
 
func _remove_stat(data: StatModifierData):
	speed_multiplier /= data.speed_multiplier
	attack_multiplier /= data.attack_multiplier
	defense_multiplier /= data.defense_multiplier
 
func _process_stat_modifiers(delta: float):
	for effect_type in active_stat_modifiers.keys():
		active_stat_modifiers[effect_type].remaining_time -= delta
		if active_stat_modifiers[effect_type].remaining_time <= 0:
			var mod = active_stat_modifiers[effect_type].modifier
			_remove_stat(mod)
			emit_signal("effect_ended", effect_type)
			active_stat_modifiers.erase(effect_type)
			break
 
func apply_knockback_from(origin: Vector2, strength: float):
	var direction = (global_position - origin).normalized()
	velocity_knockback = direction * strength
 
func _process_knockback(delta: float):
	if velocity_knockback.length_squared() > 0.1:
		velocity_knockback = velocity_knockback.move_toward(Vector2.ZERO, knockback_friction * delta)
