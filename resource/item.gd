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
## アイテムの対象範囲
@export var target: Global.Target


@export_category("説明文")
@export_multiline var description: String ## 1行全角13文字
@export_multiline var battle_description: String ## バトル用説明文 1行全角18文字


## インベントリを確認し、レベルを返す関数
func get_level() -> int:
	if id in Global.inv.item: # 所持しているならレベルを返す
		return Global.inv.item[id]
	else: # アイテムを未所持なら仮で0を返す
		return 0

## レベルを引数として、値段を返す関数
func get_price(lv: int) -> int:
	return price * lv

## レベルを引数として、そのレベルでの効果量を算出して返す関数
func get_power(lv: int) -> int:
	return power + power_scale * (lv - 1)

## レベルを引数として、説明文に効果量を含めて返す関数
func get_description(lv: int) -> String:
	return description % get_power(lv)

func get_battle_description(lv: int) -> String:
	return battle_description % get_power(lv)
	
