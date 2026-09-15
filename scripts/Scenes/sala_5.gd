extends Node2D


func _ready() -> void:
	GameState.current_room_name = "Room_05"
	MapData.mark_visited("Room_05")
	MusicManager.play_game_music()
