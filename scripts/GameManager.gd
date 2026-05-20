extends Node

# ===== PERSISTÊNCIA GLOBAL =====
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_player_health()
	
	player_died.connect(_on_player_died)
	boss_defeated.connect(_on_boss_defeated)

# ===== DADOS DO PLAYER =====
# Sistema de luz (apenas iluminação)
var luz_coletada: bool = false
var intensidade_luz: float = 1.0
var raio_luz: float = 200.0
var cor_luz: Color = Color(1, 1, 0.8)  # Amarelo suave

# Sistema da faca (destrói ervas)
var tem_faca: bool = false
var faca_cooldown: float = 0.0
var faca_cooldown_max: float = 0.5  # 0.5 segundos entre cada corte
var faca_alcance: float = 60.0  # Alcance do corte em pixels

# Modo combinado (faca + luz) - os dois funcionam juntos
var modo_combinado_ativo: bool = false
var intensidade_combinada: float = 1.8   # Luz mais forte
var raio_combinado: float = 350.0        # Raio maior
var cor_combinada: Color = Color(1, 0.8, 0.4)  # Amarelo mais intenso

# Sistema de vida
var player_max_health: int = 100
var player_current_health: int = 100
var player_is_alive: bool = true

# Checkpoints
var current_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_reached: bool = false

# Referência ao player (será atribuída quando o player entrar na cena)
var player_reference: Node2D = null

# ===== SINAIS =====
signal player_damaged(current_health, max_health)
signal player_healed(current_health, max_health)
signal player_died()
signal player_respawned()
signal player_health_changed(current_health, max_health)
signal boss_defeated
signal boss_spawned(boss_node)
signal metodo_combinado_ativado()      # Quando ativa o modo combinado
signal luz_estado_atualizado(coletada: bool, intensidade: float, raio: float, cor: Color)
signal faca_estado_atualizado(tem_faca: bool)
signal faca_usada(posicao: Vector2, alcance: float, direcao: Vector2)  # Sinal quando a faca é usada
signal erva_cortada(posicao: Vector2)  # Sinal quando uma erva é cortada

# Adicione estas funções ao seu GameManager.gd se ainda não tem
var ultima_mensagem: String = ""
var historico_mensagens: Array = []

func guardar_mensagem_ui(mensagem: String):
	ultima_mensagem = mensagem
	historico_mensagens.append(mensagem)
	if historico_mensagens.size() > 20:
		historico_mensagens.pop_front()

func get_ultima_mensagem() -> String:
	if ultima_mensagem == "":
		return "🎮 Jogo iniciado! Pressione Q para atacar!"
	return ultima_mensagem

func _process(delta):
	# Atualiza cooldown da faca
	if faca_cooldown > 0:
		faca_cooldown -= delta
		faca_cooldown = max(0, faca_cooldown)

func register_boss(boss_node: Node):
	boss_spawned.emit(boss_node)
	print("Boss registrado no GameManager")

func _on_boss_defeated():
	print("Boss foi derrotado!")

func resetar_jogo():
	"""Reseta todo o estado do jogo"""
	luz_coletada = false
	intensidade_luz = 1.0
	raio_luz = 200.0
	tem_faca = false
	modo_combinado_ativo = false
	faca_cooldown = 0.0
	print("Jogo resetado!")
	emitir_sinal_luz()
	emitir_sinal_faca()

# ===== SISTEMA DA LUZ (APENAS ILUMINA) =====

func coletar_luz():
	"""Coleta a luz - serve apenas para iluminar o ambiente"""
	if luz_coletada:
		print("Luz já foi coletada!")
		return
	
	luz_coletada = true
	verificar_modo_combinado()
	emitir_sinal_luz()
	print("✨ LUZ COLETADA! Agora o ambiente está mais iluminado. ✨")
	print("Intensidade: ", get_intensidade_luz(), " | Raio: ", get_raio_luz())

func get_intensidade_luz() -> float:
	"""Retorna a intensidade atual da luz"""
	if modo_combinado_ativo:
		return intensidade_combinada
	return intensidade_luz

func get_raio_luz() -> float:
	"""Retorna o raio atual da luz"""
	if modo_combinado_ativo:
		return raio_combinado
	return raio_luz

func get_cor_luz() -> Color:
	"""Retorna a cor atual da luz"""
	if modo_combinado_ativo:
		return cor_combinada
	return cor_luz

