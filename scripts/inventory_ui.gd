extends Control

## Anexe este script a um Control dentro de um CanvasLayer.
## Estrutura esperada da cena:
## CanvasLayer
##  └── InventoryUI (Control, este script)
##       └── HBoxContainer

@export var icon_size: Vector2 = Vector2(48, 48)
@export var spacing: int = 1

# Mapeia o nome do item (o mesmo texto usado em GameManager.adicionar_item)
# para a textura do ícone. Ajuste os caminhos para os seus arquivos.
var icones_itens := {
	"faca": preload("res://sprites/Sprites/Itens/faca.png"),
	"duble_jump": preload("res://sprites/Sprites/Itens/lapiao.png"),
	"brilho": preload("res://sprites/Sprites/Itens/lapiao.png"),
	"chave":preload("res://sprites/Sprites/Itens/chave.png")
}

@onready var container: HBoxContainer = $HBoxContainer

var icones_ativos: Dictionary = {}

func _ready() -> void:
	# Fixa a UI no canto superior esquerdo da tela, com 16px de margem
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE, 10)

	container.add_theme_constant_override("separation", spacing)

	GameManager.item_adicionado.connect(_on_item_adicionado)
	GameManager.item_removido.connect(_on_item_removido)

	# Caso o jogador entre nessa cena já com itens no inventário
	_reconstruir_do_inventario_atual()


func _reconstruir_do_inventario_atual() -> void:
	for nome_item in icones_ativos.keys():
		icones_ativos[nome_item].queue_free()
	icones_ativos.clear()

	for nome_item in GameManager.inventario:
		_adicionar_icone(nome_item)


func _on_item_adicionado(nome_item: String) -> void:
	_adicionar_icone(nome_item)


func _on_item_removido(nome_item: String) -> void:
	_remover_icone(nome_item)


func _adicionar_icone(nome_item: String) -> void:
	if icones_ativos.has(nome_item):
		return

	var rect := TextureRect.new()
	rect.custom_minimum_size = icon_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.tooltip_text = nome_item.capitalize()

	var textura: Texture2D = icones_itens.get(nome_item, null)
	if textura:
		rect.texture = textura
	else:
		# Fallback: se não houver ícone cadastrado, mostra a inicial do item
		var label := Label.new()
		label.text = nome_item.substr(0, 1).to_upper()
		label.custom_minimum_size = icon_size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rect.add_child(label)

	container.add_child(rect)
	icones_ativos[nome_item] = rect


func _remover_icone(nome_item: String) -> void:
	if icones_ativos.has(nome_item):
		icones_ativos[nome_item].queue_free()
		icones_ativos.erase(nome_item)
