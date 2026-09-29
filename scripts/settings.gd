extends Node

var music_volume: float = 1.0
var sfx_volume: float = 1.0

const SAVE_PATH = "user://settings.cfg"
const ACTIONS_TO_SAVE = ["left", "right", "corte", "attack", "interact"]


func _ready() -> void:
	load_settings()
	apply_volumes()
	load_settings()
	apply_volumes()
	load_keybinds()

func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)

func save_keybinds() -> void:
	var config = ConfigFile.new()
	config.load(SAVE_PATH)  # mantém volume já salvo

	for action in ACTIONS_TO_SAVE:
		var events = InputMap.action_get_events(action)
		var data := []
		for e in events:
			if e is InputEventKey:
				data.append({"type": "key", "keycode": e.keycode})
			elif e is InputEventMouseButton:
				data.append({"type": "mouse", "button_index": e.button_index})
		config.set_value("keybinds", action, data)

	config.save(SAVE_PATH)

func load_keybinds() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		return

	for action in ACTIONS_TO_SAVE:
		if not config.has_section_key("keybinds", action):
			continue
		InputMap.action_erase_events(action)
		var data = config.get_value("keybinds", action, [])
		for entry in data:
			if entry["type"] == "key":
				var ev = InputEventKey.new()
				ev.keycode = entry["keycode"]
				InputMap.action_add_event(action, ev)
			elif entry["type"] == "mouse":
				var ev = InputEventMouseButton.new()
				ev.button_index = entry["button_index"]
				InputMap.action_add_event(action, ev)
