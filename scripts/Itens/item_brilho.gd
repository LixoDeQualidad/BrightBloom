extends Area2D

@export var personagem: Node2D  # Arraste o personagem aqui no editor

func _on_body_entered(body):
	if body.is_in_group("Player"):
		queue_free() 
		GameManager.luz_coletada = true # Ou use um grupo "player"
		# Ativa a luz no personagem
		body.get_node("PointLight2D").enabled = true
		
		
		# Opcional: Toca um som, efeito visual
		# queue_free()  # Remove o item
