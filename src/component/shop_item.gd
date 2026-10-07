extends VBoxContainer

signal button_up(item) ## ボタンが押された時に、アイテム情報を送るシグナル

var item
var level: int
var price: int

@onready var texture_button := %TextureButton as TextureButton
@onready var price_label := %Price as RichTextLabel

func _ready() -> void:
	name = item.name
	texture_button.texture_normal = item.image
	texture_button.button_up.connect(func(): button_up.emit(self)) # 押されたらシグナル発火

## 販売アイテムのレベルと値段を算出し直す関数
func update() -> void:
	level = item.get_level() + 1 # 所持しているレベルの1つ上で売られる
	if level <= item.max_level: # 最大レベルに到達していなければ
		price = item.get_price(level)
		price_label.text = "[img=50]res://asset/image/coin.PNG[/img] " + \
		"[color=gold]%d[/color]" % price
	else:
		price_label.text = "[color=red]売り切れ[/color]"
