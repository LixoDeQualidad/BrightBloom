# ui/Map.gd
extends Control

const ROOM_SIZE := 24  # tamanho de cada "quadrado" no mapa, em pixels

func _draw() -> void:
	for room_name in MapData.room_grid_positions.keys():
		var grid_pos: Vector2i = MapData.room_grid_positions[room_name]
		var pixel_pos = Vector2(grid_pos.x, grid_pos.y) * (ROOM_SIZE + 2)

		var color: Color
		if MapData.is_visited(room_name):
			color = Color(0.9, 0.9, 0.9) # sala já visitada
		else:
			color = Color(0.2, 0.2, 0.2) # sala desconhecida (ou nem desenhe)

		draw_rect(Rect2(pixel_pos, Vector2(ROOM_SIZE, ROOM_SIZE)), color)

func _process(_delta: float) -> void:
	queue_redraw()  # redesenha toda vez que algo muda (pode otimizar depois)
