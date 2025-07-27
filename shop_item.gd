extends VBoxContainer

var item
var level: int
var price: int

signal button_up(item) ## ボタンが押された時に、アイテム情報を送るシグナル

func _ready() -> void:
	name = item.name
	$texture.texture_normal = item.image
	$texture.button_up.connect(func(): button_up.emit(self)) # 押されたらシグナル発火

## 値段を算出して表示するセッター
func price_setter() -> void:
	if level <= item.max_level: # 最大レベルに到達していなければ
		price = item.price * level
		$price.text = "[img=50]res://image/coin.PNG[/img] " + \
		"[color=gold]%d[/color]" % price
	else:
		$price.text = "[color=red]売り切れ[/color]"
