class_name SaveData
extends Resource
## セーブデータの情報がまとめられているクラス

var coin: int = 0 ## 所持コイン数

## モンスターのIDをkey、モンスターのレベルをvalueとした辞書
var monster_levels: Dictionary[int, int] = {
	1: 1, 
	2: 1, 
	3: 1, 
	4: 1, 
	5: 1, 
	6: 1, 
	7: 1, 
	8: 1, 
}

## バトルアイテムのIDをkey、バトルアイテムのレベルをvalueとした辞書
var item: Dictionary[int, int] = {}

var version: String = Global.version ## セーブデータのバージョン
var beta: bool = Global.IS_BETA ## β版であるかどうか
