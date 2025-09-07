class_name Monster
extends Resource

enum Form { ## モンスターの形態
	第一形態, 
	第二形態, 
	第三形態, 
}

static var form_names = {} ## Formの値をkey、Formの定数名をvalueとする辞書

@export_category("モンスター")

@export var id: int ## モンスターのid
@export var name: String ## モンスターの名前

@export var form: Form ## モンスターの形態

@export var image: Texture ## モンスターの画像
@export var element: Array[Element] ## モンスターの属性 Element型[br]複数登録可能
@export var cost: int ## 進化に必要なmp


@export_category("ステータス")
@export var maxHP: int
@export var maxMP: int
@export var supplyMP: int
@export var ATK: int
@export var DEF: int
@export var MAG: int
@export var RES: int
@export var SPD: int

var HP: int
var MP: int

@export_category("スキル")

@export_group("スキルパターン1")
## スキルパターン1:スキルの名前
@export var skill1_name: Array[String]
## スキルパターン1:スキルのID
@export var skill1_id: Array[int]

@export_group("スキルパターン2")
## スキルパターン2:スキルの名前
@export var skill2_name: Array[String]
## スキルパターン2:スキルのID
@export var skill2_id: Array[int]


@export_category("技")
## その形態で使用可能な技の配列
@export var actions: Array[Action]


@export_category("ドロップアイテム")

@export var coin: int ## モンスターが落とすコイン枚数


@export_category("説明")

@export_multiline var description: String ## モンスターの説明
@export_multiline var flavor_text: Array[String] ## モンスターのフレーバーテキスト一覧


static func _static_init() -> void:
	for key in Form:
		var value = Form[key]
		form_names[value] = key
