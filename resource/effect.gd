class_name Effect
extends Resource

## 特殊効果を大別するカテゴリー
@export_enum("なし","状態異常","バフ","デバフ") var category: int

## エフェクトのenumのenum[br]カテゴリに対応した効果を1つだけ選択する
@export_group("エフェクト")
@export_enum("なし","火傷","水没","感電","泥々","竜巻","霜焼","紫外線","呪い","麻痺","凍結","恐怖") \
var ailment: int
@export_enum("なし","ATK UP","DEF UP","MAG UP","RES UP","SPD UP") var buff: int
@export_enum("なし","ATK DOWN","DEF DOWN","MAG DOWN","RES DOWN","SPD DOWN") var debuff: int
@export_group("")

## エフェクトの名前
@export var name: String

## エフェクトのアイコン
@export var icon: Texture

## エフェクトの強さ バフ強化倍率・デバフ弱体化倍率
@export var power: float

## バトル中に使用すると表示されるログ
@export_multiline var log: String
