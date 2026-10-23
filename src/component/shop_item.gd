extends VBoxContainer
class_name ShopItem
## ショップに販売されるアイテムのシーン

signal button_up(item_button: ShopItem) ## ボタンが押された時に、自身の情報を発行します

var item: Item
var level: int
var price: int

@onready var texture_button := %TextureButton as TextureButton
@onready var price_label := %Price as RichTextLabel

func _ready() -> void:
	name = item.name
	texture_button.texture_normal = item.image
	texture_button.button_up.connect(_on_texture_button_button_up) # 押されたらシグナル発火

## 販売アイテムのレベルと値段を算出し直す関数
func update() -> void:
	level = item.get_level() + 1 # 所持しているレベルの1つ上で売られる
	if level <= item.max_level: # 最大レベルに到達していなければ
		price = item.get_price(level)
		price_label.text = "[img=50]res://asset/image/coin.PNG[/img] " + \
		"[color=gold]%d[/color]" % price
	else:
		price_label.text = "[color=red]売り切れ[/color]"

## [signal BaseButton.button_up]を中継し[signal button_up]を発行します
func _on_texture_button_button_up() -> void:
	button_up.emit(self)
