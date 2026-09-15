# no script raiz de cada Room (ex: Room_01.gd)
extends Node2D

func _ready() -> void:
	GameState.current_room_name = "Room_02"
	MapData.mark_visited("Room_02")
	MusicManager.play_game_music()
