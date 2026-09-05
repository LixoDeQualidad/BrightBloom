extends CharacterBody2D
## NPC de tutorial: segue o player, pede 3 ações (interagir, atacar, pulo duplo)
## e toca uma animação de reação antes de voltar a seguir.

# ---------- REFERÊNCIAS ----------
@export var player_path: NodePath
@export var dialogue_box_path: NodePath  
@export var gravity := 900.0        # o CanvasLayer da sua dialogue box (script que você mandou)

@onready var player: CharacterBody2D = $"../Player"
@onready var dialogue_box: CanvasLayer= $DialogueBox
@onready var anim: AnimationPlayer = $AnimationPlayer   # ajuste o path se o seu AnimationPlayer estiver em outro lugar

# ---------- MOVIMENTO (seguir o player) ----------
@export var follow_speed := 120.0
@export var follow_distance := 60.0   # distância que o NPC mantém do player enquanto segue

# ---------- NOMES DAS ANIMAÇÕES ----------
# Troque pelos nomes reais das animações que você criou no AnimationPlayer do NPC.
@export var anim_idle := "idle"
@export var anim_walk := "walk"
@export var anim_react_interact := "react_interact"
@export var anim_react_attack := "react_attack"
@export var anim_react_jump := "react_jump"
@export var anim_celebrate_final := "celebrate"

# ---------- TEXTOS ----------
@export_multiline var text_intro := "Ei! Antes de começar, vou te ensinar uns comandos."
@export_multiline var text_ask_interact := "Aperte [E] para interagir comigo!"
@export_multiline var text_ask_attack := "Muito bem! Agora aperte [Q] para atacar!"
@export_multiline var text_ask_jump := "Perfeito! Agora,aperte [Espaço] ou [W]
 DUAS VEZES para dar um pulo duplo!"
@export_multiline var text_success_interact := "Boa! é assim que se interage."
@export_multiline var text_success_attack := "Isso aí! é assim que se ataca."
@export_multiline var text_success_jump := "Mandou bem! Agora você sabe o pulo duplo."
@export_multiline var text_final := "Pronto! Agora é com você. Boa sorte!"

# ---------- CONFIG PULO DUPLO ----------
@export var double_jump_window := 0.4   # tempo máximo (s) entre as duas apertadas

# ---------- MÁQUINA DE ESTADOS ----------
enum State { FOLLOWING, WAITING_INTERACT, WAITING_ATTACK, WAITING_JUMP, REACTING, FINISHED }
var state: State = State.FOLLOWING

var _jump_press_count := 0
var _last_jump_press_time := 0.0

signal tutorial_finished


func _ready() -> void:
	dialogue_box.visible = false
	anim.play(anim_idle)
	# pequena espera antes de começar o tutorial, pra dar tempo do player aparecer na cena
	await get_tree().create_timer(1.0).timeout
	start_tutorial()


func start_tutorial() -> void:
	_show_text(text_intro)
	await get_tree().create_timer(5.0).timeout
	_ask_interact()


# ---------- SEGUIR O PLAYER ----------
func _physics_process(delta: float) -> void:
	# aplica gravidade sempre, esteja seguindo ou não
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if state != State.FOLLOWING:
		velocity.x = 0.0
		move_and_slide()
		return

	var dir_x := player.global_position.x - global_position.x
	var dist := absf(dir_x)

	if dist > follow_distance:
		velocity.x = sign(dir_x) * follow_speed
		if anim.current_animation != anim_walk:
			anim.play(anim_walk)
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.flip_h = dir_x > 0
	else:
		velocity.x = 0.0
		if anim.current_animation != anim_idle:
			anim.play(anim_idle)

	move_and_slide()


# ---------- INPUT (E / Q / ESPAÇO-W duplo) ----------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key: Key = event.physical_keycode

	match state:
		State.WAITING_INTERACT:
			if key == KEY_E:
				_on_action_success("interact")

		State.WAITING_ATTACK:
			if key == KEY_Q:
				_on_action_success("attack")

		State.WAITING_JUMP:
			if key == KEY_SPACE or key == KEY_W:
				_register_jump_press()


func _register_jump_press() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_jump_press_time <= double_jump_window:
		_jump_press_count += 1
	else:
		_jump_press_count = 1
	_last_jump_press_time = now

	if _jump_press_count >= 2:
		_jump_press_count = 0
		_on_action_success("jump")


# ---------- PEDIR CADA AÇÃO ----------
func _ask_interact() -> void:
	state = State.WAITING_INTERACT
	_show_text(text_ask_interact)


func _ask_attack() -> void:
	state = State.WAITING_ATTACK
	_show_text(text_ask_attack)


func _ask_jump() -> void:
	state = State.WAITING_JUMP
	_show_text(text_ask_jump)


# ---------- REAÇÃO A CADA ACERTO ----------
func _on_action_success(action: String) -> void:
	state = State.REACTING
	velocity = Vector2.ZERO

	match action:
		"interact":
			anim.play(anim_react_interact)
			_show_text(text_success_interact)
		"attack":
			anim.play(anim_react_attack)
			_show_text(text_success_attack)
		"jump":
			anim.play(anim_react_jump)
			_show_text(text_success_jump)

	# espera a animação de reação terminar antes de continuar
	await anim.animation_finished
	anim.play(anim_idle)
	await get_tree().create_timer(0.8).timeout

	match action:
		"interact":
			state = State.FOLLOWING
			await get_tree().create_timer(1.5).timeout
			_ask_attack()
		"attack":
			state = State.FOLLOWING
			await get_tree().create_timer(1.5).timeout
			_ask_jump()
		"jump":
			_finish_tutorial()


func _finish_tutorial() -> void:
	state = State.FINISHED
	anim.play("celebrate")
	_show_text(text_final)
	await get_tree().create_timer(5.0).timeout
	dialogue_box.visible = false
	tutorial_finished.emit()


# ---------- HELPER DA DIALOGUE BOX ----------
func _show_text(text: String) -> void:
	dialogue_box.visible = true
	dialogue_box.set_text(text)
