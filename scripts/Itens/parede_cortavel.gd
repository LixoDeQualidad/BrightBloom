extends Node2D
@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@export var animacao_corte: String = "cortada"
var player_in_range := false
var ja_cortada := false
var player_ref: Node = null

func _ready():
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body
		print("player no range")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null

func _process(_delta):
	if ja_cortada:
		return
	if player_in_range and Input.is_action_just_pressed("interact"):
		if GameManager.tem_item("faca"):
			_cortar_parede()

func _cortar_parede() -> void:
	ja_cortada = true
	collision_shape.set_deferred("disabled", true)

	if player_ref and player_ref.has_method("usar_faca"):
		await player_ref.usar_faca()

	anim_player.play(animacao_corte)
	await anim_player.animation_finished
