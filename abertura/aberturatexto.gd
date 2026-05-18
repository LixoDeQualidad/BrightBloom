extends CanvasLayer

var slides = [
	preload("res://abertura/4.png"),
	preload("res://abertura/5.png"),
]

var atual = 0

@onready var texture_rect = $TextureRect
@export var target_scene: PackedScene

func _ready():
	get_tree().paused = true
	_mostrar_slide()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # ESPAÇO
		atual += 1
		if atual >= slides.size():
			_terminar()
		else:
			_mostrar_slide()

func _mostrar_slide():
	texture_rect.texture = slides[atual]

func _terminar():
	get_tree().paused = false
	_start()

func _start ():
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)
