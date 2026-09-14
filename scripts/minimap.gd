# ui/Minimap.gd (ou RoomsDrawer.gd, se você separou como sugeri acima)
extends Control

const ROOM_SIZE := 20
const ROOM_GAP := 2
const CURRENT_ROOM_COLOR := Color(1, 1, 0.3)
const VISITED_ROOM_COLOR := Color(0.85, 0.85, 0.85)
const UNKNOWN_ROOM_COLOR := Color(0.15, 0.15, 0.15)

func _ready() -> void:
	MapData.room_visited.connect(func(_room_name): queue_redraw())
	queue_redraw()  # <- força o primeiro desenho, não espera o sinal

func _draw() -> void:
	var current_room = GameState.current_room_name
	if current_room == "" or not MapData.room_grid_positions.has(current_room):
		return

	var current_grid_pos: Vector2i = MapData.room_grid_positions[current_room]
	var center: Vector2 = size / 2.0  # centro do minimapa

	for room_name in MapData.room_grid_positions.keys():
		if not MapData.is_visited(room_name) and room_name != current_room:
			continue  # não desenha salas nunca visitadas

		var grid_pos: Vector2i = MapData.room_grid_positions[room_name]

		# posição relativa à sala atual, centralizada no minimapa
		var relative = Vector2(grid_pos.x - current_grid_pos.x, grid_pos.y - current_grid_pos.y)
		var pixel_pos = center + relative * (ROOM_SIZE + ROOM_GAP) - Vector2(ROOM_SIZE, ROOM_SIZE) / 2.0

		var color = VISITED_ROOM_COLOR
		if room_name == current_room:
			color = CURRENT_ROOM_COLOR

		draw_rect(Rect2(pixel_pos, Vector2(ROOM_SIZE, ROOM_SIZE)), color)
		draw_rect(Rect2(pixel_pos, Vector2(ROOM_SIZE, ROOM_SIZE)), Color.BLACK, false, 1.0)
