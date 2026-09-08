extends Node2D

@export var item_necessario: String = "brilho"
@export var target_scene_path: String
@export var target_spawn_point: String = "SpawnPoint_Default"

@onready var barreira: StaticBody2D = $Barreira
@onready var detector: Area2D = $DetectorBloqueio
var player_in_range := false
var dialogue_index := 0
var is_talking := false

@export var dialogue_lines: Array[String] = [
	"Aqui embaixo é escuro demais pra mim..."
]

@onready var dialogue_box = get_node("/root/Sala2/LookedDoor/DialogueBox")# ajuste o caminho

func _ready() -> void:
	detector.body_entered.connect(_on_detector_body_entered)
	GameManager.item_adicionado.connect(_on_item_adicionado)
	atualizar_barreira()

func atualizar_barreira() -> void:
	var tem = GameManager.tem_item(item_necessario)
	barreira.set_deferred("collision_layer", 0 if tem else 1)
	barreira.set_deferred("collision_mask", 0 if tem else 1)
	detector.monitoring = not tem

func _on_item_adicionado(nome_item: String) -> void:
	if nome_item == item_necessario:
		atualizar_barreira()

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not GameManager.tem_item(item_necessario):
		body.pode_mover = false
		body.velocity.x = 0
		body.sprite.play("no")
		player_in_range = true
		await body.sprite.animation_finished
		body.pode_mover = true

func _on_detector_bloqueio_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		_end_dialogue()

func _process(_delta):
	if player_in_range:
		if not is_talking:
			_start_dialogue()
		elif dialogue_box.is_typing:
			dialogue_box.skip_typing()
		else:
			_advance_dialogue()

func _start_dialogue():
	is_talking = true
	dialogue_index = 0
	dialogue_box.show()
	dialogue_box.set_text(dialogue_lines[dialogue_index])

func _advance_dialogue():
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		_end_dialogue()
	else:
		dialogue_box.set_text(dialogue_lines[dialogue_index])

func _end_dialogue():
	is_talking = false
	dialogue_box.hide()

func _on_passagem_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameState.change_room(target_scene_path, target_spawn_point)
