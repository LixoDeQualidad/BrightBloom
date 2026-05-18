extends Area2D

func _on_body_entered(body):
	if body.name == "Player": # Ou use groups
		body.coletar_faca()
		queue_free() # Remove o item do jogo
