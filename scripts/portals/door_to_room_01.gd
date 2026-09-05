# rooms/Door.gd (anexe em cada Area2D de porta)
extends Area2D

@export var target_scene_path: String
@export var target_spawn_point: String = "SpawnPoint_Default"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameState.change_room(target_scene_path, target_spawn_point)
