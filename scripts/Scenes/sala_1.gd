# no script raiz de cada Room (ex: Room_01.gd)
extends Node2D

func _ready() -> void:
	GameState.current_room_name = "Room_01"
	GameState.show_minimap()
	MapData.mark_visited("Room_01")
	MusicManager.play_game_music()
