extends Button

@export var action_name: String = "interact"
@export var action_label: String = "Interagir"  # nome amigável, ex: "Andar Esquerda"

var waiting_for_input: bool = false

func _ready() -> void:
	if action_label == "":
		action_label = action_name.capitalize()
	_update_label()
	pressed.connect(_start_listening)

func _start_listening() -> void:
	if waiting_for_input:
		return
	waiting_for_input = true
	text = action_label + ": pressione uma tecla..."
	# opcional: capturar input mesmo fora do foco do botão
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not waiting_for_input:
		return

	# ESC cancela o remapeamento
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		waiting_for_input = false
		_update_label()
		get_viewport().set_input_as_handled()
		return

	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)
		waiting_for_input = false
		_update_label()
		Settings.save_keybinds()
		get_viewport().set_input_as_handled()

func _update_label() -> void:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		text = action_label + ": " + events[0].as_text()
	else:
		text = action_label + ": —"
