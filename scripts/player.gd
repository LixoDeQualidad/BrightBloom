extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	slide,
	swimming,
	hurt,
	attack,  # Estado de ataque
}


@onready var som_andar: AudioStreamPlayer2D = $SomAndar
@onready var som_pular: AudioStreamPlayer2D = $SomPular
@onready var som_ataque: AudioStreamPlayer2D = $SomAtaque
@onready var som_morrer: AudioStreamPlayer2D = $SomMorrer
@onready var som_dano: AudioStreamPlayer2D = $SomDano
@onready var footstep_timer: Timer = $FootstepTimer
@onready var som_pouso: AudioStreamPlayer2D = $SomPouso
var pode_mover := true


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $Hitbox

@onready var reload_timer: Timer = $ReloadTimer

@export var max_speed :float=180.0
@export var acceleration : float = 400.0
@export var deceleration : float= 400
@export var slide_deceleration = 100
@export var water_max_speed = 100
@export var water_acceleration = 200
@export var water_jump_force = -100
var has_double_jump_item: bool = false
@onready var light: PointLight2D = $PointLight2D
@onready var luz_player:PointLight2D = $PointLight2D
var met_sys_ready := false
var velocidade = 150

var na_tirolesa: bool = false

@onready var luz_fundo: PointLight2D = $PointLightFundo
@onready var ray_cast = $RayCast2D
@onready var ray_cast2 =$RayCast2D2


signal terminou_usar_item


const JUMP_VELOCITY = -300.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var usando_item := false

#-------------------------Ataque e vida-------------

@export var attack_damage: int = 20

@onready var attack_area: Area2D = $AttackArea
 
var can_act: bool = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and can_act and not PlayerStats.is_dead:
		attack()
 
 
func attack() -> void:
	can_act = false
	sprite.play("attack")
	som_ataque.play()
 
	await get_tree().create_timer(0.1).timeout  # tempo até o golpe "sair"
	attack_area.monitoring = true
	await get_tree().create_timer(0.15).timeout  # duração da hitbox ativa
	attack_area.monitoring = false
 
	await sprite.animation_finished
	can_act = true
 
 
func _on_attack_area_body_entered(body: Node) -> void:
	# Qualquer objeto destrutível deve estar no grupo "destructible"
	# e ter um método take_damage(amount: int)
	if body.is_in_group("destructible") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
 
	# Se quiser que o player também dê dano em inimigos, use um grupo "enemy"
	if body.is_in_group("Enemies") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
 
 
# Chame isso de onde o dano no player for detectado
# (ex: HurtBox.body_entered, inimigo atacando, hazard, etc.)
func take_damage(amount: int) -> void:
	PlayerStats.take_damage(amount)
	sprite.play("hurt")
 
 
func _on_player_damaged(_amount: int) -> void:
	if not PlayerStats.is_dead:
		sprite.play("hurt")
		som_dano.play()
 
func _on_player_died() -> void:
	can_act = false
	attack_area.monitoring = false
	sprite.play("die")
	som_morrer.play()
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)

	await som_morrer.finished
	GameManager.respawn_player()
 
 
func _on_health_changed(current: int, max_hp: int) -> void:
	# Atualize aqui sua UI de vida (barra, texto, etc.)
	pass
 


func tem_item(nome_item: String) -> bool:
	return GameManager.tem_item(nome_item)

func usar_faca() -> void:
	pode_mover = false
	$AnimatedSprite2D.play("faca") # nome da animação no player
	await $AnimatedSprite2D.animation_finished
	pode_mover = true



func _ready():
	go_to_idle_state()
	light.enabled = false

	if GameManager.luz_coletada:
		ativar_luz()
	# Conecta aos sinais do singleton PlayerStats (persistente entre cenas)
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.player_damaged.connect(_on_player_damaged)
	PlayerStats.player_died.connect(_on_player_died)
 
	for player in [som_andar, som_pular, som_ataque, som_morrer, som_dano,som_pouso]:
		player.bus = "SFX"

 
	# A área de ataque deve começar desligada; só ativa durante o "attack"
	attack_area.monitoring = false
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)

func _on_footstep_timer_timeout():
	if status == PlayerState.walk and is_on_floor():
		som_andar.play()



func ativar_luz():
	luz_player.enabled = true
	anim.play("luz")
	luz_player.energy = GameManager.intensidade_luz
	luz_player.texture_scale = GameManager.raio_luz
	luz_fundo.enabled = true 
	print("Luz ativada! Coletada em alguma fase: ", GameManager.luz_coletada)
	ray_cast.target_position = Vector2(50, 0)
	ray_cast.collision_mask = 2

func coletar_luz():
	var game_manager = get_node("/root/GameManager")
	anim.play("lampiao")
	if game_manager:
		game_manager.coletar_luz()
		print("✨ Luz coletada e registrada no GameManager!")

func tocar_animacao_luz() -> void:
	pode_mover = false
	velocity.x = 0
	anim.play("luz")
	await anim.animation_finished
	pode_mover = true
	# Volta pro estado correto dependendo se está no chão ou não
	if is_on_floor():
		go_to_idle_state()
	else:
		go_to_fall_state()

func _process(_delta):
	if luz_fundo:
		luz_fundo.global_position = global_position
	

func _physics_process(delta: float) -> void:
	if na_tirolesa:
		return  
	if not pode_mover:
		return
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
			PlayerState.slide:
				slide_state(delta)
			PlayerState.swimming:
				swimming_state(delta)
			PlayerState.hurt:
				hurt_state(delta)
			PlayerState.attack:
				attack_state(delta)
		
	move_and_slide()



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
	footstep_timer.start()

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x == 0:
		footstep_timer.stop()
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		footstep_timer.stop()
		go_to_jump_state()
		return


	if !is_on_floor():
		footstep_timer.stop()
		jump_count += 1
		go_to_fall_state()
		return

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	som_pular.play()
	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	


	
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
		som_pouso.play()
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
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
		


func flash_effect():
	# Efeito de piscar
	var tween = create_tween()
	tween.set_loops(6)  # Pisca 6 vezes
	tween.tween_property(anim, "modulate", Color.TRANSPARENT, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)

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
	

	
func set_large_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0
	

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


func entrar_na_tirolesa() -> void:
	na_tirolesa = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("tirolesa")
	# ou, se usar AnimatedSprite2D:
	# $AnimatedSprite2D.play("tirolesa")

func sair_da_tirolesa() -> void:
	na_tirolesa = false
	$AnimatedSprite2D.play("idle") # ou sua animação padrão


func collect_double_jump_item():
	has_double_jump_item = true
	print("Pulo duplo adquirido!")

func bounce() -> void:
	velocity.y = -300  # ajuste a força do pulo

func bounce2() -> void:
	velocity.y = -700

func tentar_entrar_na_sala(item_necessario: String = "brilho") -> bool:
	if not tem_item(item_necessario):
		pode_mover = false
		anim.play("no")
		await anim.animation_finished
		pode_mover = true
		return false
	return true
