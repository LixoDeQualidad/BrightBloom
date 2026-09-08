# ItemColetavel.gd
extends Area2D

@onready var sound = $AudioStreamPlayer2D
@export var nome_item: String = "faca"
@export var remover_ao_coletar: bool = true


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		GameManager.adicionar_item(nome_item)

		if remover_ao_coletar:
			$AnimatedSprite2D.hide()
			$CollisionShape2D.set_deferred("disabled", true)
			await get_tree().create_timer(0.1).timeout
			sound.play()
			await sound.finished
			queue_free()