func get_luz_coletada() -> bool:
	"""Retorna se a luz foi coletada"""
	return luz_coletada

# ===== SISTEMA DA FACA (DESTROI ERVAS) =====

func coletar_faca():
	"""Coleta a faca - serve para destruir ervas"""
	if tem_faca:
		print("Faca já foi coletada!")
		return
	
	tem_faca = true
	verificar_modo_combinado()
	emitir_sinal_faca()
	print("🗡️ FACA COLETADA! Agora você pode destruir ervas. 🗡️")

func get_tem_faca() -> bool:
	"""Retorna se o jogador tem a faca"""
	return tem_faca

func pode_destruir_erva() -> bool:
	"""Verifica se o jogador pode destruir ervas (precisa da faca)"""
	return tem_faca

func pode_usar_faca() -> bool:
	"""Verifica se o jogador pode usar a faca (tem faca e não está em cooldown)"""
	return tem_faca and faca_cooldown <= 0

func get_faca_cooldown() -> float:
	"""Retorna o tempo restante do cooldown da faca"""
	return faca_cooldown

func usar_faca(posicao_player: Vector2, direcao: Vector2 = Vector2.RIGHT) -> bool:
	"""
	Usa a faca para cortar ervas no chão
	Parâmetros:
	- posicao_player: posição atual do player
	- direcao: direção do corte (padrão: direita)
	
	Retorna true se conseguiu usar a faca
	"""
	if not tem_faca:
		print("❌ Você não tem uma faca para cortar ervas!")
		return false
	
	if faca_cooldown > 0:
		print("⏳ Faca em cooldown! Aguarde ", round(faca_cooldown), " segundos.")
		return false
	
	# Aplica cooldown
	faca_cooldown = faca_cooldown_max
	
	# Calcula a posição de corte
	var posicao_corte = posicao_player + (direcao * 40.0)
	
	# Emite sinal de que a faca foi usada
	faca_usada.emit(posicao_corte, faca_alcance, direcao)
	
	print("🗡️ Faca usada! Cortando ervas em alcance de ", faca_alcance, " pixels...")
	
	return true

func cortar_erva(erva_node: Node, posicao_erva: Vector2) -> bool:
	"""
	Corta uma erva específica
	Retorna true se conseguiu cortar
	"""
	if not tem_faca:
		return false
	
	if erva_node and is_instance_valid(erva_node):
		erva_node.queue_free()
		erva_cortada.emit(posicao_erva)
		print("🌿 Erva cortada pela faca! 🌿")
		return true
	
	return false

func criar_area_corte(player_node: Node2D, direcao: Vector2 = Vector2.RIGHT) -> Area2D:
	"""
	Cria uma área de corte temporária para detectar ervas
	Parâmetros:
	- player_node: referência ao nó do player
	- direcao: direção do corte (Vector2.RIGHT ou Vector2.LEFT)
	
	Retorna a Area2D criada
	"""
	if not player_node:
		print("❌ Erro: Referência do player não fornecida!")
		return null
	
	# Cria a área de corte
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Configura a forma do corte (largura 70, altura 50)
	shape.size = Vector2(70, 50)
	collision.shape = shape
	
	# Adiciona o collision shape à área
	area.add_child(collision)
	
	# Configura layers e masks
	area.collision_layer = 0
	area.collision_mask = 2  # Máscara para ervas (configure conforme seu jogo)
	
	# Adiciona a área como filha do player
	player_node.add_child(area)
	
	# Posiciona na direção do player
	var offset = direcao * 45
	area.position = offset
	
	# Define um nome para identificar
	area.name = "FacaAtaqueArea"
	
	# Adiciona metadados
	area.set_meta("type", "faca_ataque")
	area.set_meta("duration", 0.2)
	
	# Conecta o sinal de detecção
	area.area_entered.connect(_on_faca_area_entered.bind(area))
	
	# Agenda a remoção da área após 0.2 segundos
	_remover_area_apos_tempo(area, 0.2)
	
	print("🗡️ Área de corte criada na direção: ", direcao)
	
	return area

func _on_faca_area_entered(area: Area2D, faca_area: Area2D):
	"""Callback quando a área da faca detecta uma área"""
	# Verifica se a área detectada está no grupo "ervas"
	if area.is_in_group("ervas"):
		cortar_erva(area, area.global_position)

