@tool
class_name MonsterForm
extends Resource
## モンスターの各形態固有の情報を持つクラス。[br]
## [MonsterData]の変数で参照されます。
## ALERT この型のリソースファイルはゲーム内で変更してはいけません。

@export_category("モンスター")
@export var name: String ## モンスターの名前
@export var image: Texture ## モンスターの画像
@export var element: Array[Element] ## モンスターの属性 Element型[br]複数登録可能
@export var cost: int ## 進化に必要なmp

@export_category("ステータス")
@export var base_maxHP: int ## maxHPの基礎ステータス
@export var base_maxMP: int ## maxMPの基礎ステータス
@export var base_supplyMP: int ## supplyMPの基礎ステータス
@export var base_SPD: int ## SPDの基礎ステータス
@export var base_ATK: int ## ATKの基礎ステータス
@export var base_DEF: int ## DEFの基礎ステータス
@export var base_MAG: int ## MAGの基礎ステータス
@export var base_RES: int ## RESの基礎ステータス

@export_category("説明")
@export_multiline var description: String ## モンスターの説明
@export var flavor_text: Array[BattlelogData]: ## モンスターのフレーバーテキスト一覧
	set(value):
		flavor_text = value
		flavor_text_weight.resize(len(value))
		flavor_text_weight.fill(1)
## [member MonsterForm.flavor_text]の重みづけテーブル
@export var flavor_text_weight: Array[int]

## レベル[param lv]を引数として、実際のステータスをまとめて配列で返す関数[br]
## [lb]maxHP, maxMP, supplyMP, SPD, ATK, DEF, MAG, RES[rb]
func status_calculator(lv: int) -> Array[int]:
	var start_multiplier: float = 0.9 ## 
	var growth_per_level: float = 0.1 ## レベルアップで上昇するステータス倍率
	
	var maxHP: int = base_maxHP * (start_multiplier + growth_per_level * lv)
	var maxMP: int = base_maxMP
	var supplyMP: int = base_supplyMP
	var SPD: int = base_SPD * (0.99 + 0.01 * lv)
	var ATK: int = base_ATK * (start_multiplier + growth_per_level * lv)
	var DEF: int = base_DEF * (start_multiplier + growth_per_level * lv)
	var MAG: int = base_MAG * (start_multiplier + growth_per_level * lv)
	var RES: int = base_RES * (start_multiplier + growth_per_level * lv)
	return [maxHP, maxMP, supplyMP, SPD, ATK, DEF, MAG, RES]
