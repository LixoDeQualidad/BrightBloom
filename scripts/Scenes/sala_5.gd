extends Node2D


func _ready() -> void:
	MapData.mark_visited("Room_05")
	MusicManager.play_game_music()
