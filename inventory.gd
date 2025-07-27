extends TabContainer

const ITEM_SCENE = preload("res://inventory_item.tscn")

func _ready() -> void:
	if Global.inv.item == {}:
		return
	var sorted_keys = Global.inv.item.keys()
	sorted_keys.sort()
	for key: int in sorted_keys:
		var item := ITEM_SCENE.instantiate()
		item.get_node("container").id = key
		$"アイテム".add_child(item)


func _on_close_button_up() -> void:
	get_parent().queue_free()
