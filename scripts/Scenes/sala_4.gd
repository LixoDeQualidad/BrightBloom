extends Node2D


func _ready() -> void:
	MapData.mark_visited("Room_04")
	MusicManager.play_game_music()
