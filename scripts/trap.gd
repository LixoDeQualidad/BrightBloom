extends Area2D
# ==========================================================
# ARMADILHA (Trap)
# Estrutura de nós esperada:
#
# Trap (Area2D)
# ├── Sprite2D
# ├── CollisionShape2D
# └── AnimationPlayer (opcional) -> animação "trigger"
#
# O Player precisa ter um método take_damage(amount: int)
# (já existe em Player.gd) e, de preferência, estar no grupo "player".
# ==========================================================

@export var damage: int = 50


# Se true, a armadilha causa dano várias vezes enquanto o player
# permanecer dentro dela (com intervalo definido em "tick_interval").
# Se false, causa dano só uma vez por contato (precisa sair e entrar de novo).
@export var damage_over_time: bool = false
@export var tick_interval: float = 1.0

# Se true, a armadilha se destrói/desativa após o primeiro uso (ex: espinho que quebra)
@export var one_shot: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var collision: CollisionShape2D = $CollisionShape2D

var _bodies_inside: Array[Node] = []
var _tick_timer: Timer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if damage_over_time:
		_tick_timer = Timer.new()
		_tick_timer.wait_time = tick_interval
		_tick_timer.autostart = false
		_tick_timer.timeout.connect(_on_tick_timeout)
		add_child(_tick_timer)


func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return

	_apply_damage(body)

	if damage_over_time:
		_bodies_inside.append(body)
		if _tick_timer.is_stopped():
			_tick_timer.start()


func _on_body_exited(body: Node) -> void:
	if not _is_player(body):
		return

	if damage_over_time:
		_bodies_inside.erase(body)
		if _bodies_inside.is_empty():
			_tick_timer.stop()


func _on_tick_timeout() -> void:
	for body in _bodies_inside:
		_apply_damage(body)


func _apply_damage(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		sprite.play("trigger")

	if one_shot:
		_disable_trap()


func _disable_trap() -> void:
	collision.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	if _tick_timer:
		_tick_timer.stop()


func _is_player(body: Node) -> bool:
	# Funciona tanto detectando pelo grupo "player" quanto pelo método take_damage,
	# assim não precisa configurar grupo se você não quiser.
	return body.is_in_group("Player") or body.has_method("take_damage")
