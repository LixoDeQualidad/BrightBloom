extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect


var tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	color_rect.modulate.a = 0.0
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	if visible:
		fechar_pause()
	else:
		abrir_pause()

func abrir_pause() -> void:
	visible = true
	get_tree().paused = true

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.2)
	

func fechar_pause() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.15)

	tween.finished.connect(func():
		visible = false
		get_tree().paused = false
	, CONNECT_ONE_SHOT)

func _on_button_continuar_pressed() -> void:
	toggle_pause()

func _on_btn_sair_pressed():
	get_tree().quit()
	
func _on_btn_menu_pressed():
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
