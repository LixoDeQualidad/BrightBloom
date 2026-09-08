extends CharacterBody2D

@export var speed: float = 50.0
@export var gravity: float = 900.0
@onready var damage_area: Area2D = $DamageArea
@export var damage_to_player: int = 10

var direction: int = 1  # 1 = direita, -1 = esquerda
var is_dead: bool = false


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	# Verifica parede na frente
	if $WallDetector.is_colliding():
		turn_around()

	velocity.x = speed * direction
	move_and_slide()

func turn_around() -> void:
	direction *= -1
	$WallDetector.target_position.x *= -1
	$AnimatedSprite2D.flip_h = direction < 0
	# se o HeadHitbox ou outros nós dependerem da direção, ajuste aqui também

func _on_head_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		die()
		if body.has_method("bounce"):
			body.bounce()

func die() -> void:
	$AnimatedSprite2D.play ("die")
	queue_free()
	is_dead = true

func _on_damage_area_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.has_method("_on_player_damaged") and body.is_in_group("Player"):
		body.take_damage(damage_to_player)



func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("Player"):
		body.take_damage(damage_to_player)
