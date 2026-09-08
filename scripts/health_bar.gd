extends Control

# Referências aos nós da UI
@onready var health_progress_bar: ProgressBar = $HealthProgressBar
@onready var health_label: Label = $HealthProgressBar/HealthLabel

func _ready():
	print("=== HEALTHBAR INICIANDO ===")
	
	# Verifica se encontrou os nós
	if not health_progress_bar:
		print("❌ ERRO: ProgressBar não encontrado! Verifique a estrutura da cena.")
		return
	
	if not health_label:
		print("❌ ERRO: Label não encontrado!")
		return
	
	print("✓ ProgressBar e Label encontrados!")
	
	# Configura a barra
	health_progress_bar.min_value = 0
	health_progress_bar.max_value = 100
	health_progress_bar.value = 100
	
	# Conecta ao GameManager
	await get_tree().process_frame
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		print("✓ GameManager encontrado!")
		
		# Conecta ao sinal
		if game_manager.has_signal("player_health_changed"):
			game_manager.player_health_changed.connect(_on_health_updated)
			print("✓ Conectado ao sinal player_health_changed!")
			
			# Atualiza imediatamente
			_on_health_updated(game_manager.player_current_health, game_manager.player_max_health)
		else:
			print("❌ GameManager não tem o sinal player_health_changed!")
	else:
		print("❌ GameManager não encontrado em /root/GameManager")

func _on_health_updated(current: int, max: int):
	print("📊 Atualizando barra: ", current, "/", max)
	
	if health_progress_bar:
		health_progress_bar.max_value = max
		health_progress_bar.value = current
	
	if health_label:
		health_label.text = "%d / %d" % [current, max]
	
	# Efeito visual ao tomar dano
	if current < health_progress_bar.value:
		var tween = create_tween()
		tween.tween_property(health_progress_bar, "modulate", Color.RED, 0.1)
		tween.tween_property(health_progress_bar, "modulate", Color.WHITE, 0.3)
