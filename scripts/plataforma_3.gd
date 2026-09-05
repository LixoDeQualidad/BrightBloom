extends CharacterBody2D

@export var distancia: float = 220.0
@export var velocidade: float = 80.0

var posicao_inicial: Vector2
var direcao: int = 1

func _ready():
	posicao_inicial = global_position

func _physics_process(delta):
	global_position.x += direcao * velocidade * delta

	var deslocamento = global_position.x - posicao_inicial.x

	if direcao == 1 and deslocamento >= distancia:
		global_position.x = posicao_inicial.x + distancia
		direcao = -1
	elif direcao == -1 and deslocamento <= 0:
		global_position.x = posicao_inicial.x
		direcao = 1
