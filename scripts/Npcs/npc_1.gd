extends CharacterBody2D

@export var dialogue_lines: Array[String] = [
	"Então... finalmente você veio.",
	"Há quanto tempo esperávamos pela Salvadora.",
	"A floresta vem adoecendo há muito tempo,
	 mas você demorou para partir.",
	"Enquanto você permanecia longe,
	 as árvores caíam,",
	"os rios eram contaminados e 
	os animais abandonavam seus lares.",
	"Talvez você não soubesse o tamanho
	 daquilo que estava acontecendo.",
	"Mas agora que veio, não pode mais 
	ignorar o que verá pelo caminho."


]

var player_in_range := false
var dialogue_index := 0
var is_talking := false

@onready var dialogue_box = get_node("/root/Sala1/Npc_1/DialogueBox")# ajuste o caminho


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
