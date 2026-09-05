extends CharacterBody2D

@export var speed: float = 20.0        # velocidade de movimento
@export var distance: float = 100.0     # distância total do movimento

var start_pos: Vector2
var direction: int = 1   # 1 = desce, -1 = sobe

func _ready():
	start_pos = position

func _physics_process(delta):
	# Move verticalmente
	velocity.y = speed * direction
	move_and_slide()
	
	# Verifica limites
	if position.y >= start_pos.y + distance:
		direction = -1  # muda para subir
	elif position.y <= start_pos.y - distance:
		direction = 1   # muda para descer
