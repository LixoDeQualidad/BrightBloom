extends Node

const MENU_MUSIC = preload("res://audio/caetano.mp3")
const GAME_MUSIC = preload("res://audio/caetano.mp3")

const FADE_DURATION := 1.5
const MAX_VOLUME_DB := 0.0
const MIN_VOLUME_DB := -40.0

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer

var current_stream: AudioStream = null
var fade_tween: Tween

func _ready():
	_set_loop(MENU_MUSIC)
	_set_loop(GAME_MUSIC)

	player_a = _create_player()
	player_b = _create_player()
	active_player = player_a
	inactive_player = player_b

func _create_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = MIN_VOLUME_DB
	add_child(p)
	return p

func _set_loop(stream: AudioStream):
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

func play_menu_music():
	_crossfade_to(MENU_MUSIC)

func play_game_music():
	_crossfade_to(GAME_MUSIC)

func stop_music():
	_crossfade_to(null)

func _crossfade_to(stream: AudioStream):
	if stream == current_stream:
		return

	current_stream = stream

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	var fading_out := active_player
	var fading_in := inactive_player

	if stream != null:
		fading_in.stream = stream
		fading_in.volume_db = MIN_VOLUME_DB
		fading_in.play()

	fade_tween = create_tween()
	fade_tween.set_parallel(true)

	fade_tween.tween_property(fading_out, "volume_db", MIN_VOLUME_DB, FADE_DURATION)
	if stream != null:
		fade_tween.tween_property(fading_in, "volume_db", MAX_VOLUME_DB, FADE_DURATION)

	fade_tween.chain().tween_callback(func():
		fading_out.stop()
	)

	active_player = fading_in
	inactive_player = fading_out
