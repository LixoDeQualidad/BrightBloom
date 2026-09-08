extends Node2D

@onready var ponto_inicio: Marker2D = $PontoInicio
@onready var ponto_fim: Marker2D = $PontoFim
@onready var area: Area2D = $Area2D
@onready var som_tirolesa: AudioStreamPlayer2D = $SomTirolesa

var velocidade: float = 400.0
var jogador_na_tirolesa: bool = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if jogador_na_tirolesa:
		return
	if body.is_in_group("Player"):
		iniciar_tirolesa(body)

func iniciar_tirolesa(player: Node2D) -> void:
	jogador_na_tirolesa = true

	var indo_para: Vector2
	if player.global_position.distance_to(ponto_inicio.global_position) < player.global_position.distance_to(ponto_fim.global_position):
		indo_para = ponto_fim.global_position
	else:
		indo_para = ponto_inicio.global_position

	if player.has_method("entrar_na_tirolesa"):
		player.entrar_na_tirolesa()

	som_tirolesa.play()  # começa o som

	var distancia := player.global_position.distance_to(indo_para)
	var tempo := distancia / velocidade

	var tween := create_tween()
	tween.tween_property(player, "global_position", indo_para, tempo)
	tween.finished.connect(func():
		jogador_na_tirolesa = false
		som_tirolesa.stop()  # para o som ao chegar no fim
		if player.has_method("sair_da_tirolesa"):
			player.sair_da_tirolesa()
)
