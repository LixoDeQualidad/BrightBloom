extends Label

func _ready() -> void:
	text = "Resíduos: 0"
	GameManager.item_collected.connect(_on_item_collected)

func _on_item_collected(total: int) -> void:
	text = "Resíduos: %d" % total
