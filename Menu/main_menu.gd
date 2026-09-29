extends Control
func _ready():
	MusicManager.play_menu_music()
	
	
func _on_btn_jogar_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://abertura/aberturatexto.tscn")

func _on_btn_sair_pressed():
	get_tree().paused = false
	get_tree().quit()

func _on_btn_opcoes_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/opções.tscn")
