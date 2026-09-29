extends Area2D

# ID único: usa o caminho da cena + posição do nó, para identificar essa instância específica
var coin_id: String
@onready var Som= $AudioStreamPlayer2D


func _ready() -> void:
	coin_id = get_tree().current_scene.scene_file_path + "_" + str(get_path())

	if GameManager.is_coin_collected(coin_id):
		queue_free()
		return

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameManager.collect_item()
		GameManager.mark_item_collected(coin_id)
		
		hide()
		Som.reparent(get_tree().current_scene)
		Som.play()
		Som.finished.connect(Som.queue_free)
		queue_free()
