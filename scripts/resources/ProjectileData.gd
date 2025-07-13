# ProjectileData.gd - Correction pour special_properties
extends Resource
class_name ProjectileData

@export var projectile_id: int = 0
@export var projectile_name: String = ""
@export var damage: float = 10.0
@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var fire_rate: float = 0.3
@export var projectile_scene_path: String = ""
@export var description: String = ""

# CORRECTION : Ajouter special_properties comme variable normale (pas @export)
var special_properties: Dictionary = {}
