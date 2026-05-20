extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	wall,
	swimming,
	hurt,
	attack  # Estado de ataque
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector

@onready var reload_timer: Timer = $ReloadTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer  # Timer para invencibilidade
@export var invincibility_duration: float = 1.5  # Duração da invencibilidade após ser atingido
var is_invincible: bool = false

@export var max_speed = 180.0
@export var acceleration = 400
@export var deceleration = 400
@export var slide_deceleration = 100
@export var water_max_speed = 100
@export var water_acceleration = 200
@export var water_jump_force = -100
var has_double_jump_item: bool = false
@onready var light: PointLight2D = $PointLight2D
@onready var luz_player:PointLight2D = $PointLight2D
var met_sys_ready := false
var velocidade = 150
var tem_faca = false
var pode_atacar = true  # Renomeado de pode_cortar para pode_atacar
@onready var faca_area = $FacaArea
@onready var luz_fundo: PointLight2D = $PointLightFundo
@onready var ray_cast = $RayCast2D
@onready var ray_cast2 =$RayCast2D2

# Timer para cooldown do ataque
@onready var attack_cooldown: Timer = $AttackCooldown
@export var attack_duration: float = 0.3  # Duração da animação de ataque
@export var attack_damage: int = 20  # Dano do ataque
@export var attack_range: float = 100.0  # Alcance do ataque

signal health_updated(current_health, max_health)

const JUMP_VELOCITY = -300.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState

func _ready():
	go_to_idle_state()
	light.enabled = false
	
	# Configurar o timer de cooldown se não existir
	if not attack_cooldown:
		attack_cooldown = Timer.new()
		attack_cooldown.one_shot = true
		add_child(attack_cooldown)
	
	if GameManager.luz_coletada:
		ativar_luz()
	else:
		luz_player.enabled = false
	GameManager.player_respawned.connect(_on_game_manager_respawned)
	GameManager.player_health_changed.connect(_on_player_health_changed)

	health_updated.emit(GameManager.player_current_health, GameManager.player_max_health)



	
func _on_player_health_changed(current, max):
	health_updated.emit(current, max)

func ativar_luz():
	luz_player.enabled = true
	luz_player.energy = GameManager.intensidade_luz
	luz_player.texture_scale = GameManager.raio_luz
	luz_fundo.enabled = true 
	print("Luz ativada! Coletada em alguma fase: ", GameManager.luz_coletada)
	ray_cast.target_position = Vector2(50, 0)
	ray_cast.collision_mask = 2

func coletar_luz():
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.coletar_luz()
		print("✨ Luz coletada e registrada no GameManager!")

func _process(_delta):
	if luz_fundo:
		luz_fundo.global_position = global_position
	
	# Detectar tecla Q para ataque (sempre disponível)
	if Input.is_action_just_pressed("attack") and pode_atacar and status != PlayerState.attack:
		start_attack()

func _physics_process(delta: float) -> void:
	# Não processar movimento durante o ataque
	if status != PlayerState.attack:
		match status:
			PlayerState.idle:
				idle_state(delta)
			PlayerState.walk:
				walk_state(delta)
			PlayerState.jump:
				jump_state(delta)
			PlayerState.fall:
				fall_state(delta)
			PlayerState.duck:
				duck_state(delta)
			PlayerState.slide:
				slide_state(delta)
			PlayerState.swimming:
				swimming_state(delta)
			PlayerState.hurt:
				hurt_state(delta)
			PlayerState.attack:
				attack_state(delta)
		
	move_and_slide()

# Função para iniciar o ataque
func start_attack():
	if not pode_atacar:
		return
	
	pode_atacar = false
	status = PlayerState.attack
	
	# Tocar animação de ataque
	if anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		# Aguardar a animação terminar completamente
		await anim.animation_finished
	else:
		# Se não tiver animação, espera o tempo padrão
		print("Aviso: Animação 'attack' não encontrada!")
		await get_tree().create_timer(attack_duration).timeout
	
	# Executar o ataque (pode ser antes ou depois da animação)
	perform_attack()
	
	# Voltar ao estado apropriado
	pode_atacar = true
	
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
	else:
		if velocity.y < 0:
			go_to_jump_state()
		else:
			go_to_fall_state()

# Função que executa o ataque propriamente dito
# No método perform_attack() - você já tem isso, está correto
func perform_attack():
	print("Ataque executado!")
	
	var attack_direction = -1 if anim.flip_h else 1
	
	var attack_hitbox = Area2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = Vector2(attack_range, 20)
	
	var collision_shape_2d = CollisionShape2D.new()
	collision_shape_2d.shape = rectangle_shape
	attack_hitbox.add_child(collision_shape_2d)
	
	var hitbox_position = Vector2(attack_range / 2 * attack_direction, 0)
	attack_hitbox.position = hitbox_position
	
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.add_to_group("AttackHitbox")  # IMPORTANTE
	
	attack_hitbox.collision_layer = 0
	attack_hitbox.collision_mask = 1  # Colide com inimigos
	
	# Conectar sinais
	attack_hitbox.area_entered.connect(_on_attack_hit_area)
	attack_hitbox.body_entered.connect(_on_attack_hit_body)
	
	add_child(attack_hitbox)
	
	await get_tree().create_timer(0.15).timeout
	attack_hitbox.queue_free()
	if ray_cast.is_colliding():
		var colisao = ray_cast.get_collider()
		print("RayCast acertou: ", colisao.name)
		apply_damage(colisao)
	
	ray_cast2.target_position = Vector2(attack_range * attack_direction, 20)
	ray_cast2.force_raycast_update()
	
	if ray_cast2.is_colliding():
		var colisao = ray_cast2.get_collider()
		print("RayCast2 acertou: ", colisao.name)
		apply_damage(colisao)

