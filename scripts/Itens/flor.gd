extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var cura_percentual: float = 0.6  # 60%
@onready var som_cura: AudioStreamPlayer2D = $SomCura


var player_in_range = false
var collected = false

func _process(_delta: float) -> void:
	if player_in_range and not collected and Input.is_action_just_pressed("interact"):
		collect()

func collect() -> void:
	collected = true
	anim.play("murchar")
	# impede que seja coletada de novo, mas continua visível no mapa
	collision.set_deferred("disabled", true)
	PlayerStats.heal_percent(cura_percentual)
	if som_cura:
		som_cura.play()

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
