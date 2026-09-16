extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

# Ajuste os caminhos conforme sua cena
@onready var btn_continuar: Button = $ButtonContinuar
@onready var btn_menu: Button = $ButtonMenu
@onready var btn_sair: Button = $ButtonSair

var tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	color_rect.modulate.a = 0.0

	# Garante que os botões podem receber foco e funcionam pausado
	for b in [btn_continuar, btn_menu, btn_sair]:
		b.focus_mode = Control.FOCUS_ALL
		b.process_mode = Node.PROCESS_MODE_ALWAYS

	# Navegação circular com ui_up / ui_down
	btn_continuar.focus_neighbor_bottom = btn_menu.get_path()
	btn_menu.focus_neighbor_bottom = btn_sair.get_path()
	btn_sair.focus_neighbor_bottom = btn_continuar.get_path()

	btn_continuar.focus_neighbor_top = btn_sair.get_path()
	btn_menu.focus_neighbor_top = btn_continuar.get_path()
	btn_sair.focus_neighbor_top = btn_menu.get_path()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if visible:
		fechar_pause()
	else:
		abrir_pause()


func abrir_pause() -> void:
	visible = true
	get_tree().paused = true
	btn_continuar.grab_focus()   # <- essencial para o ui_accept funcionar

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.2)


func fechar_pause() -> void:
	# Tira o foco para o ui_accept não vazar para o jogo
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

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

func _on_btn_sair_pressed() -> void:
	get_tree().quit()

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
