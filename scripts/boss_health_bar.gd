extends Control

@onready var health_progress_bar: ProgressBar = $BossHealthProgressBar
@onready var health_label: Label = $BossHealthProgressBar/BossHealthLabel

var current_health: int = 0
var max_health: int = 0
var boss_node: Node = null
var flash_tween: Tween = null
var is_critical_flashing: bool = false

func _ready():
	print("=== BOSS HEALTH BAR INICIANDO ===")
	
	# Esconde a barra até o boss aparecer
	visible = false
	
	# Configura a barra
	if health_progress_bar:
		health_progress_bar.min_value = 0
		health_progress_bar.value = 0
	
	await get_tree().process_frame
	
	# SOLUÇÃO: Verificar se o boss já existe na cena
	var possible_boss = get_tree().get_first_node_in_group("Enemies")
	if possible_boss and possible_boss.has_signal("health_changed"):
		print("✅ Boss já existe na cena! Conectando...")
		_on_boss_spawned(possible_boss)
	
	# Conecta ao GameManager para futuros spawns
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.has_signal("boss_spawned"):
			# Desconectar anterior se existir para evitar duplicação
			if game_manager.boss_spawned.is_connected(_on_boss_spawned):
				game_manager.boss_spawned.disconnect(_on_boss_spawned)
			game_manager.boss_spawned.connect(_on_boss_spawned)
			print("✓ BossHealthBar conectada ao sinal boss_spawned")
		
		if game_manager.has_signal("boss_defeated"):
			if game_manager.boss_defeated.is_connected(_on_boss_defeated):
				game_manager.boss_defeated.disconnect(_on_boss_defeated)
			game_manager.boss_defeated.connect(_on_boss_defeated)
			print("✓ BossHealthBar conectada ao sinal boss_defeated")
	else:
		print("⚠️ GameManager não encontrado")

func _on_boss_spawned(boss: Node):
	print("🟢 Boss spawnado! Conectando barra...")
	_setup_boss(boss)

func _setup_boss(boss: Node):
	boss_node = boss
	
	# Conecta aos sinais do boss
	if boss.has_signal("health_changed"):
		# Evita conectar múltiplas vezes
		if boss.health_changed.is_connected(_on_boss_health_changed):
			boss.health_changed.disconnect(_on_boss_health_changed)
		boss.health_changed.connect(_on_boss_health_changed)
		print("✓ Conectado ao sinal health_changed do boss")
	
	# Mostra a barra
	visible = true
	
	# Atualiza com a vida atual do boss
	max_health = boss.max_health
	current_health = boss.current_health
	update_health_display()
	
	# Animação de entrada
	show_bar_animation()

func _on_boss_health_changed(current: int, new_max: int):
	print("📊 Atualizando barra do boss: ", current, "/", new_max)
	current_health = current
	max_health = new_max
	update_health_display()

func update_health_display():
	if health_progress_bar:
		health_progress_bar.max_value = max_health
		health_progress_bar.value = current_health
	
	
	update_bar_color()

func update_bar_color():
	if not health_progress_bar or not boss_node or boss_node.is_queued_for_deletion():
		return
	
	var percent = float(current_health) / float(max_health) if max_health > 0 else 0
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(5)
	
	if percent > 0.6:
		style.bg_color = Color(0.8, 0.2, 0.2)
		stop_critical_flash()
	elif percent > 0.3:
		style.bg_color = Color(0.9, 0.5, 0.1)
		stop_critical_flash()
	elif percent > 0.1:
		style.bg_color = Color(0.9, 0.7, 0.1)
		stop_critical_flash()
	else:
		style.bg_color = Color(1.0, 0.1, 0.1)
		start_critical_flash()
	
	health_progress_bar.add_theme_stylebox_override("fill", style)

func start_critical_flash():
	if is_critical_flashing:
		return
	
	is_critical_flashing = true
	
	flash_tween = create_tween()
	flash_tween.set_loops()
	flash_tween.tween_property(health_progress_bar, "modulate", Color.RED, 0.2)
	flash_tween.tween_property(health_progress_bar, "modulate", Color.WHITE, 0.2)

func stop_critical_flash():
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		flash_tween = null
	is_critical_flashing = false
	health_progress_bar.modulate = Color.WHITE

func show_bar_animation():
	modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)

func hide_bar_animation():
	stop_critical_flash()
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	visible = false

func _on_boss_defeated():
	print("🏆 Boss derrotado! Escondendo barra...")
	await hide_bar_animation()
	boss_node = null

func damage_flash():
	var tween = create_tween()
	tween.tween_property(health_progress_bar, "modulate", Color.WHITE, 0.05)
	tween.tween_property(health_progress_bar, "modulate", Color.RED, 0.1)
	tween.tween_property(health_progress_bar, "modulate", Color.WHITE, 0.3)

func on_boss_damaged():
	damage_flash()
