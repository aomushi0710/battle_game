extends Button

@onready var texture = $TextureRect
var action: Action
var i: int = 0

func _ready() -> void:
	texture.texture = action.element[i].icon
	self.text = action.name
	
	if len(action.element) == 1: # 属性が1つだけ
		texture.queue_free()
		self.icon = action.element[i].icon
	else:
		self.icon = load("res://null.PNG")
		blink()


func blink() -> void:
	var tween = get_tree().create_tween()
	tween.set_loops() # 以下をループ
	tween.tween_property(texture, "modulate:a", 0, 1)
	tween.tween_callback(Callable(self, "change"))
	tween.tween_property(texture, "modulate:a", 1, 1)


func change() -> void:
	i += 1
	if i >= len(action.element): # 無効なindexを取らないように初期化
		i = 0
	texture.texture = action.element[i].icon
