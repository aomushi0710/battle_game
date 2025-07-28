class_name ItemButton
extends TextureButton

var item: Item
signal item_button_up(item)

func _ready() -> void:
	texture_normal = item.image
	button_up.connect(func(): item_button_up.emit(item))
	
