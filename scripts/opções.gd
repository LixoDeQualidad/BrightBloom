extends Control

@onready var music_slider: HSlider = $VBoxContainer2/HBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/HBoxContainer2/SFXSlider

func _ready() -> void:
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	MusicManager.play_menu_music()

	# carrega valores salvos (ou padrão 1.0)
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

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
	
func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
