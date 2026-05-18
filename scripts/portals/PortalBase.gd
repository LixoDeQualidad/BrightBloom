extends Area2D
class_name PortalBase

@export var target_scene: PackedScene

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		change_scene()
		queue_free()
func change_scene():
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)
