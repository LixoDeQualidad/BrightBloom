extends Area2D  # ou StaticBody2D + Area2D, dependendo da sua config

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# ou @onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _on_top_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if body.has_method("bounce2"):
			body.bounce2()
		_play_bounce_animation()

func _play_bounce_animation() -> void:
	if AnimatedSprite2D:
		sprite.play("bounce")
	# ou, se for AnimatedSprite2D:
	# sprite.play("bounce")
