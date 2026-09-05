extends Node
@export var start_scene_path: String = "res://MapaCenas/Sala1.tscn" # ajuste pro caminho real
@export var spawn_point_name: String = "SpawnPoint_Default"


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	boss_defeated.connect(_on_boss_defeated)
	add_child(collect_sound_player)
	collect_sound_player.stream = collect_sound

# ===== SISTEMA DE LUZ =====
var luz_coletada: bool = false
var intensidade_luz: float = 1.0
var raio_luz: float = 200.0
var cor_luz: Color = Color(1, 1, 0.8)

# ===== SISTEMA DE VIDA =====
var player_max_health: int = 100
var player_current_health: int = 100
var player_is_alive: bool = true

# ===== CHECKPOINTS =====
var current_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_reached: bool = false

# ===== REFERÊNCIA AO PLAYER =====
var player_reference: Node2D = null

var collected_count: int = 0

# Mensagens de notificação por item
var mensagens_item := {
	"faca": "Você encontrou uma faca afiada!",
	"chave": "Uma chave brilhante... o que ela abre?",
	"brilho": "Você conseguiu um lampião brilhante!",
	"cura": "Me sinto muito melhor agora..."
}

# ===== SINAIS =====
signal player_damaged(current_health, max_health)
signal player_healed(current_health, max_health)
signal player_died()
signal player_respawned()
signal player_health_changed(current_health, max_health)
signal boss_defeated
signal boss_spawned(boss_node)
signal luz_estado_atualizado(coletada: bool, intensidade: float, raio: float, cor: Color)
signal upgrade_desbloqueado(nome_upgrade: String)
signal item_collected(total: int)
signal item_adicionado(nome_item: String)
signal item_removido(nome_item: String)

#SISTEMA DE COLETA DE COINS==================================================================================
signal coin_collected(item_type: String, total: int)
var collected_coin: Dictionary = {
	"coin_1": 0,
	"coin_2": 0
}
@onready var collect_sound_player = AudioStreamPlayer.new()
@export var collect_sound: AudioStream = preload("res://audio/efeito_5.mp3")

func collect_coin(item_type: String) -> void:
	if not collected_coin.has(item_type):
		collected_coin[item_type] = 0

	collected_coin[item_type] += 1
	coin_collected.emit(item_type, collected_coin[item_type])
	collect_sound_player.play()

func get_count(item_type: String) -> int:
	return collected_coin.get(item_type, 0)

func mark_item_collected(coin_id: String) -> void:
	collected_coin[coin_id] = true


func is_coin_collected(coin_id: String) -> bool:
	return collected_coin.has(coin_id)

#===========================================================================================================

# ===== SISTEMA DE INVENTÁRIO (a faca agora vive aqui) =====
var inventario: Array[String] = []

func adicionar_item(nome_item: String) -> void:
	if inventario.has(nome_item):
		return  # evita duplicar o mesmo item
	inventario.append(nome_item)
	item_adicionado.emit(nome_item)
	upgrade_desbloqueado.emit(nome_item.capitalize())
	print("Inventário: ", inventario)

func remover_item(nome_item: String) -> bool:
	if inventario.has(nome_item):
		inventario.erase(nome_item)
		item_removido.emit(nome_item)
		return true
	return false

func tem_item(nome_item: String) -> bool:
	return inventario.has(nome_item)


func collect_item() -> void:
	collected_count += 1
	item_collected.emit(collected_count)

func register_boss(boss_node: Node):
	boss_spawned.emit(boss_node)

func _on_boss_defeated():
	pass

func resetar_jogo():
	luz_coletada = false
	intensidade_luz = 1.0
	raio_luz = 200.0
	limpar_inventario()
	emitir_sinal_luz()

# ===== SISTEMA DA LUZ (mantido) =====

func coletar_luz():
	if luz_coletada:
		return
	luz_coletada = true
	emitir_sinal_luz()
	upgrade_desbloqueado.emit("Luz")

func get_intensidade_luz() -> float:
	return intensidade_luz

func get_raio_luz() -> float:
	return raio_luz

func get_cor_luz() -> Color:
	return cor_luz

func get_luz_coletada() -> bool:
	return luz_coletada

func emitir_sinal_luz():
	luz_estado_atualizado.emit(luz_coletada, get_intensidade_luz(), get_raio_luz(), get_cor_luz())

# ===== CHECKPOINTS =====

func set_checkpoint(position: Vector2):
	current_checkpoint = position
	checkpoint_reached = true


func limpar_inventario() -> void:
	var itens_copia = inventario.duplicate()
	for nome_item in itens_copia:
		inventario.erase(nome_item)
		item_removido.emit(nome_item)

func respawn_player() -> void:
	limpar_inventario()
	PlayerStats.reset_health()
	get_tree().change_scene_to_file(start_scene_path)
	await get_tree().process_frame
	_posicionar_player_no_spawn()

func _posicionar_player_no_spawn() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		push_warning("Nenhum node no grupo 'Player' encontrado após respawn.")
		return

	var spawn_point := get_tree().current_scene.find_child(spawn_point_name, true, false)
	if not spawn_point:
		push_warning("%s não encontrado na cena de spawn!" % spawn_point_name)
		return

	players[0].global_position = spawn_point.global_position
	players[0].velocity = Vector2.ZERO
