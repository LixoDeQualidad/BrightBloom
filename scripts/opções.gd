extends Control

@onready var music_slider: HSlider = $VBoxContainer2/HBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/HBoxContainer2/SFXSlider
@onready var btn_back: Button =   $Label/BtnBack # ajuste o caminho conforme sua cena

func _ready() -> void:
	MusicManager.play_menu_music()

	# carrega valores salvos (ou padrão 1.0)
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	# --- foco / navegação ---
	music_slider.focus_mode = Control.FOCUS_ALL
	sfx_slider.focus_mode = Control.FOCUS_ALL
	btn_back.focus_mode = Control.FOCUS_ALL

	music_slider.focus_neighbor_bottom = sfx_slider.get_path()
	sfx_slider.focus_neighbor_bottom = btn_back.get_path()
	btn_back.focus_neighbor_bottom = music_slider.get_path()

	music_slider.focus_neighbor_top = btn_back.get_path()
	sfx_slider.focus_neighbor_top = music_slider.get_path()
	btn_back.focus_neighbor_top = sfx_slider.get_path()

	music_slider.grab_focus()   # começa com algo focado


func _unhandled_input(event: InputEvent) -> void:
	# opcional: ESC / botão B também volta
	if event.is_action_pressed("ui_cancel"):
		_on_btn_back_pressed()
		get_viewport().set_input_as_handled()


func _on_music_changed(value: float) -> void:
	var idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	Settings.music_volume = value
	Settings.save_settings()


func _on_sfx_changed(value: float) -> void:
	var idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	Settings.sfx_volume = value
	Settings.save_settings()


func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
