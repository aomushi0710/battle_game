class_name Battle
extends Node2D

## バトル終了シグナル。[br]勝利時は[code]true[/code]を返します。
signal battle_finished(is_victory: bool)

@onready var stage_node := %Background as Control
@onready var battle_node := %Battle as Control

func _ready() -> void:
	stage_node.setup(Global.battle_stage)
	battle_node.setup()


func _on_battle_battle_finished(is_victory: bool) -> void:
	battle_finished.emit(is_victory)
