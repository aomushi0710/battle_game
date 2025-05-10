class_name Monster
extends Resource


@export_category("モンスター")

## モンスターのid
@export var id: int

## モンスターの名前
@export var name: String

## モンスターの形態[br]default(0):未進化[br]middle_evolution(1):第2形態(2回進化モンスターのみ該当)
## [br]evolution(2):最終形態(1回または2回進化モンスターのみ該当)
@export_enum("default","middle_evolution","evolution") var form: int

## モンスターの画像
@export var image: Texture

## モンスターの属性 Element型[br]複数登録可能
@export var element: Array[Element]

## 進化に必要なmp
@export var cost: int


@export_category("ステータス")
@export var maxHP: int
@export var maxMP: int
@export var supplyMP: int
@export var ATK: int
@export var DEF: int
@export var MAG: int
@export var RES: int
@export var SPD: int

var HP = maxHP
@warning_ignore("integer_division")
var MP = maxMP / 5

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
## form==default:未進化モンスターに割り当て可能な技の配列[br]
## form!=default:進化後に置き換えられる進化技
@export var actions: Array[Action]


@export_category("説明")
## モンスターの説明
@export_multiline var description: String
