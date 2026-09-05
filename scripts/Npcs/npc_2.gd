extends CharacterBody2D

@export var dialogue_lines: Array[String] = [
	"Boa sorte em limpar o restante da floresta, querida!"
]

@export_enum("coin_1", "coin_2") var required_item_type: String = "coin_1"
@export var required_items: int = 5
@export var quest_lines_incomplete: Array[String] = [
	"Ei, viajante! Cuidado por onde passa.",
	"Tenho encontrado coisas estranhas espalhadas pela floresta... 
	garrafas, embalagens e sacolas.",
	"Para quem as deixa aqui, pode parecer apenas lixo.",
	"Para nós, pode significar perigo.",
	"Encontre %d resíduos e traga-os até mim." ,
	"Pode parecer pouco, mas cada pedaço retirado daqui ajuda 
	a floresta a respirar novamente." 

]
@export var quest_lines_complete: Array[String] = [
	"Você conseguiu! 
	Essa área da floresta está muito mais limpa.",
	"Talvez uma única alma não consiga limpar uma floresta inteira...
	 mas cada atitude conta.",
	"Como prometido, aceite isto como agradecimento."

]
@export var reward_scene: PackedScene

var player_in_range := false
var dialogue_index := 0
var is_talking := false
var quest_given := false

@onready var dialogue_box = get_node("/root/Sala1/Npc2/DialogueBox")
@onready var sprite = $AnimatedSprite2D



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

func _get_current_lines() -> Array[String]:
	if quest_given:
		return dialogue_lines
	elif GameManager.get_count(required_item_type) >= required_items:
		return quest_lines_complete
	else:
		return quest_lines_incomplete

func _start_dialogue():
	is_talking = true
	dialogue_index = 0
	dialogue_box.show()
	var lines = _get_current_lines()
	dialogue_box.set_text(lines[dialogue_index] % required_items if "%d" in lines[dialogue_index] else lines[dialogue_index])

func _advance_dialogue():
	var lines = _get_current_lines()
	dialogue_index += 1

	if dialogue_index >= lines.size():
		_end_dialogue()
		_check_reward()
	else:
		var line = lines[dialogue_index]
		dialogue_box.set_text(line % required_items if "%d" in line else line)

func _check_reward():
	if not quest_given and GameManager.get_count(required_item_type) >= required_items:
		quest_given = true
		_play_give_animation()

func _play_give_animation() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.15)
	tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.1)
	tween.tween_callback(_drop_reward)

func _drop_reward() -> void:
	if reward_scene:
		var reward = reward_scene.instantiate()
		get_parent().add_child(reward)
		reward.global_position = global_position + Vector2(0, 20)
		reward.scale = Vector2.ZERO

		var item_tween = create_tween()
		item_tween.tween_property(reward, "global_position:y", reward.global_position.y - 15, 0.3).set_trans(Tween.TRANS_SINE)
		item_tween.parallel().tween_property(reward, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _end_dialogue():
	is_talking = false
	dialogue_box.hide()
