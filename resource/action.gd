class_name Action
extends Resource


@export_category("技")
@export var id: int ## 技のid
@export var name: String ## 技の名前

## 技の属性 Element型のリソース[br]複数登録可能
@export var element: Array[Element]

## 技の最大出現確率
@export_range(1,100,1,"suffix:%") var max_chance: int

## 技の基本的な威力 0なら直接的なダメージは発生しない
@export var power: int

## 技の発動に必要なmp
@export var mp: int

## 技の対象範囲
@warning_ignore("shadowed_global_identifier")
@export_enum("なし","敵単体","敵全体","味方単体","味方全体","自分","敵散開") var range: int

## 技の参照するステータスの分類
@export_enum("なし","物理","魔法") var damage_type: int

## 技の接触判定[br]true:接触 false:非接触
@export var touch: bool


@export_category("特殊効果")

## 技の特殊効果 Ability型のリソース[br]複数登録可能
@export var ability: Array[Ability]


## 技の説明[br]1行につき全角12文字記述可能
@export_category("説明文")
@export_multiline var description: String
