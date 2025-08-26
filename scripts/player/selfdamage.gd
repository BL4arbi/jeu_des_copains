extends Area2D

var amount : float = 1.0
@export var effects : Array[Effect]



func _on_body_entered(body: Node2D) -> void:
	if body.has_method("receive_hit"):
		body.receive_hit(effects,owner)
