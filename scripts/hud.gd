extends CanvasLayer

@onready var pause_menu = get_node("/root/pt_1_baixo/PauseMenu")

func _on_button_pause_pressed() -> void:
	pause_menu.toggle_pause()
