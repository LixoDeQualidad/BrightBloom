extends CharacterBody2D

enum BossState {
	walk,
	attack,
	hurt,
	idle,
	die
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector

@export var max_health: int = 200
@export var current_health: int = 200
@export var damage: int = 15
@export var invincibility_duration: float = 1.0
@export var attack_damage_default: int = 1  # Dano padrão caso não consiga obter do player

const SPEED = 50.0
const ATTACK_RANGE = 50.0

var status: BossState
var direction = 1
var player: Node2D = null
var can_attack = true
var last_direction = 0

var is_invincible: bool = false
var invincibility_timer: Timer
var is_dead: bool = false

signal health_changed(current_health, max_health)
signal boss_spawned
signal boss_defeated

func _ready() -> void:
	go_to_walk_state()
	player_detector.enabled = true
	boss_spawned.emit()
	
	# Configurar hitbox - MUDAR PARA CONEXÃO MAIS ROBUSTA
	if hitbox:
		# Conectar ao sinal area_entered se não estiver conectado
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	
	# Timer de invencibilidade
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_child(invincibility_timer)
	
	current_health = max_health
	print("Boss iniciado com ", current_health, "/", max_health, " de vida")
	
	add_to_group("Enemies")
	
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("register_boss"):
			gm.register_boss(self)
	
	health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		BossState.walk:
			walk_state(delta)
		BossState.attack:
			attack_state(delta)
		BossState.hurt:
			hurt_state(delta)
		BossState.idle:
			idle_state(delta)
		BossState.die:
			die_state(delta)

	move_and_slide()

func take_damage(amount: int):
	if is_invincible or status == BossState.die or is_dead:
		print("Boss não pode tomar dano agora")
		return
	
	print("BOSS: Tomou ", amount, " de dano! Vida antes: ", current_health)
	current_health -= amount
	current_health = max(0, current_health)
	
	print("BOSS: Vida agora: ", current_health, "/", max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()
	else:
		go_to_hurt_state()
		start_invincibility()
		flash_effect()

func die():
	if is_dead:
		return
		
	print("Boss derrotado!")
	is_dead = true
	status = BossState.die
	
	boss_defeated.emit()
	
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	player_detector.enabled = false
	
	if invincibility_timer and invincibility_timer.is_stopped() == false:
		invincibility_timer.stop()
	is_invincible = false
	
	if anim.sprite_frames and anim.sprite_frames.has_animation("die_boss"):
		anim.play("die_boss")
		await anim.animation_finished
	else:
		anim.play("hurt_boss")
		await get_tree().create_timer(0.5).timeout
	
	queue_free()

func start_invincibility():
	if is_dead:
		return
	is_invincible = true
	invincibility_timer.start(invincibility_duration)

func _on_invincibility_timer_timeout():
	if not is_dead:
		is_invincible = false
		print("Boss não está mais invencível")

func flash_effect():
	if is_dead:
		return
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(anim, "modulate", Color.RED, 0.05)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.05)

func die_state(_delta):
	velocity = Vector2.ZERO

func go_to_walk_state():
	if status == BossState.die or is_dead:
		return
	status = BossState.walk
	anim.play("walk_boss")
	can_attack = true
	hitbox.process_mode = Node.PROCESS_MODE_INHERIT
	
func go_to_attack_state():
	if not can_attack or status == BossState.die or is_dead:
		return
	can_attack = false
	status = BossState.attack
	anim.play("attack_boss")
	velocity = Vector2.ZERO
	# Após o ataque, volta para idle
	await get_tree().create_timer(0.5).timeout
	if status == BossState.attack and not is_dead:
		go_to_idle_state()
	
func go_to_hurt_state():
	if status == BossState.die or is_dead:
		return
	
	status = BossState.hurt
	anim.play("hurt_boss")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	
	await get_tree().create_timer(0.3).timeout
	
	if status == BossState.hurt and current_health > 0 and not is_dead:
		go_to_walk_state()
	
func go_to_idle_state():
	if status == BossState.die or is_dead:
		return
	status = BossState.idle
	velocity.x = 0
	anim.play("walk_boss")
	await get_tree().create_timer(0.5).timeout
	if status == BossState.idle and not is_dead:
		go_to_walk_state()
	
func idle_state(_delta):
	velocity.x = 0
	
func walk_state(_delta):
	if is_invincible or status == BossState.die or is_dead:
		return
	
	if player == null:
		player = get_player_in_range()
	
	if player != null:
		var direction_to_player = sign(player.global_position.x - global_position.x)
		
		if direction_to_player != 0 and direction_to_player != last_direction:
			last_direction = direction_to_player
			direction = direction_to_player
			atualizar_sprite_direction()
		
		velocity.x = SPEED * direction
		
		var distance_to_player = abs(player.global_position.x - global_position.x)
		if distance_to_player <= ATTACK_RANGE and can_attack:
			go_to_attack_state()
			return
	else:
		last_direction = 0
		
		if anim.frame == 3 or anim.frame == 4:
			velocity.x = SPEED * direction
		else:
			velocity.x = 0
		
		if wall_detector.is_colliding():
			direction *= -1
			atualizar_sprite_direction()
			last_direction = direction
		
		if not ground_detector.is_colliding():
			direction *= -1
			atualizar_sprite_direction()
			last_direction = direction

func get_player_in_range():
	if player_detector.is_colliding():
		var collider = player_detector.get_collider()
		if collider and collider.is_in_group("Player"):
			return collider
	return null

func atualizar_sprite_direction():
	if scale.x != direction:
		scale.x = direction

func attack_state(_delta):
	# Estado de ataque - apenas aguarda a animação terminar
	pass

func hurt_state(_delta):
	velocity.x = 0

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_dead:
		return
		
	match anim.animation:
		"attack_boss":
			# Ataque terminou, já vai para idle pelo timer no go_to_attack_state
			pass
		"hurt_boss":
			if current_health > 0 and status == BossState.hurt:
				go_to_walk_state()

func _on_hitbox_area_entered(area: Area2D):
	if is_dead:
		return
		
	print("Area entrou no hitbox do boss: ", area.name)
	print("Grupos da area: ", area.get_groups())
	
	# Verificação mais robusta para o hitbox de ataque
	if area.name == "AttackHitbox" or "AttackHitbox" in area.get_groups():
		print("ATAQUE DO PLAYER DETECTADO!")
		
		# Tentar obter dano de diferentes formas
		var attack_damage = attack_damage_default  # Usar valor padrão
		
		# Verificar se o parent tem o método
		if area.get_parent() and area.get_parent().has_method("get_attack_damage"):
			attack_damage = area.get_parent().get_attack_damage()
		# Verificar se a própria área tem o método
		elif area.has_method("get_attack_damage"):
			attack_damage = area.get_attack_damage()
		# Verificar se tem uma variável damage
		elif area.has_method("get") and area.get("damage"):
			attack_damage = area.damage
		
		print("Aplicando dano: ", attack_damage)
		take_damage(attack_damage)
		return
	
	# Restante do código para dano de contato...
	var parent = area.get_parent()
	if (parent and parent.is_in_group("Player")) or (area.is_in_group("Player")):
		print("Player encostou no boss!")
		if parent.has_method("take_damage"):
			parent.take_damage(damage)
		elif area.has_method("take_damage"):
			area.take_damage(damage)
func _on_hitbox_body_entered(body: Node2D):
	if is_dead:
		return
		
	print("Corpo entrou no hitbox do boss: ", body.name)
	
	if body.is_in_group("Player") and body.has_method("take_damage"):
		print("PLAYER tocou no boss!")
		body.take_damage(damage)
