extends Button

const ACTIONS = ["left", "right", "cortar", "attack", "interact"]

func _ready() -> void:
	pressed.connect(_reset)

func _reset() -> void:
	InputMap.load_from_project_settings()
	Settings.save_keybinds()
	get_tree().reload_current_scene()  # simples: recarrega a tela pra atualizar os labels
