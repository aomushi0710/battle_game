class_name SaveData
extends Resource
## セーブデータの情報がまとめられているクラス

var coin: int = 0 ## 所持コイン数
## モンスターのレベル[br]
## [code]key[/code]モンスターのID[code]value[/code]モンスターのレベル
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
## 所持バトルアイテム[br]
## [code]key[/code]バトルアイテムのID[code]value[/code]バトルアイテムのレベル
var item: Dictionary[int, int] = {}

## セーブデータのバージョン
var version: String = Global.version
var beta: bool = Global.VERSION_BETA ## β版であるかどうかのフラグ

## カスタムリソースのプロパティを辞書形式に変換する関数
func to_dictionary() -> Dictionary:
	var dict := {} ## 返り値の辞書
	var base_props: Array[String] = [] ## Resourceクラスが既に持つプロパティ一覧
	
	for prop: Dictionary in Resource.new().get_property_list():
		base_props.append(prop.name)
	
	for prop: Dictionary in get_property_list():
		if not base_props.has(prop.name) and prop.name != "script":
			dict[prop.name] = get(prop.name)
	
	return dict

## 辞書形式のデータからカスタムリソースに変換する関数
static func from_dictionary(dict: Dictionary) -> SaveData:
	var new_instance = new()
	for key in dict:
		new_instance.set(key, dict[key])
	return new_instance
