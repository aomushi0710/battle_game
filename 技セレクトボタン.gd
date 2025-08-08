extends Button

@onready var texture = $TextureRect
var action: Action
var i: int = 0
var texture_mode: Mode ## 表示される時の形態
enum Mode { ## フォントサイズによるアイコンのズレを補正するモード切り替え
	SELECT, ## 技セレクト時
	BATTLE  ## バトル時
}

func _ready() -> void:
	if texture_mode == Mode.SELECT:
		texture.position = Vector2(2.5, 2.5)
		texture.scale = Vector2(0.1, 0.1)
	elif texture_mode == Mode.BATTLE:
		texture.position = Vector2(4, 4)
		texture.scale = Vector2(0.105, 0.105)
	texture.texture = action.element[i].icon
	self.text = action.name
	
	if len(action.element) == 1: # 属性が1つだけ
		texture.queue_free()
		self.icon = action.element[i].icon
	else:
		self.icon = load("res://null.PNG")
		blink()


func blink() -> void:
	var tween = get_tree().create_tween().bind_node(texture)
	tween.set_loops() # 以下をループ
	tween.tween_property(texture, "modulate:a", 0, 1)
	tween.tween_callback(Callable(self, "change"))
	tween.tween_property(texture, "modulate:a", 1, 1)


func change() -> void:
	i += 1
	if i >= len(action.element): # 無効なindexを取らないように初期化
		i = 0
	texture.texture = action.element[i].icon