# Aplicar dano ao alvo
func apply_damage(target):
	print("Aplicando dano a: ", target.name)
	
	# Verificar se é o boss ou inimigo
	if target.is_in_group("Enemies"):
		if target.has_method("take_damage"):
			print("Chamando take_damage no alvo")
			target.take_damage(attack_damage)
		else:
			print("Alerta: Alvo não tem método take_damage!")
	
	# Verificar se é uma erva
	elif target.is_in_group("erva"):
		if target.has_method("cortar"):
			target.cortar()
		else:
			target.queue_free()
		print("Erva cortada!")
	
	# Verificar outros objetos destrutíveis
	elif target.is_in_group("Destructible"):
		if target.has_method("destroy"):
			target.destroy()
		else:
			target.queue_free()
		print("Objeto destrutível atingido!")
# Callbacks para o hitbox do ataque
func _on_attack_hit_area(area: Area2D):
	print("Hitbox de ataque colidiu com área: ", area.name)
	var parent = area.get_parent()
	
	# Se a área for do boss, aplicar dano diretamente
	if area.name == "Hitbox" or parent.is_in_group("Enemies"):
		apply_damage(parent)
	else:
		apply_damage(area)


func _on_attack_hit_body(body: Node2D):
	print("Hitbox de ataque colidiu com corpo: ", body.name)
	apply_damage(body)

# Estado de ataque (não se move)
func attack_state(delta):
	# Congela o movimento horizontal durante o ataque
	velocity.x = 0
	apply_gravity(delta)

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()
	
func exit_from_duck_state():
	set_large_collider()
	
func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()
	
func exit_from_slide_state():
	set_large_collider()
	
func go_to_swimming_state():
	status = PlayerState.swimming
	anim.play("swimming")
	velocity.y = min(velocity.y, 150)
	
func go_to_hurt_state():
	if status == PlayerState.hurt:
		return
	
	status = PlayerState.hurt
	anim.play("hurt")
	velocity.x = 0
	reload_timer.start()

func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return
	
func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
		
	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return
		
func jump_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if velocity.y > 0:
		go_to_fall_state()
		return
		
func fall_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
		
func duck_state(delta):
	apply_gravity(delta)
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return
		
func slide_state(delta):
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	
	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
		
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.x = direction
		go_to_jump_state()
		return
		
func swimming_state(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, water_max_speed * direction, water_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, water_acceleration * delta)
		
	velocity.y += water_acceleration * delta
	velocity.y = min(velocity.y, water_max_speed)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = water_jump_force
		
func take_damage(amount: int):
	if is_invincible or status == PlayerState.hurt:
		return  # Já está invencível ou já tomando dano
	
	# Aplica o dano via GameManager
	var died = GameManager.damage_player(amount)
	
	if died:
		# Player morreu
		die()
	else:
		# Player só tomou dano
		go_to_hurt_state()
		start_invincibility()

func die():
	print("Player morreu!")
	status = PlayerState.hurt
	anim.play("die")
	# Desativa colisões
	collision_shape.disabled = true
	hitbox_collision_shape.disabled = true
	# Para o movimento
	velocity = Vector2.ZERO
	# Aguarda respawn
	await get_tree().create_timer(1.0).timeout
	# Notifica o GameManager para respawn
	GameManager.respawn_player()
	# Recarrega a cena ou respawna
	get_tree().reload_current_scene()

func flash_effect():
	# Efeito de piscar
	var tween = create_tween()
	tween.set_loops(6)  # Pisca 6 vezes
	tween.tween_property(anim, "modulate", Color.TRANSPARENT, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)



func start_invincibility():
	is_invincible = true
	# Pisca o sprite para indicar invencibilidade
	flash_effect()
	invincibility_timer.start(invincibility_duration)

func hurt_state(delta):
	apply_gravity(delta)

func move(delta):
	update_direction()
	
	# VALIDAÇÃO: Garantir que direction é um número
	if direction == null:
		direction = 0.0
		print("Aviso: direction era null, resetado para 0")
	
	# Usar comparação explícita para evitar erro com null
	if direction != 0:
		var target_velocity = direction * max_speed
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func can_jump() -> bool:
	var max_allowed_jumps = 3 if has_double_jump_item else 2
	return jump_count < max_allowed_jumps

func set_small_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3
	
	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 3
	
func set_large_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0
	
	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 0.5

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_hurt_state()
	elif body.is_in_group("Water"):
		go_to_swimming_state()

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		go_to_hurt_state()
	
func hit_lethal_area():
	go_to_hurt_state()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Water"):
		jump_count = 0
		go_to_jump_state()



func collect_double_jump_item():
	has_double_jump_item = true
	print("Pulo duplo adquirido!")

# Mantido para compatibilidade com seu sistema de faca
# SUBSTITUA a função coletar_faca() existente por esta:
func coletar_faca():
	tem_faca = true
	
	# REGISTRA a faca no GameManager (isso vai emitir o sinal!)
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.coletar_faca()  # Isso vai chamar o sistema correto
		print("🗡️ Faca coletada e registrada no GameManager!")
	else:
		print("❌ GameManager não encontrado!")
func _on_game_manager_respawned():
	# Reseta posição
	global_position = GameManager.current_checkpoint
	# Reativa colisões
	collision_shape.disabled = false
	hitbox_collision_shape.disabled = false
	# Reseta invencibilidade
	is_invincible = false
	anim.modulate = Color.WHITE
	
func get_attack_damage() -> int:
	return attack_damage
