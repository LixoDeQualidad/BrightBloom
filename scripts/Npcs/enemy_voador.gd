extends CharacterBody2D

enum State { IDLE, CHASE, DASH, RECOVER }

@export var speed: float = 120.0
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var attack_range: float = 70.0
@export var attack_damage: int = 15
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var som_morrer: AudioStreamPlayer2D = $somDie

@export var max_health: int = 10
var current_health: int = max_health
var is_dead: bool = false

var player: Node2D = null
var state: State = State.IDLE
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var has_hit_this_dash: bool = false

@onready var detection_area: Area2D = $DetectionArea
@onready var hit_area: Area2D = $HitArea


func _ready() -> void:
	add_to_group("Enemies")
	current_health = max_health
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	hit_area.body_entered.connect(_on_hit_area_body_entered)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE:
			_chase(delta)
		State.DASH:
			_do_dash(delta)
		State.RECOVER:
			_recover(delta)

	move_and_slide()


func _chase(_delta: float) -> void:
	if player == null:
		state = State.IDLE
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attack_range and cooldown_timer <= 0.0:
		_start_dash()
	else:
		var direction := (player.global_position - global_position).normalized()
		velocity = direction * speed
	sprite.play("idle")


func _start_dash() -> void:
	state = State.DASH
	dash_timer = dash_duration
	has_hit_this_dash = false
	dash_direction = (player.global_position - global_position).normalized()
	sprite.play("attack")


func _do_dash(delta: float) -> void:
	velocity = dash_direction * dash_speed
	dash_timer -= delta
	if dash_timer <= 0.0:
		state = State.RECOVER
		cooldown_timer = dash_cooldown


func _recover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, speed * 5 * delta)
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		state = State.CHASE if player != null else State.IDLE


func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		if state == State.IDLE:
			state = State.CHASE


func _on_detection_body_exited(body: Node) -> void:
	if body == player:
		player = null
		state = State.IDLE
		velocity = Vector2.ZERO


func _on_hit_area_body_entered(body: Node) -> void:
	if is_dead:
		return
	if body.is_in_group("Player") and state == State.DASH and not has_hit_this_dash:
		has_hit_this_dash = true
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)


# Chamado pela AttackArea do player: body.take_damage(attack_damage)
func take_damage(amount: int = 10) -> void:
	sprite.play("hurt")
	if is_dead:
		return
	current_health = max(current_health - amount, 0)
	# opcional: flash de dano, som, etc.
	if current_health <= 0:
		die()


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	hit_area.monitoring = false
	detection_area.monitoring = false
	# toque animação de morte / som / drop de item aqui, depois:
	queue_free()
	sprite.play("die")
	som_morrer.play()