func _remover_area_apos_tempo(area: Area2D, tempo: float):
	"""Remove a área após um determinado tempo"""
	await get_tree().create_timer(tempo).timeout
	if area and is_instance_valid(area):
		area.queue_free()
		print("🗡️ Área de corte removida")

# ===== SISTEMA COMBINADO (LUZ + FACA JUNTOS) =====

func verificar_modo_combinado():
	"""Verifica se tem os dois itens para ativar o modo combinado"""
	if luz_coletada and tem_faca and not modo_combinado_ativo:
		ativar_modo_combinado()
	elif (not luz_coletada or not tem_faca) and modo_combinado_ativo:
		desativar_modo_combinado()

func ativar_modo_combinado():
	"""Ativa o modo combinado - luz mais forte E faca disponível"""
	modo_combinado_ativo = true
	metodo_combinado_ativado.emit()
	emitir_sinal_luz()
	print("⚔️✨ MODO COMBINADO ATIVADO! ✨⚔️")
	print("→ Luz mais intensa e com maior alcance!")
	print("→ Faca disponível para destruir ervas!")
	print("Intensidade: ", intensidade_combinada, " | Raio: ", raio_combinado)

func desativar_modo_combinado():
	"""Desativa o modo combinado, volta para o modo individual"""
	if modo_combinado_ativo:
		modo_combinado_ativo = false
		emitir_sinal_luz()
		print("Modo combinado desativado.")

func emitir_sinal_luz():
	"""Emite sinal com o estado atual da luz"""
	luz_estado_atualizado.emit(
		luz_coletada,
		get_intensidade_luz(),
		get_raio_luz(),
		get_cor_luz()
	)

func emitir_sinal_faca():
	"""Emite sinal com o estado atual da faca"""
	faca_estado_atualizado.emit(tem_faca)

# ===== SISTEMA DE VIDA =====

func reset_player_health():
	player_current_health = player_max_health
	player_is_alive = true
	player_health_changed.emit(player_current_health, player_max_health)
	print("Vida resetada: ", player_current_health, "/", player_max_health)

func damage_player(amount: int) -> bool:
	if not player_is_alive:
		return false
	
	player_current_health -= amount
	player_current_health = max(0, player_current_health)
	
	print("💔 Dano: ", amount, " | Vida: ", player_current_health, "/", player_max_health)
	
	player_damaged.emit(player_current_health, player_max_health)
	player_health_changed.emit(player_current_health, player_max_health)
	
	if player_current_health <= 0:
		player_died.emit()
		player_is_alive = false
		return true
	
	return false

func heal_player(amount: int):
	if not player_is_alive:
		return
	
	player_current_health += amount
	player_current_health = min(player_current_health, player_max_health)
	
	print("💚 Cura: ", amount, " | Vida: ", player_current_health, "/", player_max_health)
	
	player_healed.emit(player_current_health, player_max_health)
	player_health_changed.emit(player_current_health, player_max_health)

func set_player_health(amount: int):
	player_current_health = clamp(amount, 0, player_max_health)
	player_health_changed.emit(player_current_health, player_max_health)
	
	if player_current_health <= 0:
		player_died.emit()
		player_is_alive = false

func set_max_health(amount: int):
	player_max_health = amount
	player_current_health = min(player_current_health, player_max_health)
	player_health_changed.emit(player_current_health, player_max_health)

# ===== SISTEMA DE CHECKPOINTS =====

func set_checkpoint(position: Vector2):
	current_checkpoint = position
	checkpoint_reached = true
	print("📍 Checkpoint salvo em: ", position)

func respawn_player() -> Vector2:
	if not checkpoint_reached:
		current_checkpoint = Vector2(0, 0)
	
	reset_player_health()
	player_respawned.emit()
	print("🔄 Player respawnado no checkpoint: ", current_checkpoint)
	return current_checkpoint

func _on_player_died():
	print("💀 Player morreu! Respawnando em 2 segundos...")
	await get_tree().create_timer(2.0).timeout
	respawn_player()

func get_enemy_damage() -> int:
	return 10

func get_checkpoint() -> Vector2:
	return current_checkpoint

func is_checkpoint_reached() -> bool:
	return checkpoint_reached

# ===== FUNÇÃO AUXILIAR PARA REGISTRAR PLAYER =====

func registrar_player(player: Node2D):
	"""Registra a referência do player no GameManager"""
	player_reference = player
	print("✅ Player registrado no GameManager")
