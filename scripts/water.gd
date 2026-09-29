extends Area2D

@export var damage_to_player: int = 100


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("Player"):
		body.take_damage(damage_to_player)
