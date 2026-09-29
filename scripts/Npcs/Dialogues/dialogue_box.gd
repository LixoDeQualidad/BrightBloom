extends CanvasLayer

@onready var label = $Panel/Label
@onready var sound_player = $Panel/AudioStreamPlayer2D

@export var typing_speed := 0.03
@export var voice_sound: AudioStream

var full_text := ""
var is_typing := false
var char_index := 0

func _ready():
	sound_player.bus = "SFX"

func set_text(text: String):
	full_text = text
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

func skip_typing():
	is_typing = false
	label.text = full_text
	_finish_typing()

func _finish_typing():
	is_typing = false
	sound_player.stop()
