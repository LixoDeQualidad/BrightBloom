extends StaticBody2D
# ==========================================================
# OBJETO DESTRUTÍVEL
# Estrutura de nós esperada:
#
# Destructible (StaticBody2D)  -> IMPORTANTE: adicionar ao grupo "destructible"
#                                  (Node > Groups, ou faça isso no _ready abaixo)
# ├── AnimatedSprite2D
# ├── CollisionShape2D
# └── (opcional) usar frames "hit" e "break" no AnimatedSprite2D
# ==========================================================
@export var max_health: int = 10
@export var break_effect_scene: PackedScene  # opcional: cena de partículas/estilhaços

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var current_health: int
var is_broken: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("destructible")


func take_damage(amount: int) -> void:
	if is_broken:
		return

	current_health -= amount

	if current_health <= 0:
		break_object()
	else:
		_play_hit_feedback()


func _play_hit_feedback() -> void:
	# Toca animação de "hit" se ela existir, sem interromper outras lógicas
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		# volta pro idle depois que o hit terminar (se ele não fizer isso sozinho)
		if not sprite.animation_finished.is_connected(_on_hit_finished):
			sprite.animation_finished.connect(_on_hit_finished, CONNECT_ONE_SHOT)


func _on_hit_finished() -> void:
	if not is_broken and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func break_object() -> void:
	if is_broken:
		return
	is_broken = true

	# Desativa colisão imediatamente para não bloquear mais o player
	collision.set_deferred("disabled", true)

	# Spawna efeito de partículas/estilhaços, se houver
	if break_effect_scene:
		var effect = break_effect_scene.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)

	# Toca animação de quebra e só remove o objeto depois que ela terminar
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("break"):
		sprite.play("break")
		await sprite.animation_finished
	
	queue_free()
