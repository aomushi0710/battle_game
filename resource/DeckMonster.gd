class_name  DeckMonster
extends Resource

@export var monster: Monster ## モンスターの現在の形態
@export var evolution_forms: Array[Monster] ## モンスターの全形態が登録されている配列
@export var action: Array[Action] ## 登録済みの技
var second_form_action: Array[Action] ## 第二形態で使用可能になる登録済みの技
var third_form_action: Array[Action] ## 第三形態で使用可能になる登録済みの技
@export var chance: Array[int] ## 技の出現確率
@export var skill: int = 0 ## スキルパターン
