extends HBoxContainer

var id: int ## アイテムID

func _ready() -> void:
	if id == 0:
		queue_free()
		return
	var item: Item = Global.item_data[id] ## アイテム
	$Control/texture.texture_normal = item.image
	$name.text = item.name
	$level.text = "Lv.%d" % Global.save_data.item[id]
	
