extends CharacterBody2D

@export var dialogue_lines: Array[String] = [
	"Olhe para este rio, Salvadora.",
	"Ele já foi muito mais limpo e cheio de vida.",
	"Com o tempo, a poluição chegou até suas águas, 
	e muitos dos que viviam aqui precisaram partir.",
	"Mas ainda há esperança. 
	Se você conseguir derrotar o Guardião Corrompido,
	 a vida poderá voltar.",
	"Talvez seja por isso que você tenha vindo até aqui."
]

var player_in_range := false
var dialogue_index := 0
var is_talking := false

@onready var dialogue_box = get_node("/root/Sala2/Npc3/DialogueBox")# ajuste o caminho


func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		_end_dialogue()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
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
