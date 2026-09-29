# ui/Minimap.gd (ou RoomsDrawer.gd, se você separou como sugeri acima)
extends Control

const ROOM_SIZE := 10         # largura/altura de cada quadrado (px) -> mexa aqui pra mudar o TAMANHO
const ROOM_GAP := 1           # espaço entre quadrados vizinhos (px)
const MARGIN := Vector2(1, 1) # deslocamento do quadrado da grade (0,0) a partir do canto sup. esq. do desenho

const CURRENT_ROOM_COLOR := Color(0.678, 0.91, 0.659, 0.561)
const VISITED_ROOM_COLOR := Color(0.898, 0.804, 0.753, 0.584)
const UNKNOWN_ROOM_COLOR := Color(0.851, 0.859, 0.992, 0.427)

func _ready() -> void:
	MapData.room_visited.connect(func(_room_name): queue_redraw())
	queue_redraw()  # <- força o primeiro desenho, não espera o sinal

func _draw() -> void:
	var current_room = GameState.current_room_name

	for room_name in MapData.room_grid_positions.keys():
		# POSIÇÃO de cada sala vem da coordenada de grade em MapData.room_grid_positions.
		# Para mudar onde um quadrado específico aparece, edite o Vector2i dele lá.
		var grid_pos: Vector2i = MapData.room_grid_positions[room_name]
		var pixel_pos = MARGIN + Vector2(grid_pos.x, grid_pos.y) * (ROOM_SIZE + ROOM_GAP)

		var color = UNKNOWN_ROOM_COLOR       # sala nunca visitada
		if MapData.is_visited(room_name):
			color = VISITED_ROOM_COLOR       # já visitada, mas não é a atual
		if room_name == current_room:
			color = CURRENT_ROOM_COLOR       # sala onde o jogador está agora

		draw_rect(Rect2(pixel_pos, Vector2(ROOM_SIZE, ROOM_SIZE)), color)
		draw_rect(Rect2(pixel_pos, Vector2(ROOM_SIZE, ROOM_SIZE)), Color.BLACK, false, 1.0)
