class_name DeckSaveData
extends Resource

## デッキの名前
@export var name: String


@export_category("デッキ")

## モンスターのIDのリスト
@export var monster: Array[int]

## 技のIDのリスト
@export var action: Array[Array] = [[],[],[]]

## 技の出現確率のリスト
@export var chance: Array[Array] = [[],[],[]]

## スキルパターンのリスト
@export var skill: Array[int]


@export_category("バージョン")

## デッキが保存されたバージョン[br]float型 1.0 2.1など
@export var version: float

## バージョンがベータ版であるかどうか[br]true:β版 false:正式リリース
@export var beta: bool
