extends Area2D

@export var nome_item: String = "brilho"
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	# Evita disparar de novo enquanto o som toca
	set_deferred("monitoring", false)
	GameManager.adicionar_item(nome_item)
	GameManager.luz_coletada = true

	# Ativa a luz do personagem
	var luz := body.get_node_or_null("PointLight2D") as PointLight2D
	if luz:
		luz.enabled = true

	# Toca a animação "luz" via função do próprio player
	if body.has_method("tocar_animacao_luz"):
		body.tocar_animacao_luz()

	sound.play()
	queue_free()
