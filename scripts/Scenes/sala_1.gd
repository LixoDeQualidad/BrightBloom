# no script raiz de cada Room (ex: Room_01.gd)
extends Node2D

func _ready() -> void:
	MapData.mark_visited("Room_01")
	MusicManager.play_game_music()
