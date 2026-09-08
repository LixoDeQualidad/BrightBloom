extends Node2D

func _ready() -> void:
	MapData.mark_visited("Room_03")
	MusicManager.play_game_music()
