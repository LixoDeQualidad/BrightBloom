extends Node

signal health_changed(current_health: int, max_health: int)
signal player_damaged(amount: int)
signal player_died

@export var max_health: int = 100

var current_health: int = max_health
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health = max(current_health - amount, 0)
	player_damaged.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	if is_dead:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	
func heal_percent(percent: float) -> void:
	var amount := int(max_health * percent)
	heal(amount)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	player_died.emit()


# Útil para quando o player "renasce" ou inicia um novo jogo
func reset_health() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
