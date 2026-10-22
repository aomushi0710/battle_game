class_name SaveData
extends Resource
## セーブデータの情報がまとめられているクラス

@export_storage var coin: int = 0 ## 所持コイン数

## モンスターのIDをkey、モンスターのレベルをvalueとした辞書
@export_storage var monster_levels: Dictionary[int, int] = {
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
@export_storage var item: Dictionary[int, int] = {}

@export_storage var version: String = Global.version ## セーブデータのバージョン
@export_storage var beta: bool = Global.IS_BETA ## β版であるかどうか
