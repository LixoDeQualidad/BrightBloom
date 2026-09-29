extends StaticBody2D

signal Gaiola_aberta

@export var item_necessario: String = "chave"
@onready var interaction_area: Area2D = $InteractionArea
@onready var npc_preso: Node = $NpcPreso
@onready var sprite_fechada: Sprite2D = $GaiolaFechada
@onready var sprite_aberta: Sprite2D = $GaiolaAberta
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var player_in_range := false
var esta_aberta := false
var is_talking := false
var dialogue_index := 0
var dialogue_lines: Array[String] = []

func _ready():
	sprite_fechada.visible = true
	sprite_aberta.visible = false



func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false

func _process(_delta):
	if not player_in_range or esta_aberta:
		return
	if Input.is_action_just_pressed("interact"):
		_tentar_abrir()

func _tentar_abrir():
	if GameManager.tem_item(item_necessario):
		_abrir_gaiola()

func _abrir_gaiola():
	esta_aberta = true
	sprite_fechada.visible = false
	sprite_aberta.visible = true

	emit_signal("Gaiola_aberta")  # avisa quem estiver escutando (ex: o NPC)
	collision_shape.set_deferred("disabled", true)

	if npc_preso and npc_preso.has_method("libertar"):
		npc_preso.libertar()
