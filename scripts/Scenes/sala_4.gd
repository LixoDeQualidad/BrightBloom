extends Node2D


func _ready() -> void:
	GameState.current_room_name = "Room_04"
	MapData.mark_visited("Room_04")
	MusicManager.play_game_music()
