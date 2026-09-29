# NotificacaoUI.gd
extends CanvasLayer
@export var smooth_speed: float = 0.25  # duração da animação da barra (segundos)
 
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var labelvida: Label = $ProgressBar/Label
 
var _tween: Tween
 

@onready var label: Label = $LabelNotificacao

var tempo_exibicao := 2.0
var tween: Tween

func _ready() -> void:
	label.modulate.a = 0.0  # começa invisível
	GameManager.item_adicionado.connect(_on_item_adicionado)
	progress_bar.max_value = PlayerStats.max_health
	progress_bar.value = PlayerStats.current_health
	_update_label(PlayerStats.current_health, PlayerStats.max_health)
 
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.player_died.connect(_on_player_died)
 

func _on_item_adicionado(nome_item: String) -> void:
	var texto = GameManager.mensagens_item.get(nome_item, "%s desbloqueada!" % nome_item.capitalize())
	mostrar_notificacao(texto)

func mostrar_notificacao(texto: String) -> void:
	label.text = texto

	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)      # fade in
	tween.tween_interval(tempo_exibicao)                      # fica visível
	tween.tween_property(label, "modulate:a", 0.0, 0.5)      # fade out

func _on_health_changed(current_health: int, max_health: int) -> void:
	progress_bar.max_value = max_health
	_update_label(current_health, max_health)
 
	# Anima suavemente até o novo valor em vez de "pular"
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(progress_bar, "value", current_health, smooth_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 
 
func _on_player_died() -> void:
	# Opcional: efeito visual quando a vida zera (piscar, escurecer, etc.)
	if _tween:
		_tween.kill()
	progress_bar.value = 0
 
 
func _update_label(current_health: int, max_health: int) -> void:
	if labelvida:
		labelvida.text = "%d / %d" % [current_health, max_health]
		
