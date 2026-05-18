extends Area2D

@onready var animated_sprite = $AnimatedSprite2D  # Referência ao AnimatedSprite2D

func _ready():
	# Toca a animação idle quando o item aparece
	if animated_sprite:
		animated_sprite.play("Orb")

func _on_body_entered(body):
	if body.has_method("collect_double_jump_item"):
		# Desativa a colisão para não coletar múltiplas vezes
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Dá o power-up ao player
		body.collect_double_jump_item()
		
		# Toca animação de coleta
		if animated_sprite:
			animated_sprite.play("Orb coletado")
			# Aguarda a animação terminar antes de remover
			await animated_sprite.animation_finished
		
		# Remove o item
		queue_free()
