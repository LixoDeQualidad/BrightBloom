extends Control

func _on_btn_jogar_pressed():
	get_tree().change_scene_to_file("res://abertura/aberturatexto.tscn")

func _on_btn_sair_pressed():
	get_tree().quit()

func _on_btn_opcoes_pressed():
	get_tree().change_scene_to_file("res://scene/opções.tscn")


func _on_button_pressed() -> void:
	pass # Replace with function body.
