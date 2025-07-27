class_name Item
extends Resource


@export_category("アイテム")
@export var id: int ## アイテムのID
@export var name: String ## アイテムの名前
@export var image: Texture ## アイテムの画像
@export var price: int ## アイテムの値段


@export_category("効果")
@export var max_level: int ## アイテムレベル上限
@export var power: int ## アイテムの効果量 ※lv1
@export var power_scale: int ## レベルアップで増える効果量


@export_category("説明文")
@export_multiline var description: String ## 1行全角13文字

## レベルを引数として、説明文に効果量を含めて返す関数
func description_setter(lv: int) -> String:
	return description % (power + power_scale * (lv - 1))


## レベルを引数として、値段を返す関数
func price_setter(lv: int) -> int:
	return price * lv
