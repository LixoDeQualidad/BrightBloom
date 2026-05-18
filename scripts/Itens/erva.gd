extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Começa com animação idle
	animated_sprite.play("idle c")
	
func cortar():
	# Toca animação de corte
	animated_sprite.play("cortada")
	
	# Aguarda a animação terminar
	await animated_sprite.animation_finished
	
	# Destroi a erva
	queue_free()
