extends Resource
class_name Effect 

@export var name : String = "New Effect"
@export var effect_type : Util.EffectType = Util.EffectType.NONE
@export var behavior : Util.EffectBehavior = Util.EffectBehavior.NONE

@export var damage : DamageData
@export var stat_modifiers : StatModifierData
@export var duration : float = 0.0
@export var tick_interval : float = 1.0 
@export var knockback_strength : float = 0.0
