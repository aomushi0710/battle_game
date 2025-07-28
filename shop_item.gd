extends VBoxContainer

var item
var level: int
var price: int

signal button_up(item) ## ボタンが押された時に、アイテム情報を送るシグナル

func _ready() -> void:
	name = item.name
	$texture.texture_normal = item.image
	$texture.button_up.connect(func(): button_up.emit(self)) # 押されたらシグナル発火

## 販売アイテムのレベルと値段を算出し直す関数
func update() -> void:
	level = item.get_level() + 1 # 所持しているレベルの1つ上で売られる
	if level <= item.max_level: # 最大レベルに到達していなければ
		price = item.get_price(level)
		$price.text = "[img=50]res://image/coin.PNG[/img] " + \
		"[color=gold]%d[/color]" % price
	else:
		$price.text = "[color=red]売り切れ[/color]"
