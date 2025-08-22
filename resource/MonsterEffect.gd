class_name MonsterEffect
extends Resource
## モンスターに付与されるエフェクト

signal set_turn ## ターン数が変更された時に発行。表示されるターン数を変更する。
signal delete ## ターン数が0になった時に発行。自身を削除する。

var monster: BattleMonster ## このエフェクトが付いてるモンスター
var effect: Ability
var turn: int: ## 残りターン数
	set(value):
		turn = value
		set_turn.emit()
var damage: int ## 状態異常によって受けるダメージ
var description: String


func _init(_effect: Ability) -> void:
	effect = _effect
	turn = _effect.turn
	description = _effect.description


func update() -> void:
	pass
		

## ターン終了時の処理
func turn_finished() -> void:
	turn -= 1
	if turn == 0:
		delete.emit()
