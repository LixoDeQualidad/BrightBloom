# autoload/MapData.gd
extends Node

# Cada sala é uma posição na grade do MUNDO, não do tilemap
# Ex: Room_01 fica em (0,0), Room_02 fica uma tela à direita em (1,0)
var room_grid_positions: Dictionary = {
	"Room_01": Vector2i(0, 0),
	"Room_02": Vector2i(1, 0),
	"Room_03": Vector2i(1, 1),
}

var visited_rooms: Dictionary = {}

func mark_visited(room_name: String) -> void:
	visited_rooms[room_name] = true

func is_visited(room_name: String) -> bool:
	return visited_rooms.get(room_name, false)
