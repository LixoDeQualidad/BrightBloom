extends Area2D

@export_enum("coin_1", "coin_2") var coin_type: String = "coin_1"

# ID único: usa o caminho da cena + posição do nó, para identificar essa instância específica
var coin_id: String

func _ready() -> void:
	coin_id = get_tree().current_scene.scene_file_path + "_" + str(get_path())
	
	if GameManager.is_coin_collected(coin_id):
		queue_free()
		return
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameManager.collect_coin(coin_type)
		GameManager.mark_item_collected(coin_id)
		queue_free()
