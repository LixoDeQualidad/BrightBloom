# autoload/MapData.gd
extends Node

signal room_visited(room_name: String)

var room_grid_positions: Dictionary = {
	"Room_01": Vector2i(0, 0),
	"Room_02": Vector2i(1, 0),
	"Room_03": Vector2i(1, 1),
	"Room_04": Vector2i(1, 2),
	"Room_05": Vector2i(1, 3)
}

var visited_rooms: Dictionary = {}

func mark_visited(room_name: String) -> void:
	if not visited_rooms.has(room_name):
		visited_rooms[room_name] = true
		room_visited.emit(room_name)

func is_visited(room_name: String) -> bool:
	return visited_rooms.get(room_name, false)
