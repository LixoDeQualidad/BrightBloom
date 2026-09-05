extends CharacterBody2D

# --- Diálogos ---
@export var dialogue_lines_preso: Array[String] = [
	"Ajude-me... estou preso!",
	"Por favor, me solte dessa cela."
]
@export var dialogue_lines_livre: Array[String] = [
	"Obrigado por me libertar!",
	"Vou ficar por perto, te seguindo.",
	"Cuidado com os lobos ao norte."
]

# --- Estado ---
var is_preso := true
var pode_interagir := false   # só true depois do sinal "Gaiola_aberta"
var player_in_range := false
var is_talking := false
var dialogue_index := 0
var player: Node2D = null

# --- Seguir o player ---
@export var follow_speed := 80.0
@export var follow_distance := 40.0

# --- Referência da gaiola (arraste o node da gaiola no Inspector) ---
@export var gaiola_path: NodePath
@onready var gaiola = get_node_or_null(gaiola_path)

@onready var dialogue_box = get_node("/root/pt_1_baixo/Cage/DialogueBox") # ajuste o caminho

func _ready():
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	

	if gaiola and gaiola.has_signal("Gaiola_aberta"):
		gaiola.connect("Gaiola_aberta", _on_gaiola_aberta)

func _on_gaiola_aberta():
	pode_interagir = true
	print("Sinal recebido: NPC agora pode interagir!")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player = body

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		_end_dialogue()

func _process(_delta):
	if not pode_interagir:
		return  # ignora completamente o input de interação

	if player_in_range and Input.is_action_just_pressed("interact"):
		if not is_talking:
			_start_dialogue()
		elif dialogue_box.is_typing:
			dialogue_box.skip_typing()
		else:
			_advance_dialogue()

func _physics_process(delta):
	if not is_preso and player and not is_talking:
		_follow_player(delta)
	else:
		velocity = Vector2.ZERO


func _follow_player(_delta):
	var distance = global_position.distance_to(player.global_position)
	if distance > follow_distance:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * follow_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _current_lines() -> Array[String]:
	return dialogue_lines_preso if is_preso else dialogue_lines_livre

func _start_dialogue():
	is_talking = true
	dialogue_index = 0
	dialogue_box.show()
	dialogue_box.set_text(_current_lines()[dialogue_index])

func _advance_dialogue():
	dialogue_index += 1
	var lines = _current_lines()
	if dialogue_index >= lines.size():
		_end_dialogue()
		if is_preso:
			libertar()
	else:
		dialogue_box.set_text(lines[dialogue_index])

func _end_dialogue():
	is_talking = false
	dialogue_box.hide()

func libertar():
	is_preso = false
	print("NPC foi libertado!")
