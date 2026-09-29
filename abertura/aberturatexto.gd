extends CanvasLayer

@export var background: Texture2D
@export var target_scene: PackedScene

@export var typing_speed := 0.03
@export var voice_sound: AudioStream

@export var intro_texts: Array[String] = [
	"A floresta não mudou derrepente",
	"Primeiro vieram pequenos sinais:",
	"folhas manchadas água turva, um ar mais pesado...",
	"Com o tempo o mau cheiro e o silêncio tomaram conta",
	"e a vida começou a enfraquecer",
	"Mesmo assim, a floresta ainda resistia.",
	"Sentindo um fraco pulsar de vida sob a terra,",
	"Lumina entendeu que ainda havia esperança.",
	"Abriu suas asas, deixando um brilho suave cortar a escuridão,",
	 "e seguiu pelas regiões mais afetadas —",
	"determinada a encontrar a origem da corrupção e limpar cada traço dela.",
	"Porque foi para isso que ela nasceu."
]

@onready var background_rect = $AberturaFundo
@onready var label = $Label
@onready var sound_player = $SoundPlayer

var current_index := 0
var full_text := ""
var is_typing := false
var char_index := 0

func _ready():
	MusicManager.play_game_music()
	process_mode = Node.PROCESS_MODE_ALWAYS
	sound_player.bus = "SFX"
	background_rect.texture = background
	get_tree().paused = true
	_show_text(current_index)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # ESPAÇO
		if is_typing:
			_skip_typing()
		else:
			_advance()

func _show_text(index: int):
	full_text = intro_texts[index]
	label.text = ""
	char_index = 0
	is_typing = true
	_type_next_char()

func _type_next_char():
	if not is_typing:
		return

	if char_index < full_text.length():
		label.text += full_text[char_index]
		char_index += 1

		if full_text[char_index - 1] != " ":
			sound_player.stream = voice_sound
			sound_player.pitch_scale = randf_range(0.9, 1.1)
			sound_player.play()

		await get_tree().create_timer(typing_speed).timeout
		_type_next_char()
	else:
		_finish_typing()

func _skip_typing():
	is_typing = false
	label.text = full_text
	_finish_typing()

func _finish_typing():
	is_typing = false
	sound_player.stop()

func _advance():
	current_index += 1
	if current_index >= intro_texts.size():
		_terminar()
	else:
		_show_text(current_index)

func _terminar():
	get_tree().paused = false
	if target_scene:
		get_tree().change_scene_to_file ("res://MapaCenas/Tutorial.tscn")
