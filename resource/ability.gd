class_name Ability
extends Resource

## 特殊効果を大別するカテゴリー 
@export_enum("なし","状態異常","バフ","デバフ","回復","吸収",\
"急所ダメージ","追加ダメージ","割合ダメージ","進化:100") var category: int

## 特殊効果のenumのenum[br]カテゴリに対応した効果を1つだけ選択する
@export_group("特殊効果")
@export_enum("なし","火傷","水没","感電","泥々","竜巻","霜焼","紫外線","呪い","麻痺","凍結","恐怖") \
var ailment: int
@export_enum("なし","ATK UP","DEF UP","MAG UP","RES UP","SPD UP") var buff: int
@export_enum("なし","ATK DOWN","DEF DOWN","MAG DOWN","RES DOWN","SPD DOWN") var debuff: int
@export_enum("なし","HP回復","定数HP回復","MP回復","定数MP回復") var healing: int
@export_enum("なし","HP吸収","MP吸収","SPD吸収") var steal: int
@export_enum("なし","急所ダメージ") var critical: int
@export_enum("なし","追加ダメージ") var additional: int
@export_enum("なし","最大HP割合ダメージ","現在HP割合ダメージ") var percentage: int
@export_enum("なし","進化Ⅰ","進化Ⅱ") var evolution: int
@export_group("")

## 特殊効果の名前
@export var name: String # 技の説明などに記載される特殊効果の名前 火傷、水没、など

## 特殊効果の対象
@warning_ignore("shadowed_global_identifier")
@export_enum("連動","敵単体","敵全体","味方単体","味方全体","自分") var range: int

## 特殊効果の発動条件
@export_enum("なし") var trigger: int

## 特殊効果によって得られるエフェクト
@export var effect: Effect
