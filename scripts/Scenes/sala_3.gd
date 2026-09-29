extends Node2D

func _ready() -> void:
	GameState.current_room_name = "Room_03"
	MapData.mark_visited("Room_03")
	MusicManager.play_game_music()
